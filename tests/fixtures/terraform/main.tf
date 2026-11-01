# Self-test fixture for terraform-validate.yml. It uses only the built-in
# terraform_data resource, so init needs no providers and no lock file.
terraform {
  required_version = ">= 1.16"
}

variable "greeting" {
  description = "Value stored in the fixture resource"
  type        = string
  default     = "hello"
}

resource "terraform_data" "fixture" {
  input = var.greeting
}

output "greeting" {
  description = "The stored greeting"
  value       = terraform_data.fixture.output
}
