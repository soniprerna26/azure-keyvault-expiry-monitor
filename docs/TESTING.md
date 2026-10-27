# Test Plan and Results

## Environment

| Item | Value |
|---|---|
| Vault | `prerna-project-test-kv` (test) |
| Subscription / tenant | Azure subscription 1 / Default Directory |
| Shell | Windows PowerShell (Windows Terminal) |
| Threshold | 30 days |

## Executed test (evidence in `docs/images/output.png`)

| ID | Scenario | Setup | Expected | Actual | Result |
|---|---|---|---|---|---|
| T1 | Secret inside threshold | `test-secret-1`, about 2 days to expiry | Warning: expires in 2 days | `Secret 'test-secret-1' expires in 2 days!` | Pass |
| T2 | Certificate inside threshold | `test-certificate-1`, about 29 days to expiry | Warning: expires in 29 days | `Certificate 'test-certificate-1' expires in 29 days!` | Pass |
| T3 | Repeat runs are consistent | Script run several times in a row | Same output each run | Identical output on each run | Pass |

## Recommended additional tests

These are included for anyone extending the project. Mark each as executed only after you have run it yourself.

| ID | Scenario | How to test | Expected |
|---|---|---|---|
| T4 | Item outside threshold | Create a secret expiring in 90 days | No warning |
| T5 | Boundary: exactly 30 days | Secret with 30 days and a few hours remaining | Warning (30 is less than or equal to 30) |
| T6 | Item with no expiry | Create a secret without `-Expire` | Silently skipped, no error |
| T7 | Already expired item | Secret with an expiry in the past | `EXPIRED n days ago` |
| T8 | Dry run | Run with `-NoEmail` | Warnings only, no credential prompt |
| T9 | Email delivery | Run with `-FromEmail` and `-ToEmail` | Email arrives with subject `Key Vault Alert: ...` |
| T10 | Wrong password | Enter an invalid app password | SMTP authentication error, script reports it |
| T11 | Insufficient permissions | Run as an identity without list rights | Forbidden error from Azure |

## Unit tests

`tests/Check-KeyVaultExpiry.Tests.ps1` contains Pester tests for the message formatting and the threshold arithmetic.

```powershell
Install-Module Pester -Scope CurrentUser -Force
Invoke-Pester -Path .\tests
```

## Why "29 days" and not "30"

The certificate test item was created with roughly a one-month lifetime. `TimeSpan.Days` truncates fractional days, so 29 days and 23 hours is displayed as 29. The value is correct and below the 30-day threshold.
