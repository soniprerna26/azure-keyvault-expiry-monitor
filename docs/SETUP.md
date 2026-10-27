# Setup Guide

## 1. Create a test Key Vault (Azure CLI)

```bash
az login
az group create --name rg-kv-monitor-test --location centralindia
az keyvault create --name <unique-vault-name> --resource-group rg-kv-monitor-test --location centralindia
```

Vault names are globally unique, 3 to 24 characters, letters, digits and hyphens.

## 2. Grant yourself access

If the vault uses Azure RBAC, assign these roles at the vault scope:

* **Key Vault Secrets Officer** (to create the test secret)
* **Key Vault Certificates Officer** (to create the test certificate)

For the monitor itself, **Key Vault Secrets User** and **Key Vault Certificates Officer/Reader-equivalent list permission** are enough. Verify the exact roles in your tenant, because role names and data actions can differ by configuration.

## 3. Install modules

```powershell
Install-Module Az.Accounts, Az.KeyVault -Scope CurrentUser
Import-Module Az.KeyVault
```

## 4. Sign in

```powershell
Connect-AzAccount
Get-AzSubscription        # confirm the right subscription is selected
```

## 5. Create test items

```powershell
.\scripts\New-TestKeyVaultItems.ps1 -VaultName "<unique-vault-name>"
```

## 6. Prepare Gmail SMTP (optional)

1. Enable 2-Step Verification on the Google account.
2. Create an **App Password** in the Google account security settings.
3. Use that 16-character app password when `Get-Credential` prompts. Never use the account password.

## 7. Run

```powershell
.\src\Check-KeyVaultExpiry.ps1 -VaultName "<unique-vault-name>" -NoEmail
```

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `Get-AzKeyVaultSecret` returns Forbidden | Missing get/list permission | Grant the permissions or RBAC role |
| Command not found | Az modules not installed or not imported | Re-run step 3 |
| SMTP authentication error | Using the normal Gmail password | Use an App Password |
| Timeout on port 587 | Firewall blocks outbound SMTP | Allow 587 or use another mail route |
| No warnings appear | No item is within the threshold, or items have no expiry date | Check `Expires` values and the threshold |
