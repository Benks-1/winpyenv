# winpyenv
Powershell wrapper around winget and python launcher

## Reason
I wanted to create a functionality like `conda activate` without having the need to install `conda` and I didn't want to `pip install` a tool because I don't want to have it version specific, but instead for all python versions installed on my machine. And since Python Launcher is compatible with azure yaml pipelines this makes the most sense.

## Instalation process

- To enable the scripts to be available through the powershell/pwsh console, simply add the folder where you have downloaded the files into your "System Environmental Variables" (PATH is ok). Make sure that only the exe files are in there otherwise you will have issues with ps1 that is digitally not signed.

- To enable venv creation add a "System Environment Variable" called ENVS_PATH. All venv's that you create with this tool will be by default stored in that directory.

- Note: if you add a "System Environment Variable" called PYLAUNCHER_ALLOW_INSTALL and set any value, Launcher will try to install the python version specified if it is missing on the machine and if it is available. [Python documentation](https://docs.python.org/3/using/windows.html#install-on-demand)


- The powershell scripts are here as a reference of what the exe files are compiled from. And you can modify it also to meet your needs and compile it yourself.
  - Issues: If you end up getting this message `winpyenv: File C:\path\to\winpyenv.ps1 cannot be loaded. The file C:\path\to\winpyenv.ps1 is not digitally signed. You cannot run this script on the current system. For more information about running scripts and setting execution policy, see about_Execution_Policies at https://go.microsoft.com/fwlink/?LinkID=135170.`.
    - Create a copy the files, remove the original, and rename the file names back as the original (most probably you will have to remove ' copy' from all 3 files.) 
    - Or use this: `PowerShell -ExecutionPolicy Bypass -File .\winpyenv.ps1`

## Usage

Usage: winpyenv <tool> <command>

Tools And Comands:
  
- interpreter -> Access Python interpreter tool.
    - list-available -> Provides a list of python versions that are available for download via winget.
    
    - install <Version> [scope] -> Runs the installation process of python (It will ask for version and scope if not defined).
    
    - remove <Version> -> Removes a specific python installation (It will ask for version if not defined).
    
    - list-installed -> Provides a list of all available python installations on the machine

- venv -> Access Python virtual environment tool.
  
  - activate <EnvName>          Activate the specified virtual environment.
  
  - create <EnvName> [Version]  Create a virtual environment with the specified Python version.
  
  - list                        List all virtual environments.
  
  - delete <EnvName>            Delete the specified virtual environment.

Examples:
- winpyenv interpreter list-available
- winpyenv interpreter install -Version 3.9 -Sope machine    -> system-wide installation of python version 3.9.latest
- winpyenv interpreter install -Version 3.9.1 -Sope machine  -> system-wide installation of python version 3.9.1
- winpyenv interpreter install -Version 3.9                  -> This is an example of user installation, same as -Scope user
- winpyenv interpreter remove -Version 3.9                   -> Removes the instalation of python 3.9.x (Only one 3.9 can be installed)
- winpyenv interpreter list-installed                        -> Lists all python versions installed on pc that can be seen by winget
- winpyenv venv create -EnvName venv_name                    -> Creates a python venv with the biggest python version if not defined otherwise
- winpyenv venv create -EnvName venv_name -Version 3.9       -> Creates a python venv with python version 3.9 (if 3.9 is installed)
- winpyenv venv activate -EnvName venv_name                  -> Activates the virtual environment that goes by the name venv_name
- winpyenv venv list                                         -> Lists all available venvs created on the path Env:ENVS_PATH
- winpyenv venv delete -EnvName venv_name                    -> Removes the virtual environment that goes by the name venv_name if exists.
- winpyenv help                                              -> Shows this message

