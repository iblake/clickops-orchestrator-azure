################################################################################
#  Data source for existing resource group
################################################################################
data "azurerm_resource_group" "existing" {
  count = var.resource_group.existing_name != null ? 1 : 0
  name  = var.resource_group.existing_name
}

################################################################################
#  Resource Group (AVM Module) - Only if not using existing
################################################################################
module "resource_group" {
  count   = var.resource_group.existing_name == null && var.resource_group.name != null && var.resource_group.location != null ? 1 : 0
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.2.1"

  name     = var.resource_group.name
  location = var.resource_group.location
}