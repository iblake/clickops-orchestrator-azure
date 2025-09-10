module "resource_group" {
  for_each = {
    for key, config in local.resource_groups : key => config
    if !config.is_existing
  }
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.2.1"

  name     = each.value.name
  location = each.value.location
}