terraform {
  
required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region     = "us-west-2"
  access_key = "my-access-key"
  secret_key = "my-secret-key"
}

# Create a VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/32"
}








/*

resource "azurerm_resource_group" "mtc-rg" {
  name     = "mtc-resources"
  location = "Australia East"
  tags = {
    environment = "Dev"
  }
}

resource "azurerm_virtual_network" "mtc-vn" {
  name                = "mtc-network"
  resource_group_name = azurerm_resource_group.mtc-rg.name
  location            = azurerm_resource_group.mtc-rg.location
  address_space       = ["10.123.0.0/16"]

  tags = {
    environment = "dev"
  }
}

resource "azurerm_subnet" "mtc-subnet" {
  name                 = "mtc-subnet"
  resource_group_name  = azurerm_resource_group.mtc-rg.name
  virtual_network_name = azurerm_virtual_network.mtc-vn.name
  address_prefixes     = ["10.123.1.0/24"]
}

resource "azurerm_network_security_group" "mtc-sg" {
  name                = "mtc-sg"
  location            = azurerm_resource_group.mtc-rg.location
  resource_group_name = azurerm_resource_group.mtc-rg.name

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_security_rule" "mtc-dev-rule-ssh" {
  name                        = "mtc-dev-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"  # Set the protocol to TCP for SSH
  source_port_range           = "*"    # Allow traffic from any source port
  destination_port_range      = "22"   # Allow traffic only on port 22 (SSH)
  source_address_prefix       = "*"    # Allow traffic from any source IP address
  destination_address_prefix  = "*"    # Allow traffic to any destination IP address
  resource_group_name         = azurerm_resource_group.mtc-rg.name
  network_security_group_name = azurerm_network_security_group.mtc-sg.name
}

resource "azurerm_network_security_rule" "mtc-dev-rule-http" {
  name                        = "mtc-dev-rule-http"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"  # Set the protocol to TCP for HTTP
  source_port_range           = "*"    # Allow traffic from any source port
  destination_port_range      = "80"   # Allow traffic only on port 80 (HTTP)
  source_address_prefix       = "*"    # Allow traffic from any source IP address
  destination_address_prefix  = "*"    # Allow traffic to any destination IP address
  resource_group_name         = azurerm_resource_group.mtc-rg.name
  network_security_group_name = azurerm_network_security_group.mtc-sg.name
}


resource "azurerm_network_security_rule" "mtc-dev-rule-HTTPS" {
  name                        = "mtc-dev-rule-https"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"  # Set the protocol to TCP for HTTP
  source_port_range           = "*"    # Allow traffic from any source port
  destination_port_range      = "443"   # Allow traffic only on port 443 (HTTPS)
  source_address_prefix       = "*"    # Allow traffic from any source IP address
  destination_address_prefix  = "*"    # Allow traffic to any destination IP address
  resource_group_name         = azurerm_resource_group.mtc-rg.name
  network_security_group_name = azurerm_network_security_group.mtc-sg.name
}


resource "azurerm_subnet_network_security_group_association" "mtc-sga" {
  subnet_id                 = azurerm_subnet.mtc-subnet.id
  network_security_group_id = azurerm_network_security_group.mtc-sg.id
}

resource "azurerm_public_ip" "mtc-ip" {
  name                = "mtc-ip"
  resource_group_name = azurerm_resource_group.mtc-rg.name
  location            = azurerm_resource_group.mtc-rg.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "mtc-nic" {
  name                = "mtc-nic"
  location            = azurerm_resource_group.mtc-rg.location
  resource_group_name = azurerm_resource_group.mtc-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.mtc-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mtc-ip.id
  }

  tags = {
    environment = "dev"
  }
}

resource "azurerm_linux_virtual_machine" "mtc-vm" {
  name                = "mtc-vm"
  resource_group_name = azurerm_resource_group.mtc-rg.name
  location            = azurerm_resource_group.mtc-rg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.mtc-nic.id,
  ]

 custom_data = filebase64("customdata.tpl")

  admin_ssh_key {
    username   = "adminuser"
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  #To enable SSH once provisioned
  provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-script.tpl", {
      hostname     = self.public_ip_address,
      user         = "adminuser",
      identityfile = "~/.ssh/mtcazurekey"
    })
    interpreter = var.host_os == "windows" ? ["Powershell", "-Command"] : ["bash", "-c"]
  }

tags = {
    environment = "dev"
  }
}

data "azurerm_public_ip" "mtc-ip-data" {
  name                = azurerm_public_ip.mtc-ip.name
  resource_group_name = azurerm_resource_group.mtc-rg.name
}

output "public_ip_address" {
  value = "${azurerm_linux_virtual_machine.mtc-vm.name}: ${data.azurerm_public_ip.mtc-ip-data.ip_address}"
}

#################################
# Azure Function
resource "azurerm_storage_account" "mtc-sa" {
  name                     = "pythonfuncstoracc"
  resource_group_name      = azurerm_resource_group.mtc-rg.name
  location                 = "Australia Southeast"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}


resource "azurerm_service_plan" "mtc-sp" {
  name                = "NanoGKPythonFunction"
  resource_group_name = azurerm_resource_group.mtc-rg.name
  location            = "Australia Southeast"
  os_type             = "Linux"
  sku_name            = "Y1"
}


resource "azurerm_linux_function_app" "mtc-functionapp" {
  name                = "NanoGKPythonFunction"
  resource_group_name = azurerm_resource_group.mtc-rg.name
  location            = "Australia Southeast"

  storage_account_name       = azurerm_storage_account.mtc-sa.name
  storage_account_access_key = azurerm_storage_account.mtc-sa.primary_access_key
  service_plan_id            = azurerm_service_plan.mtc-sp.id

site_config {
}

app_settings = {
    FUNCTIONS_EXTENSION_VERSION = "~3"
    AzureWebJobsStorage        = "DefaultEndpointsProtocol=https;AccountName=${azurerm_storage_account.mtc-sa.name};AccountKey=${azurerm_storage_account.mtc-sa.primary_access_key};EndpointSuffix=core.windows.net"
   
    # Specify the URL of the GitHub-hosted Python script
    WEBSITE_RUN_FROM_PACKAGE   = "https://github.com/N4nn0x/terraform_cloud/raw/main/AzureFunction/PythonScript.py"
    AzureWebJobsHttpRoute = "PythonFunction"  # Route to access the function via HTTP
    FUNCTIONS_WORKER_RUNTIME = "python"  # Python worker runtime
  }
}
*/
