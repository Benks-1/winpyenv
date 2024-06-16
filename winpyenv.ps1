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
    pywinget.exe $command -Version $Version -Scope $Scope
}

function Venv {
    pyvenv.exe $command -Version $Version -EnvName $EnvName
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