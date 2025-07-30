# Azure Landing Zones Orchestrator - Complete Guide (OCI Pattern)

This orchestrator implements the **OCI Landing Zones pattern** for Azure, supporting both **creating new resources** and **using existing resources** through modular JSON configuration and key-based references.

## 🆕 Modular Architecture (OCI Landing Zones Pattern)

### Domain-Based Organization

```
config/
├── iam/
│   └── resource-groups.json       # Resource Groups
├── network/
│   └── networks.json             # VNets and Subnets  
├── security/
│   └── security-groups.json      # Network Security Groups
└── compute/
    └── virtual-machines.json     # Virtual Machines
```

### OCI Pattern Advantages

1. **Key-Based References**: Instead of hardcoded IDs, uses logical references (`resource_group_key: "rg-demo"`)
2. **Explicit Var-files**: Terraform commands require passing JSON files as var-files (same as OCI)
3. **Automatic Resolution**: The orchestrator automatically resolves references between domains
4. **Hybrid Compatibility**: Same configuration works for both new AND existing resources
5. **Modular Management**: Each domain can be managed independently

## 🚀 Base Commands (OCI Pattern)

**All commands require passing the 4 JSON files as var-files:**

```bash
# Plan
terraform plan \
  -var-file=config/iam/resource-groups.json \
  -var-file=config/network/networks.json \
  -var-file=config/security/security-groups.json \
  -var-file=config/compute/virtual-machines.json

# Apply  
terraform apply \
  -var-file=config/iam/resource-groups.json \
  -var-file=config/network/networks.json \
  -var-file=config/security/security-groups.json \
  -var-file=config/compute/virtual-machines.json

# Destroy
terraform destroy \
  -var-file=config/iam/resource-groups.json \
  -var-file=config/network/networks.json \
  -var-file=config/security/security-groups.json \
  -var-file=config/compute/virtual-machines.json
```

## 📋 CASE 1: Create ALL resources from scratch

**When to use this case?**
- Starting a new project
- No existing Azure infrastructure  
- Want to create: Resource Group + VNet + Subnet + NSG + VM

### 🔧 CASE 1 Configuration

#### Step 1: Resource Groups (`config/iam/resource-groups.json`)

```json
{
  "resource_groups": {
    "rg-demo": {
      "name": "rg-free-demo",
      "location": "eastus"
    }
  }
}
```

#### Step 2: Networks (`config/network/networks.json`)

```json
{
  "networks": {
    "vnet-demo": {
      "resource_group_key": "rg-demo",
      "name": "vnet-free-demo",
      "cidr": "10.0.0.0/16",
      "subnets": {
        "subnet-public": {
          "name": "subnet-public",
          "cidr": "10.0.1.0/24"
        }
      }
    }
  }
}
```

#### Step 3: Security Groups (`config/security/security-groups.json`)

```json
{
  "security_groups": {
    "nsg-web": {
      "resource_group_key": "rg-demo",
      "name": "nsg-web",
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
}
```

#### Step 4: Virtual Machines (`config/compute/virtual-machines.json`)

```json
{
  "virtual_machines": {
    "vm-web": {
      "resource_group_key": "rg-demo",
      "network_key": "vnet-demo",
      "subnet_key": "subnet-public",
      "security_group_key": "nsg-web",
      "name": "vm-web",
      "size": "Standard_B1s",
      "admin_username": "azureuser", 
      "ssh_key_path": "~/.ssh/azure_vm_key.pub",
      "create_public_ip": true,
      "public_ip_sku": "Basic"
    }
  }  
}
```

### ⚡ CASE 1 Deployment

```bash
# 1. Generate SSH key if it doesn't exist
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_vm_key -N ''

# 2. Validate configuration
terraform validate

# 3. View deployment plan (OCI Pattern)
terraform plan \
  -var-file=config/iam/resource-groups.json \
  -var-file=config/network/networks.json \
  -var-file=config/security/security-groups.json \
  -var-file=config/compute/virtual-machines.json

# 4. Create ALL infrastructure (~18 resources)
terraform apply \
  -var-file=config/iam/resource-groups.json \
  -var-file=config/network/networks.json \
  -var-file=config/security/security-groups.json \
  -var-file=config/compute/virtual-machines.json

# 5. View created resources
terraform output
```

**✅ Result:** ALL new resources are created with key-based references automatically resolved.

---

## 🔗 CASE 2: Use EXISTING resources + create VM

**When to use this case?**
- You already have Resource Group, VNet, Subnet, NSG in Azure (created with CASE 1)
- You only want to add/remove VMs from existing infrastructure
- You want modular resource management

### 🔧 CASE 2 Configuration

**The magic of the OCI pattern!** You use the **same JSON files** as in CASE 1. The system automatically detects which resources already exist in the Terraform state.

### Example: Remove VM but preserve network

#### Modify only: `config/compute/virtual-machines.json`

```json
{
  "virtual_machines": {}
}
```

#### Keep unchanged: Rest of JSON files (iam, network, security)

### Example: Re-create VM using existing infrastructure  

#### Restore: `config/compute/virtual-machines.json`

```json
{
  "virtual_machines": {
    "vm-web": {
      "resource_group_key": "rg-demo",
      "network_key": "vnet-demo",
      "subnet_key": "subnet-public", 
      "security_group_key": "nsg-web",
      "name": "vm-web",
      "size": "Standard_B1s",
      "admin_username": "azureuser",
      "ssh_key_path": "~/.ssh/azure_vm_key.pub",
      "create_public_ip": true,
      "public_ip_sku": "Basic"
    }
  }
}
```

### ⚡ CASE 2 Deployment

```bash
# 1. Same command as CASE 1 (OCI Pattern)
terraform plan \
  -var-file=config/iam/resource-groups.json \
  -var-file=config/network/networks.json \
  -var-file=config/security/security-groups.json \
  -var-file=config/compute/virtual-machines.json

# 2. Apply changes (only creates VM ~7 resources)
terraform apply \
  -var-file=config/iam/resource-groups.json \
  -var-file=config/network/networks.json \
  -var-file=config/security/security-groups.json \
  -var-file=config/compute/virtual-machines.json
```

**✅ Result:** Only the VM is created, automatically reusing the existing network infrastructure.

---

## 🤔 Difference between CASE 1 and CASE 2

| Aspect | **CASE 1: New Resources** | **CASE 2: Existing Resources** |
|---------|------------------------------|----------------------------------|
| **What does it create?** | EVERYTHING from scratch (~18 resources) | Only missing components (~7 resources) |
| **JSON Configuration** | 4 files with complete resources | **Same 4 files** |
| **Commands** | **Identical** (OCI pattern) | **Identical** (OCI pattern) |
| **Detection** | Empty Terraform state | Terraform state with existing resources |
| **Use Case** | New project | Modular resource management |
| **Complexity** | Low | **Equally low** |

## 🎯 Key-Based Reference System

**Keys** are logical identifiers that allow referencing resources between domains:

### Automatic Reference Resolution

- `resource_group_key: "rg-demo"` → Resolves to `rg-free-demo` (real name)
- `network_key: "vnet-demo"` → Resolves to `vnet-free-demo` (real name)
- `subnet_key: "subnet-public"` → Resolves to `subnet-public` (real name)  
- `security_group_key: "nsg-web"` → Resolves to `nsg-web` (real name)

### Resolution Flow

```
JSON Config → locals.tf → Resource References → Azure Resources
     ↓              ↓              ↓                    ↓
   "rg-demo"  →  Processing  →  rg-free-demo  →  Azure RG
```

## 📤 Key-Structured Outputs

```bash
# View all outputs
terraform output

# View specific outputs by domain
terraform output resource_groups
terraform output networks  
terraform output security_groups
terraform output virtual_machines
```

### Output Example:

```json
{
  "resource_groups": {
    "rg-demo": {
      "name": "rg-free-demo",
      "id": "/subscriptions/.../resourceGroups/rg-free-demo",
      "location": "eastus"
    }
  },
  "networks": {
    "vnet-demo": {
      "name": "vnet-free-demo", 
      "id": "/subscriptions/.../virtualNetworks/vnet-free-demo",
      "subnets": {
        "subnet-public": {
          "name": "subnet-public",
          "id": "/subscriptions/.../subnets/subnet-public"
        }
      }
    }
  },
  "virtual_machines": {
    "vm-web": {
      "name": "vm-web",
      "id": "/subscriptions/.../virtualMachines/vm-web",
      "size": "Standard_B1s"
    }
  }
}
```

## 🛠️ Advanced Use Cases

### Modular Domain Management

```bash  
# Remove only VMs (preserve network)
# Empty: config/compute/virtual-machines.json → {"virtual_machines": {}}
terraform apply -var-file=... # Only destroys VMs

# Add new VM  
# Fill: config/compute/virtual-machines.json with new VM
terraform apply -var-file=... # Only creates new VM

# Modify NSG rules
# Edit: config/security/security-groups.json  
terraform apply -var-file=... # Only updates NSG
```

### Configuration Scalability

```json
// Multiple VMs in the same domain
{
  "virtual_machines": {
    "vm-web": { /* web VM config */ },
    "vm-api": { /* api VM config */ },
    "vm-db": { /* database VM config */ }
  }
}

// Multiple NSGs in the same domain  
{
  "security_groups": {
    "nsg-web": { /* web rules */ },
    "nsg-api": { /* API rules */ },
    "nsg-db": { /* database rules */ }
  }
}
```

## 🔧 Development Commands

```bash
# Validate Terraform configuration
terraform validate

# Format Terraform files  
terraform fmt

# Validate JSON
cat config/iam/resource-groups.json | jq .

# View current state
terraform show

# View plan without applying  
terraform plan -var-file=config/iam/resource-groups.json \
  -var-file=config/network/networks.json \
  -var-file=config/security/security-groups.json \
  -var-file=config/compute/virtual-machines.json

# Destroy infrastructure
terraform destroy -var-file=config/iam/resource-groups.json \
  -var-file=config/network/networks.json \
  -var-file=config/security/security-groups.json \
  -var-file=config/compute/virtual-machines.json
```

## 🔒 Azure Free Tier Compliance

The orchestrator automatically enforces free tier limits:

- **VM Sizes**: Only `Standard_B1s` (1 vCPU, 1GB RAM) and `Standard_B1ms` (1 vCPU, 2GB RAM)
- **Disk Type**: `Standard_LRS` only, 30GB default
- **Public IP**: `Basic` SKU with `Static` allocation  
- **Validation**: Type constraints prevent non-free-tier configurations

## 🆘 Common Issues

### Error: "SSH key not found"
```bash
# Solution: Generate the SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_vm_key -N ''
```

### Error: "Must provide var-file arguments"  
```bash
# Solution: Always use the 4 var-files (OCI pattern)
terraform plan \
  -var-file=config/iam/resource-groups.json \
  -var-file=config/network/networks.json \
  -var-file=config/security/security-groups.json \
  -var-file=config/compute/virtual-machines.json
```

### Error: "Invalid JSON"
```bash
# Solution: Validate JSON syntax
cat config/iam/resource-groups.json | jq .
cat config/network/networks.json | jq .
cat config/security/security-groups.json | jq .  
cat config/compute/virtual-machines.json | jq .
```

### Error: "Key not found in reference"
```bash
# Solution: Verify that keys exist in their domains
# Example: If you use "resource_group_key": "rg-demo"
# "rg-demo" must exist in config/iam/resource-groups.json
```

## 🚀 Ready to Get Started?

1. **For new project**: Follow [CASE 1](#-case-1-create-all-resources-from-scratch)
2. **For modular management**: Follow [CASE 2](#-case-2-use-existing-resources--create-vm) 
3. **For advanced development**: Review [advanced use cases](#-advanced-use-cases)

**The OCI Landing Zones pattern gives you maximum flexibility with minimum complexity!**