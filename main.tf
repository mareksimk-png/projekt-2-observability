# Přečte stav Projektu 1
data "terraform_remote_state" "projekt_1" {
  backend = "s3"

  config = {
    bucket = "portfolio-iac-terraform-state-850695279272"
    key    = "projekt-1/terraform.tfstate"
    region = "eu-central-1"
  }
}

# Získá ID instance z Projektu 1
locals {
  projekt_1_instance_id = data.terraform_remote_state.projekt_1.outputs.instance_id
  projekt_1_vpc_id      = data.terraform_remote_state.projekt_1.outputs.vpc_id
}