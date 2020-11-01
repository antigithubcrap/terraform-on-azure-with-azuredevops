variable location { }
variable linux-virtual-machine-01-admin-username { }
variable linux-virtual-machine-01-admin-password { }

provider "azurerm" {

    version = "2.34.0"

    features { }
}

data "template_file" "template-file-01" {

    template = file("terraform-01-custom-data.sh")
}

resource "random_id" "terraform-randomid-01" {

    keepers = {

        azi_id = 1
    }

    byte_length = 2
}

resource "azurerm_resource_group" "terraform-resourcegroup-01" {

    name     = "terraform-global-01-${random_id.terraform-randomid-01.hex}"
    location = var.location

    tags = {

        CONTEXT = "TERRAFORM"
    }
}

resource "azurerm_virtual_network" "terraform-virtualnetwork-01" {

    name                = "terraform-01-${random_id.terraform-randomid-01.hex}"
    address_space       = ["192.168.255.0/24"]
    location            = azurerm_resource_group.terraform-resourcegroup-01.location
    resource_group_name = azurerm_resource_group.terraform-resourcegroup-01.name

    tags = {

        CONTEXT = "TERRAFORM"
    }
}

resource "azurerm_subnet" "terraform-subnet-01-01" {

    name                 = "AzureBastionSubnet"
    resource_group_name  = azurerm_resource_group.terraform-resourcegroup-01.name
    virtual_network_name = azurerm_virtual_network.terraform-virtualnetwork-01.name
    address_prefixes     = ["192.168.255.0/25"]
}

resource "azurerm_subnet" "terraform-subnet-01-02" {

    name                 = "private-subnet"
    resource_group_name  = azurerm_resource_group.terraform-resourcegroup-01.name
    virtual_network_name = azurerm_virtual_network.terraform-virtualnetwork-01.name
    address_prefixes     = ["192.168.255.128/25"]
}

resource "azurerm_network_interface" "terraform-networkinterface-01" {

    name                = "terraform-01-${random_id.terraform-randomid-01.hex}"
    resource_group_name = azurerm_resource_group.terraform-resourcegroup-01.name
    location            = azurerm_resource_group.terraform-resourcegroup-01.location

    ip_configuration {

        name                          = "internal"
        subnet_id                     = azurerm_subnet.terraform-subnet-01-02.id
        private_ip_address_allocation = "Dynamic"
    }

    tags = {

        CONTEXT = "TERRAFORM"
    }
}

resource "azurerm_linux_virtual_machine" "terraform-linuxvirtualmachine-01" {

    name                            = "terraform-01-${random_id.terraform-randomid-01.hex}"
    resource_group_name             = azurerm_resource_group.terraform-resourcegroup-01.name
    location                        = azurerm_resource_group.terraform-resourcegroup-01.location
    size                            = "Standard_B1ls"
    admin_username                  = var.linux-virtual-machine-01-admin-username
    admin_password                  = var.linux-virtual-machine-01-admin-password
    disable_password_authentication = false
    custom_data                     = base64encode(data.template_file.template-file-01.rendered)
    
    identity {
        type = "SystemAssigned"
    }

    network_interface_ids = [
        azurerm_network_interface.terraform-networkinterface-01.id
    ]

    os_disk {

        name                 = "terraform-01-${random_id.terraform-randomid-01.hex}-OSDisk"
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {

        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    tags = {

        CONTEXT = "TERRAFORM"
    }
}

resource "azurerm_public_ip" "terraform-publicip-01" {

    name                = "terraform-01-${random_id.terraform-randomid-01.hex}"
    resource_group_name = azurerm_resource_group.terraform-resourcegroup-01.name
    location            = azurerm_resource_group.terraform-resourcegroup-01.location
    allocation_method   = "Static"
    sku                 = "Standard"

    tags = {

        CONTEXT = "TERRAFORM"
    }
}

resource "azurerm_bastion_host" "terraform-bastionhost-01" {

    name                = "terraform-01-${random_id.terraform-randomid-01.hex}"
    resource_group_name = azurerm_resource_group.terraform-resourcegroup-01.name
    location            = azurerm_resource_group.terraform-resourcegroup-01.location

    ip_configuration {

        name                 = "default"
        subnet_id            = azurerm_subnet.terraform-subnet-01-01.id
        public_ip_address_id = azurerm_public_ip.terraform-publicip-01.id
    }

    tags = {

        CONTEXT = "TERRAFORM"
    }
}

resource "azurerm_storage_account" "terraform-storageaccount-01" {

    name                     = "xlterraform01${random_id.terraform-randomid-01.hex}"
    resource_group_name      = azurerm_resource_group.terraform-resourcegroup-01.name
    location                 = azurerm_resource_group.terraform-resourcegroup-01.location
    account_tier             = "Standard"
    account_replication_type = "GRS"

    tags = {

        CONTEXT = "TERRAFORM"
    }
}