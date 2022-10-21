data "archive_file" "zip_ecs_notifer_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/resources/ecs-notifer-lambda"
  output_path = "${path.module}/resources/ecs-notifer-lambda.zip"
}

resource "aws_lambda_function" "ecs_notifer" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "${path.module}/resources/ecs-notifer-lambda.zip"
  function_name = "${terraform.workspace}-ecs-notifer-lambda"
  role          = aws_iam_role.roleForLambda.arn
  handler       = "main.handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256("${path.module}/resources/ecs-notifer-lambda.zip")

  runtime = "nodejs16.x"
  #  depends_on = [aws_iam_role_policy_attachment.ecsServiceUpdateRole_policy]

  #  environment {
  #    variables = {
  #      foo = "bar"
  #    }
  #  }
}