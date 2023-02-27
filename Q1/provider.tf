
provider "azurerm" {
  subscription_id = "00461249-f3ba-465e-855e-d64aac4eb75f"
  client_id       = var.sp_client_id
  client_secret   = var.sp_client_secret
  tenant_id       = var.tenant_id
  environment     = "public"
  features {}
}