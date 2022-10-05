/* One final step remains in the Terraform configuration to make the deployed resources easier to test.
To reach the service, the URL of the load balancer is required. You could find it on the AWS dashboard,
 but Terraform can make it easier. Add a file called outputs.tf in the same directory as main.tf */
output "load_balancer_ip" {
  value = aws_alb.application_load_balancer.dns_name
}

/* This file will be included in the Terraform configuration when commands are run, and the output will
instruct Terraform to print the URL of the load balancer when the plan has been applied. */