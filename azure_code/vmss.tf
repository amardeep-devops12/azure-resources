resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = "vmssworkspace"
  resource_group_name = "python1234"
  location            = "West Europe"
  sku                 = "PerGB2018"
}

module "vmss" {
  source              = "./modules/vmss"
  resource_group_name = "python1234"
  vnet_name           = "test"
  subnet_name         = "public-subnet-0"
  # storage account for boot diagnostics
  storage_account_name        = "tesing"
  storage_account_tier        = "Standard"
  vmscaleset_name             = "testvmss"
  public_ip_allocation_method = "Static"
  public_ip_sku               = "Standard"
  public_ip_sku_tier          = "Regional"
  # This module support multiple Pre-Defined Linux and Windows Distributions.
  # Check the README.md file for more pre-defined images for Ubuntu, Centos, RedHat.
  # Please make sure to use gen2 images supported VM sizes if you use gen2 distributions
  # Specify `disable_password_authentication = false` to create random admin password
  # Specify a valid password with `admin_password` argument to use your own password 
  # To generate SSH key pair, specify `generate_admin_ssh_key = true`
  # To use existing key pair, specify `admin_ssh_key_data` to a valid SSH public key path.  
  os_flavor               = "linux"
  linux_distribution_name = "ubuntu2204"
  virtual_machine_size    = "Standard_D2s_v3"
  admin_username          = "azureadmin"
  generate_admin_ssh_key  = true
  instances_count         = 2
  custom_data = base64encode(<<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y nginx
              sudo systemctl start nginx
              sudo systemctl enable nginx
              EOF
  )

  # Proxymity placement group, Automatic Instance repair and adding Public IP to VM's are optional.
  # remove these argument from module if you dont want to use it.  
  enable_proximity_placement_group    = true
  assign_public_ip_to_each_vm_in_vmss = true
  enable_automatic_instance_repair    = true

  # Public and private load balancer support for VM scale sets
  # Specify health probe port to allow LB to detect the backend endpoint status
  # Standard Load Balancer helps load-balance TCP and UDP flows on all ports simultaneously
  # Specify the list of ports based on your requirement for Load balanced ports
  # for additional data disks, provide the list for required size for the disk. 
  enable_load_balancer            = true
  load_balancer_type              = "public"
  load_balancer_sku               = "Standard"
  load_balancer_health_probe_port = 80
  load_balanced_port_list         = [80, 443]
  additional_data_disks           = [100, 200]

  # Enable Auto scaling feature for VM scaleset by set argument to true. 
  # Instances_count in VMSS will become default and minimum instance count.
  # Automatically scale out the number of VM instances based on CPU Average only.    
  enable_autoscale_for_vmss          = true
  minimum_instances_count            = 2
  maximum_instances_count            = 5
  scale_out_cpu_percentage_threshold = 80
  scale_in_cpu_percentage_threshold  = 20

  # Boot diagnostics to troubleshoot virtual machines, by default uses managed 
  # To use custom storage account, specify `storage_account_name` with a valid name
  # Passing a `null` value will utilize a Managed Storage Account to store Boot Diagnostics
  enable_boot_diagnostics = true

  # Network Seurity group port allow definitions for each Virtual Machine
  # NSG association to be added automatically for all network interfaces.
  # Remove this NSG rules block, if `existing_network_security_group_id` is specified
  nsg_inbound_rules = [
    {
      name                   = "http"
      destination_port_range = "80"
      source_address_prefix  = "*"
    },

    {
      name                   = "https"
      destination_port_range = "443"
      source_address_prefix  = "*"
    },
  ]

  # (Optional) To enable Azure Monitoring and install log analytics agents
  # (Optional) Specify `storage_account_name` to save monitoring logs to storage.   
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics.id

  # Deploy log analytics agents to virtual machine. 
  # Log analytics workspace customer id and primary shared key required.
  deploy_log_analytics_agent                 = true
  log_analytics_customer_id                  = azurerm_log_analytics_workspace.log_analytics.workspace_id
  log_analytics_workspace_primary_shared_key = azurerm_log_analytics_workspace.log_analytics.primary_shared_key

  # Adding additional TAG's to your Azure resources
  tags = {
    ProjectName = "project"
  }
  depends_on = [azurerm_log_analytics_workspace.log_analytics]
}


