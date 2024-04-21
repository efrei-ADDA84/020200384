provider "azurerm" {
  features {}
  skip_provider_registration = true
  subscription_id = "765266c6-9a23-4638-af32-dd1e32613047"
}

resource "azurerm_public_ip" "public_ip" {
  name                = "public-ip"
  location            = "france central"
  resource_group_name = "ADDA84-CTP"
  allocation_method   = "Static"
}

data "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = "ADDA84-CTP"
  virtual_network_name = "network-tp4"
}

resource "azurerm_network_interface" "network_interface" {
  name                = "network_interface-nic"
  location            = "france central"
  resource_group_name = "ADDA84-CTP"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA" 
  rsa_bits  = 4096
}

resource "local_file" "public_key" {
  content  = tls_private_key.ssh.public_key_openssh
  filename = "${path.module}/id_rsa.pub"
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/id_rsa"
  file_permission = "0600"
}

resource "azurerm_linux_virtual_machine" "virtual_machine" {
  name                = "devops-${var.efrei_identifier}"
  resource_group_name = "ADDA84-CTP"
  location            = "france central"
  size                = "Standard_D2s_v3"

  admin_username = "devops"
  disable_password_authentication = true

  network_interface_ids = [azurerm_network_interface.network_interface.id]

  admin_ssh_key {
    username   = "devops"
    public_key = tls_private_key.ssh.public_key_openssh
  }

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

variable "efrei_identifier" {
  default = "20200384"
}