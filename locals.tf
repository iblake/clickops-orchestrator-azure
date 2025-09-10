locals {
  # OCI modular orchestration pattern: dependency variables override local configs
  # This enables composition where external modules can provide computed resources
  # Falls back to direct JSON config when no dependencies are provided

  # HYBRID PATTERN ARCHITECTURE:
  # All module resources follow this filter pattern: for_each with !config.is_existing
  # - Modules create NEW resources (is_existing=false)  
  # - Data sources reference EXISTING resources (is_existing=true)
  all_resource_groups = var.module_dependencies.resource_groups != null ? var.module_dependencies.resource_groups : var.resource_groups
  all_networks        = var.module_dependencies.networks != null ? var.module_dependencies.networks : var.networks
  all_security_groups = var.module_dependencies.security_groups != null ? var.module_dependencies.security_groups : var.security_groups

  # Common resource group resolution helper - eliminates repeated conditional logic
  _resource_group_resolution = {
    for key, config in local.all_resource_groups : key => {
      name     = config.name
      location = config.location
    }
  }

  # Process Resource Groups (new vs existing)
  resource_groups = {
    for key, config in local.all_resource_groups : key => {
      name        = config.name
      location    = config.location
      resource_id = config.resource_id # null for new, ID for existing
      is_existing = config.resource_id != null
    }
  }

  # Process Networks with hybrid support
  networks = {
    for key, config in local.all_networks : key => merge(
      {
        name               = config.name
        resource_group_key = config.resource_group_key
        resource_id        = config.resource_id
        is_existing        = config.resource_id != null
        cidr               = config.cidr
        subnets            = config.subnets
      },
      # Hybrid pattern: Only resolve resource group details for NEW resources
      # Existing resources already have their RG context embedded in resource_id
      # Cross-reference lookup: JSON config uses keys, Terraform needs actual names/locations
      config.resource_id == null && config.resource_group_key != null ? {
        resource_group_name = local._resource_group_resolution[config.resource_group_key].name
        location            = local._resource_group_resolution[config.resource_group_key].location
        } : {
        resource_group_name = null
        location            = null
      }
    )
  }

  # Process Security Groups with hybrid support
  security_groups = {
    for key, config in local.all_security_groups : key => merge(
      {
        name        = config.name
        resource_id = config.resource_id
        is_existing = config.resource_id != null
        rules       = config.rules
      },
      # Hybrid pattern: Only resolve RG for new NSGs (same pattern as networks)
      config.resource_id == null && config.resource_group_key != null ? {
        resource_group_name = local._resource_group_resolution[config.resource_group_key].name
        location            = local._resource_group_resolution[config.resource_group_key].location
        } : {
        resource_group_name = null
        location            = null
      }
    )
  }

  # Process Virtual Machines with hybrid references
  virtual_machines = {
    for key, config in var.virtual_machines : key => {
      name                = config.name
      resource_group_name = local._resource_group_resolution[config.resource_group_key].name
      location            = local._resource_group_resolution[config.resource_group_key].location
      size                = config.size
      admin_username      = config.admin_username
      ssh_key_path        = config.ssh_key_path
      ssh_public_key      = file(pathexpand(config.ssh_key_path))
      create_public_ip    = config.create_public_ip
      public_ip_sku       = config.public_ip_sku
      network_key         = config.network_key
      subnet_key          = config.subnet_key
      security_group_key  = config.security_group_key
    }
  }

  # Extract resource group names from Azure resource IDs using regex
  # Pattern: /subscriptions/{sub}/resourceGroups/{rg-name}/providers/{provider}/...
  # Needed because existing resources only provide full resource IDs, but data sources need RG names

  # Step 1: Collect all non-null resource IDs with explicit filtering
  _all_resource_ids = concat(
    [for net in local.networks : net.resource_id if net.resource_id != null],
    [for sg in local.security_groups : sg.resource_id if sg.resource_id != null]
  )

  # Step 2: Extract unique resource group names from collected IDs
  resource_group_from_id = {
    for id in distinct(local._all_resource_ids) :
    id => regex("/resourceGroups/([^/]+)/", id)[0]
  }

  # Helper for resource group name resolution in data sources
  resolved_resource_group_names = {
    networks = {
      for key, config in local.networks : key =>
      config.resource_group_name != null ? config.resource_group_name :
      try(local.resource_group_from_id[config.resource_id], null)
    }
    security_groups = {
      for key, config in local.security_groups : key =>
      config.resource_group_name != null ? config.resource_group_name :
      try(local.resource_group_from_id[config.resource_id], null)
    }
  }

  # Helper for resource source labels in outputs
  resource_sources = {
    resource_groups = { for k, v in local.resource_groups : k => v.is_existing ? "existing" : "created" }
    networks        = { for k, v in local.networks : k => v.is_existing ? "existing" : "created" }
    security_groups = { for k, v in local.security_groups : k => v.is_existing ? "existing" : "created" }
  }

  # Pre-compute existing subnet combinations for efficient data source lookup
  # Flattening strategy: network.subnet → flat list with composite keys (net_key.subnet_key)
  # Only processes subnets marked as existing (subnet.resource_id != null)
  # Resolves resource group names using coalesce for cleaner null handling
  existing_subnets = {
    for combo in flatten([
      for net_key, network in local.networks : [
        for subnet_key, subnet in network.subnets : {
          key                  = "${net_key}.${subnet_key}"
          name                 = subnet.name
          virtual_network_name = network.name
          # Simplified resource group resolution using coalesce + try
          resource_group_name = coalesce(
            network.resource_group_name,
            try(local.resource_group_from_id[network.resource_id], null)
          )
        }
        if network.is_existing
      ]
    ]) : combo.key => combo
  }

  # Performance optimization: compute resource IDs once, reference multiple times
  # Eliminates repeated conditional logic in VM network interface configuration
  # Hybrid pattern: dynamically selects between data sources (existing) and modules (new)
  resource_ids = {
    # Resource Group IDs
    resource_groups = {
      for key, config in local.resource_groups : key => (
        config.is_existing ?
        data.azurerm_resource_group.existing[key].id :
        module.resource_group[key].resource_id
      )
    }

    # Network IDs
    networks = {
      for key, config in local.networks : key => (
        config.is_existing ?
        data.azurerm_virtual_network.existing[key].id :
        module.vnet[key].resource_id
      )
    }

    # Security Group IDs - computed once, used multiple times
    security_groups = {
      for key, config in local.security_groups : key => (
        config.is_existing ?
        data.azurerm_network_security_group.existing[key].id :
        module.nsg[key].resource_id
      )
    }

    # Subnet IDs - computed once, used multiple times  
    subnets = {
      for net_key, network in local.networks : net_key => {
        for subnet_key, subnet in network.subnets : subnet_key => (
          network.is_existing ?
          data.azurerm_subnet.existing["${net_key}.${subnet_key}"].id :
          module.vnet[net_key].subnets[subnet_key].resource_id
        )
      }
    }
  }
}