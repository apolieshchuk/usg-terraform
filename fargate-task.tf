/* The task definition defines how the our application should be run. This is where it’s specified that
 the platform will be Fargate rather than EC2, so that managing EC2 instances isn’t required.
 This means that CPU and memory for the running task should be specified. The Docker container exposes
  the API on port var.app_port, so that’s specified as the host and container ports. The network mode is set to “awsvpc”, which
  tells AWS that an elastic network interface and a private IP address should be assigned to the task when it runs.  */
resource "aws_ecs_task_definition" "aws-ecs-task" {
  family = "${var.app_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  memory                   = "512"
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn

  tags = {
    Name        = "${var.app_name}-ecs-td"
    Environment = terraform.workspace
  }

  container_definitions = jsonencode([
    {
      name: "${var.app_name}-${terraform.workspace}-container",
      image: "${var.app_image_url}:${terraform.workspace}",
      entryPoint: [],
      repositoryCredentials : {
        credentialsParameter : var.app_image_arm_token
      },
      environment: lookup(var.env_variables, terraform.workspace),
      essential: true,
      logConfiguration: {
        logDriver: "awslogs",
        options: {
          awslogs-group: aws_cloudwatch_log_group.log-group.id,
          "awslogs-region": var.aws_region,
          "awslogs-stream-prefix": "${var.app_name}-${terraform.workspace}"
        }
      },
      portMappings: [
        {
          containerPort: var.app_port,
          hostPort: var.app_port
        }
      ],
      cpu: 256,
      memory: 512,
      networkMode: "awsvpc"
    }
  ])

//  container_definitions = <<DEFINITION
//    [
//    {
//      "name": "${var.app_name}-${terraform.workspace}-container",
//      "image": "${var.app_image_url}:${terraform.workspace}",
//      "repositoryCredentials" : {
//        "credentialsParameter" : "dev/gitlab/deploy_token"
//      },
//      "entryPoint": [],
//      "environment": ${jsonencode(var.staging_env)},
//      "essential": true,
//      "logConfiguration": {
//        "logDriver": "awslogs",
//        "options": {
//          "awslogs-group": "${aws_cloudwatch_log_group.log-group.id}",
//          "awslogs-region": "${var.aws_region}",
//          "awslogs-stream-prefix": "${var.app_name}-${terraform.workspace}"
//        }
//      },"portMappings": [
//        {
//          "containerPort": ${var.app_port},
//          "hostPort": ${var.app_port}
//        }
//      ],
//      "cpu": 256,
//      "memory": 512,
//      "networkMode": "awsvpc"
//    }
//  ]
//  DEFINITION
}

data "aws_ecs_task_definition" "main" {
  task_definition = aws_ecs_task_definition.aws-ecs-task.family
}