/* Will relate the Load Balancer with the Containers. The target group, when added to the load balancer
 listener tells the load balancer to forward incoming traffic on port var.app_port to wherever the load balancer is attached */
resource "aws_lb_target_group" "target_group" {
  name        = "${var.app_name}-${terraform.workspace}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.aws-vpc.id

  health_check {
    healthy_threshold   = "3"
    interval            = "300"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/health"
    unhealthy_threshold = "2"
  }

  tags = {
    Name        = "${var.app_name}-${terraform.workspace}-lb-tg"
    Environment = terraform.workspace
  }
}