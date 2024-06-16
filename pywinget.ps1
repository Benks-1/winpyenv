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
