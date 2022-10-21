resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "${var.app_name}-${terraform.workspace}-execution-task-role"
  assume_role_policy = data.aws_iam_policy_document.assume_ecs_role_policy.json
  tags = {
    Name        = "${var.app_name}-${terraform.workspace}iam-role"
    Environment = terraform.workspace
  }
}

// For ECS services update (schedule on/off lambda)
resource "aws_iam_role" "ecsServiceUpdateRole" {
  name               = "${var.app_name}-${terraform.workspace}-update-ecs-service-role"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda_role_policy.json
  tags = {
    Name        = "${var.app_name}-${terraform.workspace}-update-ecs-service-role"
    Environment = terraform.workspace
  }
}

resource "aws_iam_role" "roleForLambda" {
  name               = "${var.app_name}-${terraform.workspace}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda_role_policy.json
  tags = {
    Name        = "${var.app_name}-${terraform.workspace}-lambda-role"
    Environment = terraform.workspace
  }
}

data "aws_iam_policy_document" "assume_ecs_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "assume_lambda_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

// Attach policy for access to AWS SecretManager for get ECS docker private container credentials
resource "aws_iam_role_policy" "secret_manager_access_policy" {
  name = "getSecretManagerValuePolicy"
  role = aws_iam_role.ecsTaskExecutionRole.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

// Attach policy for access to AWS ECS Services and update it (for turn ON/OFF scheduling)
resource "aws_iam_role_policy" "ecs_service_update_policy" {
  name = "ecsServiceUpdatePolicy"
  role = aws_iam_role.ecsServiceUpdateRole.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "logs:*"
        ],
        "Resource": "arn:aws:logs:*:*:*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ecs:DescribeServices",
          "ecs:UpdateService"
        ],
        "Resource": [
          "*"
        ]
      }
    ]
  })
}
