data "azurerm_client_config" "current" {
}

# Fetch Existing Resource Group
data "azurerm_resource_group" "existing_rg" {
  name = var.resource_group_name
}

resource "azurerm_key_vault" "kv" {
  name                        = lower("kv-${var.key_vault_name}")
  location                    = data.azurerm_resource_group.existing_rg.location
  resource_group_name         = data.azurerm_resource_group.existing_rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = var.sku_name
  enabled_for_deployment      = var.enabled_for_deployment
  enabled_for_disk_encryption = var.enabled_for_disk_encryption
  enable_rbac_authorization   = var.enable_rbac_authorization
  purge_protection_enabled    = var.purge_protection_enabled
  tags                        = var.tags

  dynamic "access_policy" {
    for_each = var.enable_rbac_authorization ? [] : var.access_policies
    content {
      tenant_id               = data.azurerm_client_config.current.tenant_id
      object_id               = data.azurerm_client_config.current.object_id
      key_permissions         = access_policy.value.key_permissions
      secret_permissions      = access_policy.value.secret_permissions
      certificate_permissions = access_policy.value.certificate_permissions
    }
  }
}

resource "azurerm_key_vault_key" "hsm_key" {
  name         = var.hsm_key_name
  key_vault_id = azurerm_key_vault.kv.id
  key_type     = var.key_type
  key_size     = var.key_size

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }

    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }
  depends_on = [azurerm_key_vault.kv]
}

# Key Vault Secrets
resource "azurerm_key_vault_secret" "secrets" {
  for_each     = var.key_vault_secrets
  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_key_vault_key.hsm_key]
}
