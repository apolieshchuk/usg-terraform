/* Resources that will be created will be defined inside of the VPC.
 An AWS VPC provides logical isolation of resources from one another.
 All of the resources that will be defined will live within the same VPC */
resource "aws_vpc" "aws-vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name        = "${var.app_name}-${terraform.workspace}-vpc"
    Environment = terraform.workspace
  }
}

/* allows communication between the VPC and the internet at all */
resource "aws_internet_gateway" "aws-igw" {
  vpc_id = aws_vpc.aws-vpc.id
  tags = {
    Name        = "${var.app_name}-${terraform.workspace}-igw"
    Environment = terraform.workspace
    VPC         = aws_vpc.aws-vpc.id
    ManagedBy   = "terraform"
  }
}

/* Things that should be public-facing, such as a load balancer, will be added to the public subnet.
 Other things that don’t need to communicate with the internet directly,
 such as a Hello World service defined inside an ECS cluster, will be added to the private subnet. */
resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.aws-vpc.id
  cidr_block        = element(var.private_subnets, count.index)
  availability_zone = element(var.availability_zones, count.index)

  tags = {
    Name        = "${var.app_name}-${terraform.workspace}-private-subnet-${count.index + 1}"
    Environment = terraform.workspace
  }
}

###
# Route Tables, Routes and Associations
##

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.aws-vpc.id
  cidr_block              = element(var.public_subnets, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  count                   = length(var.public_subnets)
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.app_name}-${terraform.workspace}-public-subnet-${count.index + 1}"
    Environment = terraform.workspace
  }
}

# The routing table for the public subnet, going through the internet gateway:
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.aws-vpc.id

  tags = {
    Name = "${var.app_name}-${terraform.workspace}-rtb-public"
    VPC         = aws_vpc.aws-vpc.id
    Environment = terraform.workspace
    ManagedBy   = "terraform"
    Role        = "private"
  }
}

# Public Route
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.aws-igw.id
}

# Public Route to Public Route Table for Public Subnets
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id

//  for_each  = aws_subnet.public
//  subnet_id = aws_subnet.public[each.key].id
//  route_table_id = aws_route_table.public.id
}