locals {
  notifer_rules = [
    {
      name: "${terraform.workspace}-task-on",
      status: "RUNNING"
    },
    {
      name: "${terraform.workspace}-task-off",
      status: "STOPPED"
    },
  ]
}

resource "aws_cloudwatch_event_rule" "ecs_notifer_event_rule" {
  count = length(local.notifer_rules)
  name = "ecs-${lookup(local.notifer_rules[count.index], "name")}-event-rule"
  event_pattern = jsonencode({
    "source": ["aws.ecs"],
    "detail-type": ["ECS Task State Change"],
    "detail": {
      "lastStatus": [lookup(local.notifer_rules[count.index], "status")],
      "desiredStatus": [lookup(local.notifer_rules[count.index], "status")],
      "clusterArn": [aws_ecs_cluster.aws-ecs-cluster.arn]
    }
  })
  description         = "Notify when ECS task change status to ${lookup(local.notifer_rules[count.index], "status")}"

  tags = {
    Name        = "ecs-${lookup(local.notifer_rules[count.index], "name")}-event-rule"
    Environment = terraform.workspace
  }
}

resource "aws_cloudwatch_event_target" "ecs_notifer_lambda_target" {
  count = length(local.notifer_rules)
  arn = aws_lambda_function.ecs_notifer.arn
  rule = aws_cloudwatch_event_rule.ecs_notifer_event_rule[count.index].name
}

resource "aws_lambda_permission" "ecs_notifier" {
  count = length(local.notifer_rules)
  statement_id = "AllowExecutionFromEventBridge_${lookup(local.notifer_rules[count.index], "name")}-event"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ecs_notifer.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.ecs_notifer_event_rule[count.index].arn
}
