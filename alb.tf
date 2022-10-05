/* Defines the load balancer itself and attaches it to the public subnet
 in each availability zone with the load balancer security group */
resource "aws_alb" "application_load_balancer" {
  name               = "${var.app_name}-${terraform.workspace}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.public.*.id
  security_groups    = [aws_security_group.load_balancer_security_group.id]

  tags = {
    Name        = "${var.app_name}-${terraform.workspace}-alb"
    Environment = terraform.workspace
  }
}