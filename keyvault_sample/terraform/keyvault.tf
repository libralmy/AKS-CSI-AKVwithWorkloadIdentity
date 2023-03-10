resource "azurerm_key_vault" "main" {
  name                = var.keyvault_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"

  # access policy for creator
  access_policy {
    object_id = data.azurerm_client_config.current.object_id
    tenant_id = data.azurerm_client_config.current.tenant_id

    certificate_permissions = [
      "Get",
      "List",
      "Create",
      "Delete",
      "Import"
    ]

    key_permissions = [
      "Get",
      "List",
      "Create",
      "Delete",
      "Import"
    ]

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge"
    ]
  }

  # access policy for azure function
  access_policy {
    object_id = azurerm_user_assigned_identity.keyvault_client.principal_id
    tenant_id = azurerm_user_assigned_identity.keyvault_client.tenant_id
    
    certificate_permissions = [
      "Get",
      "List",
      "Create",
      "Delete",
      "Import"
    ]

    key_permissions = [
      "Get",
      "List",
      "Create",
      "Delete",
      "Import"
    ]

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge"
    ]
  }
  tags = {}
}

resource "azurerm_key_vault_secret" "main" {
  name         = local.secret_name
  value        = local.secret_value
  key_vault_id = azurerm_key_vault.main.id
}
###import cert ###
resource "azurerm_key_vault_certificate" "example" {
  name         = local.cert_name
  key_vault_id = azurerm_key_vault.main.id

  certificate {
    contents = filebase64("../keyvault_sample/Cert/emilycerta.pfx")
    password = ""
  }
}