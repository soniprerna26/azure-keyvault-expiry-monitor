# Changelog

All notable changes to this project are documented here.

## [1.1.0] - 2026-10-27

### Added
- Script parameters: `-VaultName`, `-ThresholdDays`, `-FromEmail`, `-ToEmail`, `-SmtpServer`, `-SmtpPort`
- `-NoEmail` dry-run switch
- Comment-based help (`Get-Help .\src\Check-KeyVaultExpiry.ps1 -Full`)
- Reporting of already-expired items
- Test-data helper script, Pester tests and full documentation set

### Fixed
- Certificate loop failed to guard against items with no expiry date (the secret loop already did)

### Changed
- Script renamed from `checkvault.ps1` to `src/Check-KeyVaultExpiry.ps1`
- Hard-coded vault name and email addresses removed

## [1.0.0] - Initial version

- Scan secrets and certificates in a single hard-coded Key Vault
- 30-day threshold, console warning and SMTP email alert
- SMTP password requested at runtime via `Get-Credential`
- Validated on a test vault: secret expiring in 2 days and certificate expiring in 29 days detected
