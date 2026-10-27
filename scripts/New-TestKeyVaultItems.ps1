<#
.SYNOPSIS
    Creates a test secret and a test certificate in an Azure Key Vault so the
    expiry monitor can be validated end to end.

.DESCRIPTION
    - Creates 'test-secret-1' expiring in -SecretDays days (default 2).
    - Creates 'test-certificate-1' (self-signed) with a lifetime of -CertDays days
      (default 29).
    Use ONLY against a non-production test vault.

.PARAMETER VaultName
    Name of the test Key Vault.

.EXAMPLE
    .\New-TestKeyVaultItems.ps1 -VaultName "my-test-kv"

.NOTES
    Requires the caller to have Set permission on secrets and Create permission on
    certificates in the vault. The Key Vault certificate validity is expressed in
    months, so -CertDays is converted and the resulting expiry is approximate.
    If you need an exact 29-day expiry, import a pre-made certificate instead
    (see docs/TESTING.md).
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$VaultName,

    [int]$SecretDays = 2
)

# --- Secret with an explicit expiry date ------------------------------------
$secretValue = ConvertTo-SecureString -String ([guid]::NewGuid().ToString()) -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $VaultName -Name "test-secret-1" `
    -SecretValue $secretValue `
    -Expire (Get-Date).AddDays($SecretDays).ToUniversalTime() | Out-Null
Write-Host "Created secret 'test-secret-1' expiring in about $SecretDays days."

# --- Self-signed certificate -------------------------------------------------
# Key Vault certificate policies express validity in whole months, so a short
# lifetime is achieved by setting ValidityInMonths to 1 (about 30 days).
$policy = New-AzKeyVaultCertificatePolicy `
    -SecretContentType "application/x-pkcs12" `
    -SubjectName "CN=test-certificate-1.local" `
    -IssuerName "Self" `
    -ValidityInMonths 1 `
    -ReuseKeyOnRenewal

Add-AzKeyVaultCertificate -VaultName $VaultName -Name "test-certificate-1" `
    -CertificatePolicy $policy | Out-Null
Write-Host "Requested certificate 'test-certificate-1' (about 1 month validity)."
Write-Host "Wait a few seconds for issuance, then run the monitor script."
