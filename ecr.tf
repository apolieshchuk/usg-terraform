//resource "aws_ecr_repository" "aws-ecr" {
//  name = "${var.app_name}-${terraform.workspace}-ecr"
//  tags = {
//    Name        = "${var.app_name}-ecr"
//    Environment = terraform.workspace
//  }
//}