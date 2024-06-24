param (
    [Parameter(Position=0)]
    [ValidateSet("activate", "create", "list", "delete", "pip", "shell", "help")]
    [string]$command,

    [Parameter()]
    [string]$EnvName,

    [Parameter()]
    [string]$Version,

    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Parameters
)

$envsPath = $env:PY_ENVS_PATH

if (-not $envsPath) {
    Write-Host "Error: PY_ENVS_PATH environment variable is not set." -ForegroundColor Red
    exit 1
}

# Ensure the virtual environments directory exists
if (-not (Test-Path -Path $envsPath)) {
    New-Item -Path $envsPath -ItemType Directory | Out-Null
}

function Show-Help {
    Write-Host @"
Usage: pyvenv <command> [EnvName ] [pyVersion]

Commands:
  activate <EnvName>             Activate the specified virtual environment.
  create <EnvName> [pyVersion]   Create a virtual environment with the specified Python version.
  list                           List all virtual environments.
  delete <EnvName>               Delete the specified virtual environment.
  help                           Show this help message.

Examples:
  pyvenv activate <name>
  pyvenv create <name> 3.8
  pyvenv list
  pyvenv delete <name>
"@
}

function Activate-Venv {
    param (
        [string]$EnvName 
    )

    $venvPath = Join-Path -Path $envsPath -ChildPath $EnvName 
    if (-not (Test-Path -Path $venvPath)) {
        Write-Host "Error: Virtual environment '$EnvName ' does not exist in '$envsPath'." -ForegroundColor Red
        exit 1
    }

    $pip = Join-Path -Path $venvPath -ChildPath "Scripts\Activate.ps1"
    
    if (-not (Test-Path -Path $pip)) {
        Write-Host "Error: Activate script not found in '$venvPath\Scripts'." -ForegroundColor Red
        exit 1
    }

    Write-Host "Activating virtual environment '$EnvName '..." -ForegroundColor Green
    . $pip
    Write-Host "Activated '$EnvName '."
}

function Invoke-Pip {
    param (
        [string]$EnvName,
        [string]$ArgsString
    )

    $Args = $ArgsString -split ' '
    
    $venvPath = Join-Path -Path $envsPath -ChildPath $EnvName 
    if (-not (Test-Path -Path $venvPath)) {
        Write-Host "Error: Virtual environment '$EnvName ' does not exist in '$envsPath'." -ForegroundColor Red
        exit 1
    }

    $pip = Join-Path -Path $venvPath -ChildPath "Scripts\pip.exe"
    
    if (-not (Test-Path -Path $pip)) {
        Write-Host "Error: Pip not found in '$venvPath\Scripts'." -ForegroundColor Red
        exit 1
    }

    & $pip @Args
}

function Start-PythonShell {
    param (
        [string]$EnvName
    )

    $venvPath = Join-Path -Path $envsPath -ChildPath $EnvName 
    if (-not (Test-Path -Path $venvPath)) {
        Write-Host "Error: Virtual environment '$EnvName' does not exist in '$envsPath'." -ForegroundColor Red
        return
    }

    $pythonExe = Join-Path -Path $venvPath -ChildPath "Scripts\python.exe"
    
    if (-not (Test-Path -Path $pythonExe)) {
        Write-Host "Error: Python executable not found in '$venvPath\Scripts'." -ForegroundColor Red
        return
    }

    & $pythonExe
}

function Create-Venv {
    param (
        [string]$EnvName ,
        [string]$Version
    )

    $venvPath = Join-Path -Path $envsPath -ChildPath $EnvName 

    if (Test-Path -Path $venvPath) {
        Write-Host "Error: Virtual environment '$EnvName ' already exists in '$envsPath'." -ForegroundColor Red
        exit 1
    }

    $pythonExe = ""
    $usedLauncher = ""

    if ($Version) {
        # Use py launcher if available
        if (Get-Command py -ErrorAction SilentlyContinue) {
            $pythonExe = Get-Command py
            $usedLauncher = "Python launcher (py) with version $Version"
        } else {
            # Look for specific python version in PATH
            $pythonExe = Get-Command "python$Version" -ErrorAction SilentlyContinue
            if ($pythonExe) {
                $usedLauncher = "Python executable (python$Version)"
            } else {
                Write-Host "Error: Python version '$Version' not found." -ForegroundColor Red
                exit 1
            }
        }
    } else {
        if (Get-Command py -ErrorAction SilentlyContinue){
            $pythonExe = Get-Command py
            $usedLauncher = "Python launcher (py) default version"
        } elseif (Get-Command python -ErrorAction SilentlyContinue){
            $pythonExe = Get-Command python
            $pythonVersiontext = "{0}.{1}" -f $pythonExe.Version.Major, $pythonExe.Version.Minor
            $usedLauncher = "Python executable (python$pythonVersiontext)"
        } else {
            Write-Host "Error: Python executable not found in PATH." -ForegroundColor Red
            exit 1
        }
    }

    Write-Host "Creating virtual environment '$EnvName ' with $usedLauncher..." -ForegroundColor Green
    if ($Version) {
        & $pythonExe -$Version -m venv $venvPath
    } else {
        & $pythonExe -m venv $venvPath
    }
    if (Test-Path -Path $venvPath) {
        Write-Host "Virtual environment '$EnvName ' created successfully using $usedLauncher." -ForegroundColor Green
    } else {
        Write-Host "Error: Virtual environment '$EnvName ' was not created in '$envsPath'." -ForegroundColor Red
        exit 1
    }
}

function List-Venvs {
    Write-Host "Listing all virtual environments in '$envsPath'..." -ForegroundColor Green
    Get-ChildItem -Path $envsPath -Directory | ForEach-Object {
        Write-Host $_.Name
    }
}

function Delete-Venv {
    param (
        [string]$EnvName 
    )
    $venvPath = Join-Path -Path $envsPath -ChildPath $EnvName 
    if (-not (Test-Path -Path $venvPath)) {
        Write-Host "Error: Virtual environment '$EnvName ' does not exist in '$envsPath'." -ForegroundColor Red
        exit 1
    }
    Write-Host "Deleting virtual environment '$EnvName '..." -ForegroundColor Green
    Remove-Item -Recurse -Force -Path $venvPath
    Write-Host "Virtual environment '$EnvName ' deleted successfully."
}

switch ($command) {
    "activate" { 
        if (-not $EnvName ) {
            Write-Host "Error: 'activate' action requires <EnvName>." -ForegroundColor Red
            Show-Help
            exit 1
        }
        Activate-Venv -EnvName $EnvName  
    }
    "create" { 
        if (-not $EnvName ) {
            Write-Host "Error: 'create' action requires <EnvName>." -ForegroundColor Red
            Show-Help
            exit 1
        }
        Create-Venv -EnvName $EnvName -Version $Version 
    }
    "list" { List-Venvs }
    "delete" { 
        if (-not $EnvName ) {
            Write-Host "Error: 'delete' action requires <EnvName>." -ForegroundColor Red
            Show-Help
            exit 1
        }
        Delete-Venv -EnvName $EnvName  
    }
    "pip" {
        Invoke-Pip -EnvName $EnvName -ArgsString ($Parameters -join ' ')
    }
    "shell"{
        Start-PythonShell -EnvName $EnvName
    }
    "help" { Show-Help }
    default { Show-Help }

}
# SIG # Begin signature block
# MIIFdwYJKoZIhvcNAQcCoIIFaDCCBWQCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCl08ToMHNIYSO4
# opWxdfvmWGZXQrYNHn7YyJ4A3MRhGKCCAvYwggLyMIIB2qADAgECAhAuvWaLwrIA
# tEXA50caD7cLMA0GCSqGSIb3DQEBBQUAMBExDzANBgNVBAMMBnB5dmVudjAeFw0y
# NDA2MjQwNzEwMDRaFw0yNTA2MjQwNzMwMDRaMBExDzANBgNVBAMMBnB5dmVudjCC
# ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOJ29/AUPfumYx6BPYG7NBho
# VQyKoV/zrWM+M7HHTqGGbec1jk/bcywtnb2ff3d7PHLNi3Q0e/NUcR86kSJgNGgE
# AxK6WAXYdhPt3k6UP32xm6LyLsgCX/NZoRCh9IomGgEU/nPgvT+x6Wk2oo83vi7f
# ec0S84BdpsMrfQJHVQUiHjolr477F3Ft57KeH8Py+HidomSWDlb8kwnm+jbEF74u
# ZavN1E8QHXyScJdOfbaZT3aJCL/pPI4nB8yrWEZ9ePyraDB8fOEFZNKWMndF97F3
# SOpneaPkkM67RpLuexzo1QaVFq/0A6B0fEau6CMh6KmDksOGji2hsoRNfnpr0eUC
# AwEAAaNGMEQwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMB0G
# A1UdDgQWBBRobrlzDvlT0peWrkHP/wB6XSw2lzANBgkqhkiG9w0BAQUFAAOCAQEA
# JfYDK/W6D0pDxE4H3RpifI6lDuXv7V1CoDVjYmW0Z0SsO8ZQpI74MbUJahLaz9dl
# WHmbZc086mNxezWomK5YKocbsm5YIsFJXVAOw+4AwAus+mbcA3BK/uQ3vZ664MCX
# eKVq2z/piZRanv/iHYF+h7NovG6AaVfW/nyeHiZ6jZqtJ3ENzxPCfVL/YIpZ7ELL
# aFu4OqKXwcB3e5X0ODx1eSJXgqGf1BIwV8PtYycmFTXhbY/Bv9MCQICEqJXHT+e5
# 3fmVoboib7qCeok7gebOiYFXdwfel4NfP2DjxHG+WNcXaC6NyHlgNXhZsVI6p3Zc
# MX1YiitnKu1g1dFSJJXoIDGCAdcwggHTAgEBMCUwETEPMA0GA1UEAwwGcHl2ZW52
# AhAuvWaLwrIAtEXA50caD7cLMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcC
# AQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYB
# BAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILhopmqB3huU
# FMaRg0US6KUGKlz0cll27NMGtjIrYz9sMA0GCSqGSIb3DQEBAQUABIIBACKNr/S9
# 2csC8Wj3w7f0e1lEZU/jk93bBK6ZpxH+fQzHkJosGUorVUr+7RgVFGNb0ANXxi03
# qrO5mtivRJ+h7Jv22nu4aOkIUEk1p5sRNRmoTYcAACk2MAmR8buJgRhfozDmn5uV
# 2dPUO8gi6vPKKlaqJVCqfao4N3ixKizobjOemO81WQK2qAHK6wLztdzmmlm7iPfv
# aU9muzDqFyTJsbqC9crT8Bd6zaUDeVrLKBwBPD2Qb7QMrX1Y6spoAF/2OIUQE41I
# F06XqJjxfkfbGchmi1clm9cyZ/3hmlnsLPwOPDUFPVC0SmrlzQpHQ/AHRMxfjHff
# YkNbZkDEm3hFVo8=
# SIG # End signature block
