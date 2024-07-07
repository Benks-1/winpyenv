# winpyenv
Powershell wrapper around winget and python (python and/or python launcher)

## Reason
I wanted to have simple solution to manage pure python installations and environments.

Venv actions that it should do:
- show a list of environments created.
- create a venv of any python version installed on users machine.
- activate the venv easily from the console (without specifying the full path).
- removing the venv from the console (without specifying the full path).
- run the python shell from a specific venv.
- pip directly into the venv without activating it.

Installation actions that it should do:
- show a list of python installations it can use.
- show a list of python versions it can download and install.
- install a specific python version.
- uninstall a specific python version

App actions that it should do (something like PIPX):
- show a list of installed python apps.
- remove an python app
- install an python app (everything that has an app_name.exe file e.g. cookiecutter pip install comes with a cookiecutter.exe)
- adding dependencies into the app environment


## Instalation process

- You should use the `install.ps1` file, to properly install these scripts.
- Open powershell with admin rights in the folder with the install.ps1 and winenvpy.ps1, and execute this command: `powershell.exe -ExecutionPolicy Bypass -File .\install.ps1`

- It will open a Gui and there you will define the paths. It will add PY_ENVS_PATH, PY_APPS_PATH into the system environmental variables (user-specific or system-wide, you can choose) and, the current folder where you have downloaded these scripts together with `%PY_APPS_PATH%` will go into your Env:PATH so that you can use this tool and the apps you install. And the last thing it will do it will create Self-Signed CodeCertificate and add it to the `winpyenv.ps1` at the end so that you can use it. If it doesn't work, create a `file.ps1` and copy the entire code from the original to the new one and save, delete the original and rename the new to have the same name. 


## Usage

Usage: winpyenv <tool> <command>

Tools And Comands:
  
- interpreter -> Access Python interpreter tool.
  - list-available              Provides a list of python versions that are available for download via winget.
  - list-installed              Provides a list of all available python installations on the machine
  - install <Version> [Scope]   Runs the installation process of python (It will ask for version and scope if not defined).
  - uninstall <Version>         Removes a specific python installation (It will ask for version if not defined).

- venv -> Access Python virtual environment tool.
  - activate <EnvName>            Activate the specified virtual environment.
  - create <EnvName> [Version]    Create a virtual environment with the specified Python version.
  - list                          List all virtual environments.
  - delete <EnvName>              Delete the specified virtual environment.
  - shell <EnvName> [Parameters]  Starts the python interpreter of that specific venv, and can execute command's against the interpreter.
  - pip <EnvName> <Parameters>    Opens the specific pip in the venv a runs provided commands directly against it

- app -> Access Application tool.
  - list                                  Shows all installed python applications
  - install <AppName> [EnvName] [Version] Installs a python app
  - uninstall <AppName>                   Uninstalls a python app
  - pip <AppName>                         Provides pip access into the environment of the application.

Examples:
- winpyenv interpreter list-available                        -> Lists most python versions that can be installed directly from winget
- winpyenv interpreter list-installed                        -> Lists all python versions installed on pc that can be seen by winget
- winpyenv interpreter install -Version 3.9 -Scope machine   -> System-wide installation of python version 3.9.latest
- winpyenv interpreter install -Version 3.9.1 -Scope machine -> System-wide installation of python version 3.9.1
- winpyenv interpreter install -Version 3.9                  -> This is an example of user installation, same as -Scope user
- winpyenv interpreter remove -Version 3.9                   -> Removes the installation of python 3.9.x (Only one 3.9 can be installed)

- winpyenv venv list                                         -> Lists all available venvs created on the path Env:ENVS_PATH
- winpyenv venv create -EnvName venv_name                    -> Creates a python venv (with the biggest python version if python launcher is installed and there is no other default defined)
- winpyenv venv create -EnvName venv_name -Version 3.9       -> Creates a python venv with python version 3.9 (if 3.9 is installed)
- winpyenv venv create -EnvName venv_name -Activate 1        -> Creates a python venv with the default interpreter and activates the environment.
- winpyenv venv activate -EnvName venv_name                  -> Activates the virtual environment that goes by the name venv_name
- winpyenv venv shell -EnvName venv_name                     -> Starts the python interpreter of the environment that goes by the name venv_name.
- winpyenv venv shell -EnvName venv_name '-c "a = input(''Type you\''re name >''); print(f''Hello {a}'')"' -> Executes the provided commands aginst the python interpreter of the environment that goes by the name venv_name.
- winpyenv venv pip -EnvName venv_name freeze                -> Provides a list of installed packages in the environment that goes by the name venv_name.
- winpyenv venv pip -EnvName venv_name install package_name  -> Installs the package_name directly into the environment that goes by the name venv_name.
- winpyenv venv delete -EnvName venv_name                    -> Removes the virtual environment that goes by the name venv_name if exists.

- winpyenv app list                                          -> Lists all python applications Installed
- winpyenv app install -AppName venv_name                    -> Will install the python appplication venv_name, and the EnvName will also be venv_name
- winpyenv app install -AppName venv_name -EnvName another   -> Will install the python appplication venv_name, under the EnvName another
- winpyenv app install -AppName venv_name -Version 3.9       -> Will install the python appplication venv_name, with python version 3.9
- winpyenv app install -AppName venv_name -Version 3.9 -EnvName another -> Will install the python appplication venv_name, under the EnvName `another` with python version 3.9
- winpyenv app uninstall -AppName venv_name                  -> Will remove the venv_name.ps1 file from Env:PY_APPS_PATH and remove the corresponding env folder in Env:PY_ENVS_PATH
- winpyenv app pip -AppName venv_name freeze                 -> Will invoke pip from the application envoronment and execute freeze against it.
- winpyenv app pip -AppName venv_name install package        -> Will invoke pip from the application envoronment and execute install package against it.

- winpyenv help                                              -> Shows this message

Note: if you add a "System Environment Variable" called PYLAUNCHER_ALLOW_INSTALL and set any value, Launcher will try to install the python version specified if it is missing on the machine and if it is available and if python launcher is installed. [Python documentation](https://docs.python.org/3/using/windows.html#install-on-demand)