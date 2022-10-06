### -----  Static IP addressing (Optional)

/* That is all tied together with the route table association, where the private route table that includes
 the NAT gateway is added to the private subnets defined earlier. */

// Elastic IP (get exist from aws directly)
//data "aws_eip" "eip" {
//  tags = {
//    Name = "${var.app_name}-${terraform.workspace}-eip"
//  }
//}

/* Or create new */
resource "aws_eip" "gateway" {
  count      = 1
  vpc        = true
  lifecycle {
    prevent_destroy = true
  }
//  depends_on = [aws_internet_gateway.aws-igw]

  tags = {
    Name = "${var.app_name}-${terraform.workspace}-eip"
    Role        = "private"
    ManagedBy   = "terraform"
  }
}

/* The NAT gateway allows resources within the VPC to communicate with
the internet but will prevent communication to the VPC from outside sources */
# Note: We're only creating one NAT Gateway, potential single point of failure
# Each NGW has a base cost per hour to run, roughly $32/mo per NGW. You'll often see
#  one NGW per AZ created, and sometimes one per subnet.
# Note: Cross-AZ bandwidth is an extra charge, so having a NAT per AZ could be cheaper
#        than a single NGW depending on your usage
resource "aws_nat_gateway" "nat" {
  count         = 1
  //  allocation_id = aws_eip.gateway.id
  //  allocation_id = data.aws_eip.eip.id
  allocation_id = element(aws_eip.gateway.*.id, count.index)

  # Whichever the first public subnet happens to be
  # (because NGW needs to be on a public subnet with an IGW)
  # keys(): https://www.terraform.io/docs/configuration/functions/keys.html
  # element(): https://www.terraform.io/docs/configuration/functions/element.html
  //  subnet_id = aws_subnet.public[element(keys(aws_subnet.public), 0)].id
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  //  count         = 1
  tags = {
    Name        = "${var.app_name}-${terraform.workspace}-nat"
    VPC         = aws_vpc.aws-vpc.id
    Environment = terraform.workspace
    ManagedBy   = "terraform"
    Role        = "private"
  }
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  //  depends_on = [aws_internet_gateway.aws-igw]
}

###
# Route Tables, Routes and Associations
##
resource "aws_route_table" "private" {
  count  = 1
  vpc_id = aws_vpc.aws-vpc.id

  # Private Route
  route {
//    route_table_id  = aws_route_table.private.id
    cidr_block      = "0.0.0.0/0"
    nat_gateway_id  = element(aws_nat_gateway.nat.*.id, count.index)
  }

  tags = {
    Name = "${var.app_name}-${terraform.workspace}-rtb"
    VPC         = aws_vpc.aws-vpc.id
    Environment = terraform.workspace
    ManagedBy   = "terraform"
    Role        = "private"
  }
}

# Private Route (initialized in
//resource "aws_route" "private" {
//  route_table_id         = aws_route_table.private.id
//  destination_cidr_block = "0.0.0.0/0"
//  nat_gateway_id         = aws_nat_gateway.nat.id
//}


# Private Route to Private Route Table for Private Subnets
resource "aws_route_table_association" "private" {
  count          = 1
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)

//  for_each  = aws_subnet.private
//  subnet_id = aws_subnet.private[each.key].id
//  route_table_id = aws_route_table.private.id
}

output "gateway_elastic_ip" {
  value = aws_eip.gateway.*.public_ip
}