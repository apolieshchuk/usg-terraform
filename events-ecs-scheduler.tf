locals {
  scheduler_rules = [
    {
      name: "${terraform.workspace}-turn-on",
      cron: terraform.workspace == "dev" ? "cron(0 6 ? * * *)" : "cron(0 6 ? * 2-6 *)",
      desired_tasks: 1
    },
    {
      name: "${terraform.workspace}-turn-off",
      cron: terraform.workspace == "dev" ? "cron(0 22 ? * * *)" : "cron(0 22 ? * * *)"
      desired_tasks: 0
    },
  ]
}

resource "aws_cloudwatch_event_rule" "ecs_schedule_event_rule" {
  count = length(local.scheduler_rules)
  name = "ecs-${lookup(local.scheduler_rules[count.index], "name")}-event-rule"
  // every day at 5AM UTC
  schedule_expression = lookup(local.scheduler_rules[count.index], "cron")
  description         = "Start ECS instances in morning ${lookup(local.scheduler_rules[count.index], "cron")}"

  tags = {
    Name        = "ecs-${lookup(local.scheduler_rules[count.index], "name")}-event-rule"
    Environment = terraform.workspace
  }
}

resource "aws_cloudwatch_event_target" "ecs_schedule_lambda_target" {
  count = length(local.scheduler_rules)
  arn = aws_lambda_function.ecs_scheduler.arn
  rule = aws_cloudwatch_event_rule.ecs_schedule_event_rule[count.index].name
  input_transformer {
    input_template = jsonencode({
      "cluster": aws_ecs_cluster.aws-ecs-cluster.name,
      "service_names": aws_ecs_service.aws-ecs-service.name,
      "service_desired_count": lookup(local.scheduler_rules[count.index], "desired_tasks")
    })
  }
}

resource "aws_lambda_permission" "ecs_scheduler" {
  count = length(local.scheduler_rules)
  statement_id = "AllowExecutionFromEventBridge_${lookup(local.scheduler_rules[count.index], "name")}-event"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ecs_scheduler.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.ecs_schedule_event_rule[count.index].arn
}
