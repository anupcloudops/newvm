#creating RG
resource "azurerm_resource_group" "arg"{
    name = "azrg"
    location = "west europe"
}
#Creating storage
resource "azurerm_storage_account" "astorage"{
    name= "anup8888"
    location = azurerm_resource_group.arg.location
    resource_group_name = azurerm_resource_group.arg.name
    account_tier = "Standard"
    account_replication_type = "GRS"
}
#Creating Vnet
resource "azurerm_virtual_network" "avnet"{
    name="azvnet"
    location = azurerm_resource_group.arg.location
    resource_group_name = azurerm_resource_group.arg.name
    address_space = ["10.0.0.0/16"]
}

#Creating Subnet

resource "azurerm_subnet" "asub"{
    name = "azsub"
    resource_group_name = azurerm_resource_group.arg.name
    virtual_network_name = azurerm_virtual_network.avnet.name
    address_prefixes = ["10.0.1.0/24"]
}
#Creating Public IP
resource "azurerm_public_ip" "apip"{
    name = "azpip"
    location = azurerm_resource_group.arg.location
    resource_group_name = azurerm_resource_group.arg.name
    allocation_method = "Static"
    sku = "Standard"
}
#Creating Network Security Group
resource "azurerm_network_security_group" "nsg"{
    name = "aznsg"
    location = azurerm_resource_group.arg.location
    resource_group_name = azurerm_resource_group.arg.name
      security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"  
    destination_address_prefix = "*"
}
}
#creating network_interface
resource "azurerm_network_interface" "ani"{
    name="azni"
    location = azurerm_resource_group.arg.location
    resource_group_name = azurerm_resource_group.arg.name
    ip_configuration{
        name = "internal"
        subnet_id =data.azurerm_subnet.dsub.id
        private_ip_address_allocation = "Dynamic"  
        public_ip_address_id = data.azurerm_public_ip.dpip.id
    }
}
data "azurerm_public_ip" "dpip" {
  name                = azurerm_public_ip.apip.name
  resource_group_name = azurerm_resource_group.arg.name
}

data "azurerm_subnet" "dsub" {
  name                 = azurerm_subnet.asub.name
  virtual_network_name = azurerm_virtual_network.avnet.name
  resource_group_name  = azurerm_resource_group.arg.name
}

#Network interface & nsg association
resource "azurerm_network_interface_security_group_association" "ani_nsg"{
    network_interface_id = data.azurerm_network_interface.dni.id
    network_security_group_id = data.azurerm_network_security_group.dsg.id
}

    data "azurerm_network_interface" "dni" {
  name                = azurerm_network_interface.ani.name
  resource_group_name = azurerm_resource_group.arg.name
}


data "azurerm_network_security_group" "dsg" {
  name                = azurerm_network_security_group.nsg.name
  resource_group_name = azurerm_resource_group.arg.name
}

resource "azurerm_linux_virtual_machine" "avm" {
  name                = "azvm"
  resource_group_name = azurerm_resource_group.arg.name
  location            = azurerm_resource_group.arg.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  admin_password      = "1Admin_pass@word"
  network_interface_ids = [
    azurerm_network_interface.ani.id,]  # direct resource ref
  
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
# After apply — get the public IP:
output "apip" {
  value = azurerm_public_ip.apip.ip_address
}

#NSG association — always attach NSG to the NIC (not the subnet) when you want VM-level control.