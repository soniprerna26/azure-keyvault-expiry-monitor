#Requires -Modules Pester
<#
    Pester tests for the expiry calculation logic.
    These tests do not call Azure; they validate the day-count and threshold
    behaviour that Check-KeyVaultExpiry.ps1 relies on.

    Run:  Invoke-Pester -Path .\tests
#>

BeforeAll {
    # Mirrors the helper in src/Check-KeyVaultExpiry.ps1
    function Get-ExpiryMessage {
        param([string]$Type, [string]$Name, [int]$DaysLeft)
        if ($DaysLeft -lt 0) {
            return "$Type '$Name' EXPIRED $([math]::Abs($DaysLeft)) days ago!"
        }
        return "$Type '$Name' expires in $DaysLeft days!"
    }

    function Get-DaysLeft {
        param([datetime]$Expires)
        return ($Expires - (Get-Date)).Days
    }
}

Describe "Get-ExpiryMessage" {
    It "formats a future expiry" {
        Get-ExpiryMessage -Type "Secret" -Name "test-secret-1" -DaysLeft 2 |
            Should -Be "Secret 'test-secret-1' expires in 2 days!"
    }

    It "formats an already expired item" {
        Get-ExpiryMessage -Type "Certificate" -Name "old-cert" -DaysLeft -5 |
            Should -Be "Certificate 'old-cert' EXPIRED 5 days ago!"
    }
}

Describe "Threshold logic (30 days)" {
    It "flags an item expiring in 2 days" {
        (Get-DaysLeft -Expires (Get-Date).AddDays(2).AddHours(1)) | Should -BeLessOrEqual 30
    }

    It "flags an item expiring in 29 days" {
        (Get-DaysLeft -Expires (Get-Date).AddDays(29).AddHours(1)) | Should -BeLessOrEqual 30
    }

    It "does not flag an item expiring in 90 days" {
        (Get-DaysLeft -Expires (Get-Date).AddDays(90).AddHours(1)) | Should -BeGreaterThan 30
    }

    It "flags an item that has already expired" {
        (Get-DaysLeft -Expires (Get-Date).AddDays(-3)) | Should -BeLessOrEqual 30
    }
}
