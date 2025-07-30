################################################################################
# Outputs - Orchestrator Configuration
################################################################################

# Resource Groups outputs by key
output "resource_groups" {
  description = "Map of resource groups by configuration key"
  value = {
    for key, rg in local.resource_groups : key => {
      name     = length(module.resource_group) > 0 ? module.resource_group[0].name : null
      id       = length(module.resource_group) > 0 ? module.resource_group[0].resource_id : null
      location = rg.location
    }
  }
}

# Networks outputs by key
output "networks" {
  description = "Map of networks by configuration key"
  value = {
    for key, net in local.networks : key => {
      name     = length(module.vnet) > 0 ? module.vnet[0].name : null
      id       = length(module.vnet) > 0 ? module.vnet[0].resource_id : null
      location = net.location
      subnets = {
        for subnet_key, subnet in net.subnets : subnet_key => {
          name = subnet.name
          id   = length(module.vnet) > 0 ? module.vnet[0].subnets[subnet_key].resource_id : null
        }
      }
    }
  }
}

# Security Groups outputs by key
output "security_groups" {
  description = "Map of security groups by configuration key"
  value = {
    for key, sg in local.security_groups : key => {
      name     = length(module.nsg) > 0 ? module.nsg[0].name : null
      id       = length(module.nsg) > 0 ? module.nsg[0].resource_id : null
      location = sg.location
    }
  }
}

# Virtual Machines outputs by key
output "virtual_machines" {
  description = "Map of virtual machines by configuration key"
  value = {
    for key, vm in local.virtual_machines : key => {
      name     = length(module.vm) > 0 ? module.vm[0].name : null
      id       = length(module.vm) > 0 ? module.vm[0].resource_id : null
      location = vm.location
      size     = vm.size
    }
  }
}

# Legacy outputs for backward compatibility
output "resource_group_name" {
  description = "Name of the primary Resource Group (backward compatibility)"
  value       = length(module.resource_group) > 0 ? module.resource_group[0].name : null
}

output "resource_group_id" {
  description = "ID of the primary Resource Group (backward compatibility)"
  value       = length(module.resource_group) > 0 ? module.resource_group[0].resource_id : null
}

output "vnet_name" {
  description = "Name of the primary Virtual Network (backward compatibility)"
  value       = length(module.vnet) > 0 ? module.vnet[0].name : null
}

output "vnet_id" {
  description = "ID of the primary Virtual Network (backward compatibility)"
  value       = length(module.vnet) > 0 ? module.vnet[0].resource_id : null
}

output "subnet_id" {
  description = "ID of the primary subnet (backward compatibility)"
  value       = length(module.vnet) > 0 ? module.vnet[0].subnets["subnet-public"].resource_id : null
}

output "vm_name" {
  description = "Name of the primary Virtual Machine (backward compatibility)"
  value       = length(module.vm) > 0 ? module.vm[0].name : null
}

output "vm_id" {
  description = "ID of the primary Virtual Machine (backward compatibility)"
  value       = length(module.vm) > 0 ? module.vm[0].resource_id : null
}

output "vm_network_info" {
  description = "VM network information"
  value       = "Check Azure portal for IP addresses"
}

output "nsg_name" {
  description = "Name of the primary Network Security Group (backward compatibility)"
  value       = length(module.nsg) > 0 ? module.nsg[0].name : null
}

output "nsg_id" {
  description = "ID of the primary Network Security Group (backward compatibility)"
  value       = length(module.nsg) > 0 ? module.nsg[0].resource_id : null
}

output "deployment_info" {
  description = "Deployment summary"
  value = {
    resource_groups  = local.resource_group_names
    networks         = local.network_names
    security_groups  = local.security_group_names
    virtual_machines = keys(local.virtual_machines)
  }
}