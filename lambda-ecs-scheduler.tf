data "archive_file" "zip_ecs_scheduler_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/resources/ecs-scheduler-lambda"
  output_path = "${path.module}/resources/ecs-scheduler-lambda.zip"
}

resource "aws_lambda_function" "ecs_scheduler" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "${path.module}/resources/ecs-scheduler-lambda.zip"
  function_name = "${terraform.workspace}-ecs-scheduler-lambda"
  role          = aws_iam_role.ecsServiceUpdateRole.arn
  handler       = "main.lambda_handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256("${path.module}/resources/ecs-scheduler-lambda.zip")

  runtime = "python3.9"
#  depends_on = [aws_iam_role_policy_attachment.ecsServiceUpdateRole_policy]

#  environment {
#    variables = {
#      foo = "bar"
#    }
#  }
}