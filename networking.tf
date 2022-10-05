/* Resources that will be created will be defined inside of the VPC.
 An AWS VPC provides logical isolation of resources from one another.
 All of the resources that will be defined will live within the same VPC */
resource "aws_vpc" "aws-vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name        = "${var.app_name}-vpc"
    Environment = terraform.workspace
  }
}

// allows communication between the VPC and the internet at all
resource "aws_internet_gateway" "aws-igw" {
  vpc_id = aws_vpc.aws-vpc.id
  tags = {
    Name        = "${var.app_name}-igw"
    Environment = terraform.workspace
  }
}

/* Things that should be public-facing, such as a load balancer, will be added to the public subnet.
 Other things that don’t need to communicate with the internet directly,
 such as a Hello World service defined inside an ECS cluster, will be added to the private subnet. */
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.aws-vpc.id
  count             = length(var.private_subnets)
  cidr_block        = element(var.private_subnets, count.index)
  availability_zone = element(var.availability_zones, count.index)

  tags = {
    Name        = "${var.app_name}-private-subnet-${count.index + 1}"
    Environment = terraform.workspace
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.aws-vpc.id
  cidr_block              = element(var.public_subnets, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  count                   = length(var.public_subnets)
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.app_name}-public-subnet-${count.index + 1}"
    Environment = terraform.workspace
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.aws-vpc.id

  tags = {
    Name        = "${var.app_name}-routing-table-public"
    Environment = terraform.workspace
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.aws-igw.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

// -----  Static IP addressing (Optional)
/* That is all tied together with the route table association, where the private route table that includes
 the NAT gateway is added to the private subnets defined earlier. */

// Elastic IP (get exist from aws directly)
//data "aws_eip" "eip" {
//  tags = {
//    Name = "${var.app_name}-${terraform.workspace}-eip"
//  }
//}

// Or create new
resource "aws_eip" "gateway" {
  count      = 1
  vpc        = true
  depends_on = [aws_internet_gateway.aws-igw]

  tags = {
    Name = "${var.app_name}-${terraform.workspace}-eip"
  }
}

/* The NAT gateway allows resources within the VPC to communicate with
the internet but will prevent communication to the VPC from outside sources */
resource "aws_nat_gateway" "gateway" {
  count         = 1
  subnet_id     = element(aws_subnet.public.*.id, count.index)
//  allocation_id = data.aws_eip.eip.id
  allocation_id = element(aws_eip.gateway.*.id, count.index) // ToDo
  tags = {
    Name = "${var.app_name}-${terraform.workspace}-nat"
  }
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.aws-igw]
}

resource "aws_route_table" "private" {
  count  = 1
  vpc_id = aws_vpc.aws-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.gateway.*.id, count.index)
  }

  tags = {
    Name = "${var.app_name}-${terraform.workspace}-rtb"
  }
}

resource "aws_route_table_association" "private" {
  count          = 1
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

output "gateway_elastic_ip" {
  value = aws_eip.gateway.*.public_ip
}