output "projekt_1_instance_id" {
  description = "ID EC2 instance z Projektu 1"
  value       = data.terraform_remote_state.projekt_1.outputs.instance_id
}

output "projekt_1_vpc_id" {
  description = "ID VPC z Projektu 1"
  value       = data.terraform_remote_state.projekt_1.outputs.vpc_id
}