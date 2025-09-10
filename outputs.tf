# Resource Groups - Hybrid Output (New + Existing)
output "resource_groups" {
  description = "All resource groups - both newly created and existing ones referenced"
  value = {
    for key, config in local.resource_groups : key => {
      name     = config.name
      location = config.location
      id       = local.resource_ids.resource_groups[key]
      source   = local.resource_sources.resource_groups[key]
    }
  }
}

# Virtual Networks - Hybrid Output (New + Existing)
output "networks" {
  description = "All virtual networks and subnets - both newly created and existing ones referenced"
  value = {
    for key, config in local.networks : key => {
      name   = config.name
      cidr   = config.cidr
      id     = local.resource_ids.networks[key]
      source = local.resource_sources.networks[key]
      subnets = {
        for subnet_key, subnet_config in config.subnets : subnet_key => {
          name   = subnet_config.name
          cidr   = subnet_config.cidr
          id     = local.resource_ids.subnets[key][subnet_key]
          source = subnet_config.resource_id != null ? "existing" : (config.is_existing ? "mixed" : "created")
        }
      }
    }
  }
}

# Security Groups - Hybrid Output (New + Existing)
output "security_groups" {
  description = "All network security groups - both newly created and existing ones referenced"
  value = {
    for key, config in local.security_groups : key => {
      name   = config.name
      id     = local.resource_ids.security_groups[key]
      source = local.resource_sources.security_groups[key]
    }
  }
}

# Virtual Machines - Always New (with SSH Connection Info)
output "virtual_machines" {
  description = "Virtual machines with SSH connection information"
  value = {
    for key, vm in module.vm : key => {
      name         = vm.name
      id           = vm.resource_id
      ssh_username = local.virtual_machines[key].admin_username
      ssh_key_path = local.virtual_machines[key].ssh_key_path
      ssh_command  = "ssh -i ${local.virtual_machines[key].ssh_key_path} ${local.virtual_machines[key].admin_username}@<VM_PUBLIC_IP>"
    }
  }
}

# Simple deployment summary
output "deployment_summary" {
  description = "Simple summary of deployed resources"
  value = {
    resource_groups = {
      total    = length(local.resource_groups)
      created  = length([for key, config in local.resource_groups : key if !config.is_existing])
      existing = length([for key, config in local.resource_groups : key if config.is_existing])
    }
    networks = {
      total    = length(local.networks)
      created  = length([for key, config in local.networks : key if !config.is_existing])
      existing = length([for key, config in local.networks : key if config.is_existing])
    }
    security_groups = {
      total    = length(local.security_groups)
      created  = length([for key, config in local.security_groups : key if !config.is_existing])
      existing = length([for key, config in local.security_groups : key if config.is_existing])
    }
    virtual_machines = {
      total = length(module.vm)
    }
    message = "Check Azure portal for VM public IP addresses"
  }
}

# Resource IDs for external tools
output "resource_ids" {
  description = "All resource IDs for easy reference"
  value = {
    resource_groups = local.resource_ids.resource_groups
    networks        = local.resource_ids.networks
    security_groups = local.resource_ids.security_groups
    subnets         = local.resource_ids.subnets
    virtual_machines = {
      for key, vm in module.vm : key => vm.resource_id
    }
  }
}