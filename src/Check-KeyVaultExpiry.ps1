<#
.SYNOPSIS
    Scans an Azure Key Vault for secrets and certificates that are close to expiry
    and sends an SMTP email alert for each one.

.DESCRIPTION
    - Enumerates all secrets and certificates in the given Key Vault (Az.KeyVault module).
    - Calculates the days remaining until expiry for each item.
    - Flags anything at or below -ThresholdDays (default: 30), including items already expired.
    - Sends an alert email over SMTP (STARTTLS, credential-based auth).
    - The SMTP password is never stored in the script; it is requested at runtime
      through Get-Credential.

.PARAMETER VaultName
    Name of the Azure Key Vault to scan.

.PARAMETER ThresholdDays
    Alert when days remaining <= this value. Default: 30.

.PARAMETER FromEmail
    Sender address (also used as the SMTP username).

.PARAMETER ToEmail
    Recipient of the alert emails.

.PARAMETER SmtpServer
    SMTP server host name. Default: smtp.gmail.com.

.PARAMETER SmtpPort
    SMTP port. Default: 587 (STARTTLS).

.PARAMETER NoEmail
    Dry-run mode: print warnings to the console only, send nothing,
    and do not prompt for credentials.

.EXAMPLE
    .\Check-KeyVaultExpiry.ps1 -VaultName "my-kv" -FromEmail "me@example.com" -ToEmail "team@example.com"

.EXAMPLE
    .\Check-KeyVaultExpiry.ps1 -VaultName "my-kv" -ThresholdDays 60 -NoEmail

.NOTES
    Prerequisites : PowerShell 5.1+ or 7+, Az.Accounts and Az.KeyVault modules,
                    an active session (Connect-AzAccount) with "get" and "list"
                    permissions on secrets and certificates for the vault.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$VaultName,

    [int]$ThresholdDays = 30,

    [string]$FromEmail,
    [string]$ToEmail,

    [string]$SmtpServer = "smtp.gmail.com",
    [int]$SmtpPort = 587,

    [switch]$NoEmail
)

# --- Validate email parameters unless running as a dry run -------------------
if (-not $NoEmail) {
    if (-not $FromEmail -or -not $ToEmail) {
        throw "FromEmail and ToEmail are required unless -NoEmail is used."
    }
    # Password is NOT stored in this file - it is requested when the script runs.
    $credential = Get-Credential -UserName $FromEmail -Message "Enter your SMTP / Gmail app password"
}

function Send-AlertEmail {
    param(
        [string]$Subject,
        [string]$Body
    )
    if ($NoEmail) { return }
    Send-MailMessage -From $FromEmail -To $ToEmail -Subject $Subject -Body $Body `
        -SmtpServer $SmtpServer -Port $SmtpPort -UseSsl -Credential $credential
}

function Get-ExpiryMessage {
    param(
        [string]$Type,
        [string]$Name,
        [int]$DaysLeft
    )
    if ($DaysLeft -lt 0) {
        return "$Type '$Name' EXPIRED $([math]::Abs($DaysLeft)) days ago!"
    }
    return "$Type '$Name' expires in $DaysLeft days!"
}

# --- Secrets -----------------------------------------------------------------
Write-Host "Checking secrets in $VaultName..."
$secrets = Get-AzKeyVaultSecret -VaultName $VaultName
foreach ($s in $secrets) {
    $details = Get-AzKeyVaultSecret -VaultName $VaultName -Name $s.Name

    # Secrets without an expiry date are skipped (nothing to compare against).
    if ($details.Expires) {
        $daysLeft = ($details.Expires - (Get-Date)).Days
        if ($daysLeft -le $ThresholdDays) {
            $msg = Get-ExpiryMessage -Type "Secret" -Name $s.Name -DaysLeft $daysLeft
            Write-Warning $msg
            Send-AlertEmail -Subject "Key Vault Alert: Secret Expiring" -Body $msg
        }
    }
}

# --- Certificates ------------------------------------------------------------
Write-Host "Checking certificates in $VaultName..."
$certs = Get-AzKeyVaultCertificate -VaultName $VaultName
foreach ($c in $certs) {
    $details = Get-AzKeyVaultCertificate -VaultName $VaultName -Name $c.Name

    if ($details.Expires) {
        $daysLeft = ($details.Expires - (Get-Date)).Days
        if ($daysLeft -le $ThresholdDays) {
            $msg = Get-ExpiryMessage -Type "Certificate" -Name $c.Name -DaysLeft $daysLeft
            Write-Warning $msg
            Send-AlertEmail -Subject "Key Vault Alert: Certificate Expiring" -Body $msg
        }
    }
}
