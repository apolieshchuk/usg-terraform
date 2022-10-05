resource "aws_ecs_service" "aws-ecs-service" {
  name                 = "${var.app_name}-${terraform.workspace}-ecs-service"
  cluster              = aws_ecs_cluster.aws-ecs-cluster.id
  task_definition      = "${aws_ecs_task_definition.aws-ecs-task.family}:${max(aws_ecs_task_definition.aws-ecs-task.revision, data.aws_ecs_task_definition.main.revision)}"
  // how many tasks of the application should be run with the task_definition and desired_count properties within the cluster.
  desired_count        = 1
  // The launch type is Fargate so that no EC2 instance management is required
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  force_new_deployment = true

  // The tasks will run in the private subnet as specified in the network_configuration block
  network_configuration {
    subnets          = aws_subnet.private.*.id
    assign_public_ip = false
    security_groups = [
      aws_security_group.service_security_group.id,
      aws_security_group.load_balancer_security_group.id
    ]
  }

  // And will be reachable from the outside world through the load balancer as defined in the load_balancer block
  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "${var.app_name}-${terraform.workspace}-container"
    container_port   = var.app_port
  }

  /* The service shouldn’t be created until the load balancer has been, so
  the load balancer listener is included in the depends_on array. */
  depends_on = [aws_lb_listener.http_listener]
}

/* Defined a Security Group to avoid external connections to the containers.
The security group for the application task specifies that it should be added to the
default VPC and only allow traffic over TCP to port var.app_port of the application */
resource "aws_security_group" "service_security_group" {
  vpc_id = aws_vpc.aws-vpc.id

//  ingress {
//    from_port       = 0
//    to_port         = 0
//    protocol        = "-1"
//    security_groups = [aws_security_group.load_balancer_security_group.id]
//  }
  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    /* The ingress settings also include the security group of the load balancer as that
    will allow traffic from the network interfaces that are used with that security group */
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  // It allows all outbound traffic of any protocol as seen in the egress settings
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${var.app_name}-${terraform.workspace}-service-sg"
    Environment = terraform.workspace
  }
}