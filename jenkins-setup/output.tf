# output "ami_id" {
#   value = aws_instance.ec2instance[count.index]
# }

output "instance_public_ip" {
  description = "Public DNS URL of an EC2 Instance"
  value = {
    for key, instance in aws_instance.ec2instance : key => instance.public_ip
  }

  # value = aws_instance.ec2instance.public_ip
}

# The for expression is a powerful way to transform lists or maps in Terraform.
# The join() function is useful for creating human-readable strings from lists.
output "server_tags" {
  description = "Comma-separated list of server tags"
  value       = join(", ", [for tags in var.instance_tags : "server-${tags}"])
}



