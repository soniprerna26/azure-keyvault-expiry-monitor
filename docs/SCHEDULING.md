# Scheduling the Monitor

The script is interactive by default (it prompts for the SMTP password). For scheduled use, supply credentials non-interactively. Pick one approach.

## Option A: Windows Task Scheduler (simple)

1. Run `Connect-AzAccount` once and enable context persistence if you want the login to survive sessions:
   ```powershell
   Enable-AzContextAutosave
   ```
2. Create the task:
   ```powershell
   $action  = New-ScheduledTaskAction -Execute "powershell.exe" `
       -Argument '-NoProfile -ExecutionPolicy Bypass -File "C:\path\src\Check-KeyVaultExpiry.ps1" -VaultName "your-kv" -NoEmail'
   $trigger = New-ScheduledTaskTrigger -Daily -At 8am
   Register-ScheduledTask -TaskName "KeyVaultExpiryCheck" -Action $action -Trigger $trigger
   ```
3. To send email unattended, modify the script to load a credential from a secure store instead of calling `Get-Credential`.

## Option B: Azure Automation runbook (recommended for production)

1. Create an Automation Account with a **system-assigned managed identity**.
2. Grant that identity read/list access on the vault.
3. Import `Az.Accounts` and `Az.KeyVault` modules into the account.
4. In the runbook, authenticate with `Connect-AzAccount -Identity`.
5. Store the SMTP credential as an Automation **Credential asset** and read it with `Get-AutomationPSCredential`.
6. Attach a daily schedule.

## Option C: GitHub Actions with OIDC

```yaml
name: keyvault-expiry-check
on:
  schedule:
    - cron: "30 2 * * *"   # 08:00 IST
  workflow_dispatch:
permissions:
  id-token: write
  contents: read
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      - uses: azure/powershell@v2
        with:
          azPSVersion: latest
          inlineScript: ./src/Check-KeyVaultExpiry.ps1 -VaultName "${{ vars.VAULT_NAME }}" -NoEmail
```

This workflow is a template. It requires an Entra ID app registration with a federated credential, which you must set up yourself.
