resource "aws_ecs_cluster" "aws-ecs-cluster" {
  name = "${var.app_name}-${terraform.workspace}-cluster"
  tags = {
    Name        = "${var.app_name}-${terraform.workspace}-ecs"
    Environment = terraform.workspace
  }
}