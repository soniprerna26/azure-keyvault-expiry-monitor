# Architecture and Design

## Goal

Detect Azure Key Vault secrets and certificates that are close to expiry and notify the owner by email, so that rotation happens before an outage.

## Components

| Component | Role |
|---|---|
| `Check-KeyVaultExpiry.ps1` | Orchestrates scanning, threshold evaluation and alerting |
| `Az.Accounts` | Authentication (`Connect-AzAccount`) |
| `Az.KeyVault` | `Get-AzKeyVaultSecret`, `Get-AzKeyVaultCertificate` |
| SMTP server | Delivers the alert (Gmail in the test setup) |

## Data flow

1. **Authenticate.** The operator or job signs in to Azure and selects the subscription.
2. **List.** `Get-AzKeyVaultSecret -VaultName` returns summary objects for all secrets.
3. **Detail.** For each secret, a second call with `-Name` returns the full attribute set, including `Expires`.
4. **Evaluate.** `daysLeft = (Expires - Get-Date).Days`. If `daysLeft <= ThresholdDays`, the item is flagged.
5. **Notify.** A console warning is written and `Send-MailMessage` sends an email over STARTTLS.
6. **Repeat** for certificates.

## Design decisions

| Decision | Reason |
|---|---|
| Parameters instead of hard-coded values | Same script works for any vault, threshold and mailbox |
| Password via `Get-Credential` | Avoids committing credentials to source control |
| `-NoEmail` dry-run switch | Safe testing and demonstration without a mail account |
| Skip items with no `Expires` value | A missing expiry is valid in Key Vault and must not crash the run |
| Report already-expired items | Negative day counts are still actionable and should alert |
| Two-step fetch (list, then get) | The list call returns summary data; the detail call is the reliable way to read attributes |
| Read-only operation | The script never changes or deletes vault content |

## Edge cases handled

* Secret with no expiry date: skipped.
* Certificate with no expiry date: skipped (the first prototype did not guard this).
* Item already expired: reported as `EXPIRED n days ago`.
* Empty vault: loops simply do not execute.

## Day-count behaviour

`.Days` on a `TimeSpan` truncates toward zero, so an item expiring in 2 days and 20 hours reports **2 days**. This is the source of the "29 days" reading in the test results for a certificate that was set to roughly 30 days.
