provider "azurerm" {
  features {}
  subscription_id = ""
}

# terraform {
#   backend "azurerm" {
#     resource_group_name  = "tf-state-rg"
#     storage_account_name = "tfstateaccount"
#     container_name       = "tfstate"
#     key                  = "keyvault.terraform.tfstate"
#   }
# }