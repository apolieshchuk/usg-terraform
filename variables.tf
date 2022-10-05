variable "aws_access_key" {
  type        = string
  description = "AWS Access Key"
}

variable "aws_secret_key" {
  type        = string
  description = "AWS Secret Key"
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "app_count" {
  type = number
  description = "ECS Service App amount"
  default = 1
}

variable "app_port" {
  type = number
  description = "Container APP port"
  default = 3000
}

variable "app_image_url" {
  type        = string
  description = "Application path to docker image"
}

//variable "gitlab_deploy_token" {
//  description = "CI/CD Gitlab deploy token"
//  type = object({ username: string, password: string })
//}

// Todo replace to log pass or create arm token
variable app_image_arm_token {
  type        = string
  description = "ARM token from AWS Secret Manager"
}

//variable "app_image_username" {
//  type        = string
//  description = "Application docker image auth username"
//}
//
//variable "app_image_password" {
//  type        = string
//  description = "Application docker image auth password"
//}

variable "aws_cloudwatch_retention_in_days" {
  type        = number
  description = "AWS CloudWatch Logs Retention in Days"
  default     = 1
}

variable "app_name" {
  type        = string
  description = "Application Name"
}

//variable "app_environment" {  // Use terraform.workspace instead
//  type        = string
//  description = "Application Environment. staging or dev"
//}

variable "cidr" {
  description = "The CIDR block for the VPC."
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "List of public subnets"
}

variable "private_subnets" {
  description = "List of private subnets"
}

variable "availability_zones" {
  description = "List of availability zones"
}

variable "staging_env" {
  description = "Staging env config"
  type = list(object({ name: string, value: string }))
}

variable "ssl_api_certificate_arn" {
  description = "SSL certificate arn for api.staging.usgua.click and api.dev.usgua.click"
  type = object({
    staging: string,
    dev: string,
  })
}

variable "api_domen" {
  description = "environment domens"
  type = object({
    staging: string,
    dev: string,
  })
}