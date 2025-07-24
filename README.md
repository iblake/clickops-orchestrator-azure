# Azure Landing Zones Orchestrator (Free Tier Edition)

##  Requirements

- **Terraform** >= 1.6
- **Azure Provider** ~> 4.37  
- **Azure CLI** (only for Service Principal creation)

## 🔧 Azure Verified Modules (AVM) Used

| Resource                   | AVM Module                                         | Version |
|----------------------------|----------------------------------------------------|---------|
| **Resource Groups**         | `Azure/avm-res-resources-resourcegroup/azurerm`    | 0.2.1   |
| **Virtual Networks**        | `Azure/avm-res-network-virtualnetwork/azurerm`     | 0.9.2   |
| **Network Security Groups** | `Azure/avm-res-network-networksecuritygroup/azurerm`| 0.4.0   |
| **Virtual Machines**        | `Azure/avm-res-compute-virtualmachine/azurerm`     | 0.19.0  |

##  JSON Configuration

###  For NEW Resources

#### `config_jsons/iam.json`
```json
{
  "resource_group": {
    "name": "rg-free-demo",
    "location": "eastus"
  }
}
```

#### `config_jsons/network.json` 
```json
{
  "network": {
    "vnet_name": "vnet-free-demo",
    "vnet_cidr": "10.0.0.0/16",
    "subnet_name": "subnet-public", 
    "subnet_cidr": "10.0.1.0/24"
  }
}
```

#### `config_jsons/compute.json`
```json
{
  "vm": {
    "name": "vm-free",
    "size": "Standard_B1s",
    "admin_username": "azureuser",
    "ssh_key_path": "~/.ssh/azure_vm_key.pub"
  }
}
```

#### `config_jsons/security.json`
```json
{
  "security": {
    "rules": [
      {
        "name": "SSH",
        "port": 22,
        "protocol": "Tcp",
        "source": "*",
        "priority": 1000,
        "description": "Allow SSH access"
      }
    ]
  }
}
```

###  For EXISTING Resources

#### `config_jsons/iam-existing.json`
```json
{
  "resource_group": {
    "existing_name": "my-existing-resource-group"
  }
}
```

#### `config_jsons/network-existing.json`
```json
{
  "network": {
    "existing_vnet_name": "vnet-prod-hub",
    "existing_subnet_name": "subnet-workloads", 
    "existing_resource_group": "rg-networking"
  }
}
```

#### `config_jsons/security-existing.json`
```json
{
  "security": {
    "existing_nsg_name": "nsg-prod-web",
    "existing_nsg_resource_group": "rg-security"
  }
}
```


##  ONLY Free Tier Resources (Automatically Validated)

###  Allowed VM Sizes
- `Standard_B1s` (1 vCPU, 1GB RAM)
- `Standard_B1ms` (1 vCPU, 2GB RAM)

###  Disk Configurations
- **Type**: `Standard_LRS` only
- **Size**: 30GB (default)
- **Caching**: `ReadWrite`

###  Network Configuration
- **Public IP**: `Basic` SKU (if enabled)
- **Allocation**: `Dynamic`

##  Usage Examples

### Example 1: VM in Existing Subnet
**Required files:**
- `iam-existing.json` (Existing resource group)
- `network-existing.json` (Existing VNet and subnet)  
- `compute.json` (New VM)
- `security.json` (NSG with SSH rules)

```bash
terraform plan \
  -var-file=config_jsons/iam-existing.json \
  -var-file=config_jsons/network-existing.json \
  -var-file=config_jsons/compute.json \
  -var-file=config_jsons/security.json
```

### Example 2: Completely New Infrastructure
**Required files:**
- `iam.json` (New resource group)
- `network.json` (New VNet with CIDR) 
- `compute.json` (New VM)
- `security.json` (NSG with multiple rules)

```bash
terraform plan \
  -var-file=config_jsons/iam.json \
  -var-file=config_jsons/network.json \
  -var-file=config_jsons/compute.json \
  -var-file=config_jsons/security.json
```

##  Orchestrator Outputs

After deployment, you get useful information:

```hcl
Outputs:

deployment_info = {
  "location" = "eastus"
  "resource_group" = "rg-free-demo"
  "vm_name" = "vm-public"
  "vm_size" = "Standard_B1s"
}

nsg_id = "/subscriptions/fb006a95-6e01-4852-8adc-xxxx/resourceGroups/rg-free-demo/providers/Microsoft.Network/networkSecurityGroups/vm-public-nsg"

nsg_name = "vm-public-nsg"

resource_group_id = "/subscriptions/fb006a95-6e01-4852-8adc-xxxx/resourceGroups/rg-free-demo"

resource_group_name = "rg-free-demo"

subnet_id = "/subscriptions/fb006a95-6e01-4852-8adc-xxxx/resourceGroups/rg-free-demo/providers/Microsoft.Network/virtualNetworks/vnet-free-demo/subnets/subnet-public"

vm_id = "/subscriptions/fb006a95-6e01-4852-8adc-xxxx/resourceGroups/rg-free-demo/providers/Microsoft.Compute/virtualMachines/vm-public"

vm_name = "vm-public"

vm_network_info = "Check Azure portal for IP addresses"

vnet_id = "/subscriptions/fb006a95-6e01-4852-8adc-xxxx/resourceGroups/rg-free-demo/providers/Microsoft.Network/virtualNetworks/vnet-free-demo"

vnet_name = "vnet-free-demo"
```

##  Resource Destruction

### Destroy Everything
```bash
# With JSON config files
terraform destroy \
  -var-file=config_jsons/iam.json \
  -var-file=config_jsons/network.json \
  -var-file=config_jsons/compute.json \
  -var-file=config_jsons/security.json

# OR simply
terraform destroy
```