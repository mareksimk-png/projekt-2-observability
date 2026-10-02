variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Nazev projektu"
  type        = string
  default     = "portfolio-iac"
}

variable "alert_email" {
  description = "E-mail pro prijem notifikaci z SNS"
  type        = string
}

variable "cpu_threshold" {
  description = "Hranice CPU v % pro alarm"
  type        = number
  default     = 80
}

variable "disk_threshold" {
  description = "Hranice disku v % pro alarm"
  type        = number
  default     = 85
}