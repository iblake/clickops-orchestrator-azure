################################################################################
# Outputs
################################################################################

output "resource_group_name" {
  description = "Name of the Resource Group"
  value       = var.resource_group.existing_name != null ? (length(data.azurerm_resource_group.existing) > 0 ? data.azurerm_resource_group.existing[0].name : null) : (length(module.resource_group) > 0 ? module.resource_group[0].name : null)
}

output "resource_group_id" {
  description = "ID of the Resource Group"
  value       = var.resource_group.existing_name != null ? (length(data.azurerm_resource_group.existing) > 0 ? data.azurerm_resource_group.existing[0].id : null) : (length(module.resource_group) > 0 ? module.resource_group[0].resource_id : null)
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = var.network.existing_vnet_name != null ? (length(data.azurerm_virtual_network.existing) > 0 ? data.azurerm_virtual_network.existing[0].name : null) : (length(module.vnet) > 0 ? module.vnet[0].name : null)
}

output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = var.network.existing_vnet_name != null ? (length(data.azurerm_virtual_network.existing) > 0 ? data.azurerm_virtual_network.existing[0].id : null) : (length(module.vnet) > 0 ? module.vnet[0].resource_id : null)
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = var.network.existing_subnet_name != null ? (length(data.azurerm_subnet.existing) > 0 ? data.azurerm_subnet.existing[0].id : null) : (length(module.vnet) > 0 ? module.vnet[0].subnets["main"].resource_id : null)
}

output "vm_name" {
  description = "Name of the created Virtual Machine"
  value       = length(module.vm) > 0 ? module.vm[0].name : null
}

output "vm_id" {
  description = "ID of the created Virtual Machine"
  value       = length(module.vm) > 0 ? module.vm[0].resource_id : null
}

output "vm_network_info" {
  description = "VM network information"
  value       = "Check Azure portal for IP addresses"
}

output "nsg_name" {
  description = "Name of the Network Security Group"
  value       = var.security.existing_nsg_name != null ? (length(data.azurerm_network_security_group.existing) > 0 ? data.azurerm_network_security_group.existing[0].name : null) : (length(module.nsg) > 0 ? module.nsg[0].name : null)
}

output "nsg_id" {
  description = "ID of the Network Security Group"
  value       = var.security.existing_nsg_name != null ? (length(data.azurerm_network_security_group.existing) > 0 ? data.azurerm_network_security_group.existing[0].id : null) : (length(module.nsg) > 0 ? module.nsg[0].resource_id : null)
}

output "deployment_info" {
  description = "Deployment summary"
  value = {
    resource_group = var.resource_group.name
    vm_name        = var.vm.name
    vm_size        = var.vm.size
    location       = var.resource_group.existing_name != null ? (length(data.azurerm_resource_group.existing) > 0 ? data.azurerm_resource_group.existing[0].location : null) : var.resource_group.location
  }
}