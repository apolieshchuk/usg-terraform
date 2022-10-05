# Find a certificate that is issued
data "aws_acm_certificate" "ssl_certificate" {
  domain   = "api.${terraform.workspace}.${var.domain}"
  statuses = ["ISSUED"]
}