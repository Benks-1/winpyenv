param (
    [Parameter(Position=0)]
    [ValidateSet("interpreter", "venv", "help")]
    [string]$tool,

    [Parameter(Position=1)]
    [string]$command,

    [Parameter()]
    [string]$Version,

    [Parameter()]
    [ValidateSet('user', 'machine')]
    [string]$Scope = 'user',

    [Parameter()]
    [string]$EnvName
)

function Show-Help {
    Write-Host @"
Usage: winpyenv <tool> <command>

Tools And Comands:
- interpreter           Access Python interpreter tool.
    list-available              Provides a list of python versions that are available for download via winget.
    install <Version> [scope]   Runs the installation process of python (It will ask for version and scope if not defined).
    remove <Version>            Removes a specific python installation (It will ask for version if not defined).
    list-installed              Provides a list of all available python installations on the machine
- venv                  Access Python virtual environment tool.
    activate <EnvName>          Activate the specified virtual environment.
    create <EnvName> [Version]  Create a virtual environment with the specified Python version.
    list                        List all virtual environments.
    delete <EnvName>            Delete the specified virtual environment.

Examples:
  winpyenv interpreter list-available
  winpyenv interpreter install -Version 3.9 -Sope machine    -> system-wide installation of python version 3.9.latest
  winpyenv interpreter install -Version 3.9.1 -Sope machine  -> system-wide installation of python version 3.9.1
  winpyenv interpreter install -Version 3.9                  -> This is an example of user installation, same as -Scope user
  winpyenv interpreter remove -Version 3.9                   -> Removes the instalation of python 3.9.x (Only one 3.9 can be installed)
  winpyenv interpreter list-installed                        -> Lists all python versions installed on pc that can be seen by winget
  winpyenv venv create -EnvName venv_name                    -> Creates a python venv with the biggest python version if not defined othervise
  winpyenv venv create -EnvName venv_name -Version 3.9       -> Creates a python venv with python version 3.9 (if 3.9 is installed)
  winpyenv venv activate -EnvName venv_name                  -> Activates the virtual environment that goes by the name venv_name
  winpyenv venv list                                         -> Lists all available venvs created on the path Env:ENVS_PATH
  winpyenv venv delete -EnvName venv_name                    -> Removes the virtual environmet that goes by the name venv_name if exists.
  winpyenv help                                              -> Shows this message
"@
}

function Interpreter {
    pywinget.ps1 $command -Version $Version -Scope $Scope
}

function Venv {
    pyvenv.ps1 $command -Version $Version -EnvName $EnvName
}

switch ($tool) {
    "Interpreter" { 
        Interpreter
    }
    "venv" {
        Venv
    }

    "help" { Show-Help }
    default { Show-Help }

}
# SIG # Begin signature block
# MIIFfQYJKoZIhvcNAQcCoIIFbjCCBWoCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDVXCrkLlDNSXk3
# jJiL0/pFT5smwjEL/cL/td3Nw8dnEKCCAvowggL2MIIB3qADAgECAhAfEv9J6PXd
# vkg+ar7/sAssMA0GCSqGSIb3DQEBBQUAMBMxETAPBgNVBAMMCHdpbnB5ZW52MB4X
# DTI0MDYyNDA3MTAwN1oXDTI1MDYyNDA3MzAwN1owEzERMA8GA1UEAwwId2lucHll
# bnYwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDi/v5eKsbBEzBLjvz6
# YARzbelRKTkjECiu9K0pOE7boGvRbHkiINcLL16ApPnNDQsRRVjl8zYynUOu7rLG
# ydraIZztiJFPUrq45yxD4XJp3DoOCXE4zpxgol67bizJikRDCBmKMhyPusq6sjND
# 3VDkL2v4gYEOnhSAEXKY2smnn5so23keqUAdU62c4SHzHtv+gRF0IbZ38dLuxGeY
# Rj4w5gX5xcMtAVSzh5nx2zz5Qw4NAdscRiBko6le4RELTN09SuMvWTRzCESPjLT9
# VPu5/P5jeg9WQPJohSYA2uEiSRfdMs28tFkwpNK/gvIPJVOe276wknAFFA51v3iD
# 0IElAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcD
# AzAdBgNVHQ4EFgQUvfoXlscXkvAYmHVVGbpIW0zH9yYwDQYJKoZIhvcNAQEFBQAD
# ggEBAK56/+IpOU6z/jKKygpEQ7x08D2gviHfKwS+i8vMLtZC2XpQuiU/BTOfbFx4
# AYKGg/C/EoWov0eW8PmCdgzjnKhL9Fcaz1y+XOXXbRKIQ2j/0F/VKQcLYdW0EzxO
# FuZ898FZSvo7QEpiWb/z+gfvtRnIkk9K6BKkpjZ9/JRx0d4Q7sqX4qQlX/1gz2B3
# jvx/PuQtCwKr2tMeW6oVCUmZM7I5g1gaO1hZusfGyqgkPN3PCEbcy8riKrI8rZ/r
# 9XDFUY0yjTIoAF+EJuvrD2MSDch3mGtIRqvLGWLmkWXH4Jb56CaobkL8Yk4/jzXU
# l07Xm0sp+poIn2K+bPZ2c52hnnUxggHZMIIB1QIBATAnMBMxETAPBgNVBAMMCHdp
# bnB5ZW52AhAfEv9J6PXdvkg+ar7/sAssMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisG
# AQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIaQ
# MpeP582djBbrFE94gl9o76vvsQWXA/CVPDWG/xlFMA0GCSqGSIb3DQEBAQUABIIB
# AFEjBzV1hzumTvOlLlX0Pc41UJKdvugPWzaV1nwfP7qKy0wPLsJQgYe9qPeyvy2J
# Mj9kpqqpSNVlKR2Va8/CQcn+vgPXjfzNf9kEMaouPIDJfFa0JGcbhXl4qs0mqmU+
# N3i8Aamc3JUZ6/NgKPbjSiSPqMdKvg0437HAx/7wICvj3WLfhNKYmv9zok5r3yxk
# xQm+Jr2G1TMOgC9LFTVH9tU8Vrc6yqm0GkwN3h9XtZ+Fx0zs/zzuoD5AundSGTwr
# CmOZV05aryIonPgwRqOY9DzGLjT5/4bBTPD9ASO+iTa6x+vK1nvztsZAgsufdsMW
# edRJgKa/0M+2r+OxOUYjiz4=
# SIG # End signature block
