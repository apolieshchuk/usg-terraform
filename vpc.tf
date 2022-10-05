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