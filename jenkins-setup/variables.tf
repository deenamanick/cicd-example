variable "access_key" {
  description = "Access key to AWS console"
  type        = string
}

variable "secret_key" {
  description = "Secret key to AWS console"
  type        = string
  sensitive   = true
}
variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "The environment (e.g., dev, staging, prod)"
  type        = string
  default     = "dev" # Optional: Set a default value
}

variable "is_dev" {
  description = "Whether the environment is dev or not"
  type        = bool
  default     = false # Default to non-production
}

variable "instance_tags" {
  description = "Tags for the EC2 instance"
  type        = list(string)
  default     = ["web", "dev", "terraform"]
}