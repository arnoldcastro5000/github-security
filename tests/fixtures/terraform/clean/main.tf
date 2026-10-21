terraform {
  required_version = ">= 1.5.0"
}

variable "greeting" {
  description = "The greeting to output."
  type        = string
  default     = "hello"
}

output "greeting" {
  description = "The greeting."
  value       = var.greeting
}
