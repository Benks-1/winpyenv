param (
    [Parameter()]
    [ValidateSet('help', 'list-installed', 'list-available', 'install', 'remove')]
    [string]$command = 'help',
    
    [Parameter()]
    [string]$Version,

    [Parameter()]
    [ValidateSet('user', 'machine')]
    [string]$Scope = 'user'
)

function Get-AvailablePythonVersions {
    Write-Output "Fetching available Python versions..."
    $main = winget search --id Python.Python --source winget
    $main | ForEach-Object { $_.Split()[1] } | 
    Where-Object {$_ -ne '' -and $_ -ne '2'} | 
    ForEach-Object {winget search --id Python.Python --source winget --versions $_} | 
    Where-Object { $_ -match '^\d+\.\d+\.\d+' } |  
    Select-Object -Unique |
    ForEach-Object {
        [PSCustomObject]@{
            Version = $_
        }
    }
}

function Install-Python {
    param (
        [string]$Version,
        [ValidateSet('user', 'machine')]
        [string]$Scope = 'user'
    )
    $versionParts = $Version -split '\.'
    if ($versionParts.Length -gt 3 -or $versionParts.Length -lt 2) {
        Write-Host "Error: This '$Version' is not valid python version." -ForegroundColor Red
        exit 1
    }

    $scopeParam = if ($Scope -eq 'machine') { 'machine' } else { 'user' }

    if ($versionParts.Length -eq 3) {
        $versionMajor = "$($versionParts[0]).$($versionParts[1])"
        if ($scopeParam -eq 'machine') {
            Write-Output "Installing Python version $Version with scope $Scope..."
            Start-Process powershell -ArgumentList "winget install -e --id Python.Python.$versionMajor --version $Version --scope $scopeParam" -Verb RunAs
        } else {
            Write-Output "Installing Python version $Version with scope $Scope..."
            winget install -e --id Python.Python.$versionMajor --version $Version --scope $scopeParam
        }
    } else {
        if ($scopeParam -eq 'machine') {
            Write-Output "Installing Python version $Version with scope $Scope..."
            Start-Process powershell -ArgumentList "winget install -e --id Python.Python.$Version --scope $scopeParam" -Verb RunAs
        } else {
            Write-Output "Installing Python version $Version with scope $Scope..."
            winget install -e --id Python.Python.$Version --scope $scopeParam
        }
    }
}

function Remove-Python {
    param (
        [string]$Version
    )

    $versionParts = $Version -split '\.'
    if ($versionParts.Length -gt 3 -or $versionParts.Length -lt 2) {
        Write-Host "Error: This '$Version' is not valid python version." -ForegroundColor Red
        exit 1
    }
    $versionMajor = "$($versionParts[0]).$($versionParts[1])"
    Write-Output "Try to uninstall Python version $Version..."
    winget uninstall --id Python.Python.$versionMajor
}

function Get-InstalledPythonVersions {
    Write-Output "Fetching installed Python versions..."
    winget list --id Python.Python | Select-String -Pattern "Python.Python" | ForEach-Object {
        $line = $_.Line
        $columns = $line -split "\s{2,}"
        [PSCustomObject]@{
            Id      = $columns[0]
            Name    = $columns[1]
            Version = $columns[2]
            Scope   = $columns[3]
        }
    }
}

function Show-Help {
    Write-Host @"
Usage: pywinget <command>

Commands:
  list-available                 Provides a list of python versions that are available for download via winget.
  install                        Runs the instalation process of python (It will ask for version and scope).
  remove                         Removes a specific python instalation.
  list-installed                 Provides a list of all available python installations on the machine
  help                           Show this help message.

Examples:
  pywinget list-available
  pywinget install
  pywinget remove
  pywinget list-installed
  pywinget help
"@
}
 
# Main script logic
switch ($command) {
    "list-available" {
        Get-AvailablePythonVersions | Format-Table -AutoSize
    }
    "install" {
        if ($Version -eq ''){
            $version = Read-Host "Enter the Python version to install"
        } else {
            $version = $Version
        }
        if ($Scope -eq ''){
            $scope = Read-Host "Enter the scope (user/machine)"
        } else {
            $scope = $Scope
        }


        Install-Python -Version $version -Scope $scope
    }
    "remove" {
        if ($Version -eq ''){
            $version = Read-Host "Enter the Python version to remove"
        } else {
            $version = $Version
        }

        Remove-Python -Version $version
    }
    "list-installed" {
        Get-InstalledPythonVersions | Format-Table -AutoSize
    }
    "help" { Show-Help }
    default { Show-Help }
}

# SIG # Begin signature block
# MIIFfQYJKoZIhvcNAQcCoIIFbjCCBWoCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAEFgDVB+Byu8Zc
# x4NnIyp0+is8ouucvD8TvbHHtkjhlKCCAvowggL2MIIB3qADAgECAhBq335jqvIp
# rUBhfa+DF71MMA0GCSqGSIb3DQEBBQUAMBMxETAPBgNVBAMMCHB5d2luZ2V0MB4X
# DTI0MDYyNDA3MTAwNVoXDTI1MDYyNDA3MzAwNVowEzERMA8GA1UEAwwIcHl3aW5n
# ZXQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCUrry5+VgXDCvLGC8X
# Fc7OQiwN5iyK+p0sj+GC+ZqnI1nSWiiH4NWGoQzcPDvBQMPCOhXkxgH3/JGVo5eS
# L67gA63kwc4Z9fcMcmi6/kvL/FibqN5ExTVSvS+8pYQ9qDKnQt1xL5CjnDVJOjM/
# P/yx+zwgXq5J/sSz2M5P3GYZg6Bpa7KMBLc34/q0uBFfCTglXLXHyz1hucFyslKw
# IU9bDShd1XPhJVBe14n9LBvP0gE9Fb73oFFNsaIZ8+3MjM95QirWxQXV1jQ3aeiv
# s/F85bih6nKxxBinYoUknQN49RdhJnfR8Dtba8bl+DhY8DhQLlR+mRXhjl6N0X0S
# o9HNAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcD
# AzAdBgNVHQ4EFgQU7T2Dt7NmAqZyD4piAKh3rYXIxAQwDQYJKoZIhvcNAQEFBQAD
# ggEBAGEdsQxFUpHmGw2i2eoljI7XjJFVWKihHIUU/jhB9UMqvlXf0lpI6bix5R69
# PGYPRhGGQD1bHrJHvTCi/jPS+P9ODFJFjiOvMWpFH0/CbioYQO89DACbsiVm1UAX
# 0p6ApH2oZO3nVLQfubM+5lbukw+87mT/Dy481QRtLBNZwZxDqrd5CORLontpqKtk
# /9Rq0g2JzhKPn3Fd5di9XtUxapyMXuQVvLkt5VxOqexseL61Y78IeW2OgEytI3dp
# 8Equ+7nKd72ND3lJyJtXalkv4Ubb5TgqR3a4r2BSa/zhUDCorw6iyNusMAQ3027D
# BzwfkQtDtJ9++xRyjGd8tqV08SExggHZMIIB1QIBATAnMBMxETAPBgNVBAMMCHB5
# d2luZ2V0AhBq335jqvIprUBhfa+DF71MMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisG
# AQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICfu
# VbV6KEjAo4L0ddLUGPzdcuthQOKTQO0Tl1WFXcWgMA0GCSqGSIb3DQEBAQUABIIB
# AIF5jsPC3p0mXdnk4vEtFkrddM8wLutBmfob1EEWZMfaAi9ZNL3x6naCjax37jRz
# amOY2Ap3RLrLt7f8w8TLzrnDU3NPxZkeQvFJSSXth953/05s0/iGyg5sKr9G2urX
# pvZr8ha/VgW8T9XKHQRtgeflswv7fieVFux+kQ/qzrq6xeWTOjx5/QjoFkwPq5Ez
# 3i8AnXti31Kpv3sHAMU0xp75dVtKJYU+at8ZTJrhOvWE7xxmun6YTrMeVDTLSp6M
# 0YPV5DP6j+UbNJpaZYJFeCCB5mPdFCMoRpxu3E+ZQXqGRwkUfiMYKM4AefKullxI
# o32zc2CKMwsuTPgmOYABv+4=
# SIG # End signature block
