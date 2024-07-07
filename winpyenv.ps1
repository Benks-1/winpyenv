param (
    [Parameter(Position=0)]
    [ValidateSet("interpreter", "venv", "app", "help")]
    [string]$Tool,

    [Parameter(Position=1)]
    [string]$Command,

    [Parameter()]
    [string]$Version= $null,
    
    [Parameter()]
    [string]$EnvName,
    
    [Parameter()]
    [string]$AppName,
    
    [Parameter()]
    [int]$Activate = 0,

    [ValidateSet('user', 'machine')]
    [string]$Scope = 'user',

    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Parameters
)


class JsonFileHandler {
    [string]$FilePath

    JsonFileHandler() {
        $this.FilePath = "$Env:PY_APPS_PATH\mapping.json"

        if (-Not (Test-Path -Path $this.FilePath)) {
            @{} | ConvertTo-Json | Set-Content -Path $this.FilePath
            Write-Output "Initialized new JSON file at $($this.FilePath)"
        }
    }

    [hashtable] GetData() {
        if (Test-Path $this.FilePath) {
            $psCustomObject = Get-Content -Path $this.FilePath -Raw | ConvertFrom-Json
            $hashtable = @{}
            foreach ($property in $psCustomObject.PSObject.Properties) {
                $hashtable[$property.Name] = $property.Value
}
            return $hashtable
        } else {
            return @{}
        }
    }

    [void] SetData([hashtable]$data) {
        $json = $data | ConvertTo-Json -Depth 10
        Set-Content -Path $this.FilePath -Value $json
    }

    [void] Create([string]$key, $value) {
        $data = $this.GetData()
        $data[$key] = $value
        $this.SetData($data)
    }

    [string] GetItem([string]$key) {
        $data = $this.GetData()
        return $data[$key]
    }

    [void] Update([string]$key, $value) {
        $data = $this.GetData()
        if ($data.ContainsKey($key)) {
            $data[$key] = $value
            $this.SetData($data)
        } else {
            throw [System.Exception] "Key '$key' does not exist."
        }
    }

    [void] Delete([string]$key) {
        $data = $this.GetData()
        if ($data.ContainsKey($key)) {
            $data.Remove($key)
            $this.SetData($data)
        } else {
            throw [System.Exception] "Key '$key' does not exist."
        }
    }
}


class Venv {
    [string]$ENVS_PATH = $Env:PY_ENVS_PATH

    [void] EnableVenv ([string]$EnvName) {
        $venvPath = Join-Path -Path $this.ENVS_PATH -ChildPath $EnvName 
        if (-not (Test-Path -Path $venvPath)) {
            Write-Host "Error: Virtual environment '$EnvName' does not exist in '$($this.ENVS_PATH)'." -ForegroundColor Red
            return
        }

        $activateScript = Join-Path -Path $venvPath -ChildPath "Scripts\Activate.ps1"
        
        if (-not (Test-Path -Path $activateScript)) {
            Write-Host "Error: Activate script not found in '$venvPath\Scripts'." -ForegroundColor Red
            return
        }

        Write-Host "Activating virtual environment '$EnvName'..." -ForegroundColor Green
        . $activateScript
        Write-Host "Activated '$EnvName'."
    }

    [void] InvokePip ([string]$EnvName, [string]$ArgsString) {
        $Args = $ArgsString -split ' '
        
        $venvPath = Join-Path -Path $this.ENVS_PATH -ChildPath $EnvName 
        if (-not (Test-Path -Path $venvPath)) {
            Write-Host "Error: Virtual environment '$EnvName ' does not exist in '$($this.ENVS_PATH)'." -ForegroundColor Red
            exit 1
        }
    
        $pip = Join-Path -Path $venvPath -ChildPath "Scripts\pip.exe"
        
        if (-not (Test-Path -Path $pip)) {
            Write-Host "Error: Pip not found in '$venvPath\Scripts'." -ForegroundColor Red
            exit 1
        }
    
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = $pip
        $processInfo.Arguments = $ArgsString
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        $processInfo.UseShellExecute = $false
        $processInfo.CreateNoWindow = $true
    
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processInfo
        $process.Start() | Out-Null
    
        $output = $process.StandardOutput.ReadToEnd()
        $errorOutput = $process.StandardError.ReadToEnd()
    
        $process.WaitForExit()
    
        Write-Host $output
        Write-Host $errorOutput -ForegroundColor Red
    
        if ($process.ExitCode -ne 0) {
            exit $process.ExitCode
        }
    }

    [void] StartPythonShell ([string]$EnvName, [string]$ArgsString){
        $Args = $ArgsString -split ' '
        $venvPath = Join-Path -Path $this.ENVS_PATH -ChildPath $EnvName 
        if (-not (Test-Path -Path $venvPath)) {
            Write-Host "Error: Virtual environment '$EnvName ' does not exist in '$($this.ENVS_PATH)'." -ForegroundColor Red
            exit 1
        }
    
        $pythonExe = Join-Path -Path $venvPath -ChildPath "Scripts\python.exe"
        
        if (-not (Test-Path -Path $pythonExe)) {
            Write-Host "Error: Python executable not found in '$venvPath\Scripts'." -ForegroundColor Red
            exit 1
        }
        if ($Args) {
            Write-Host "Executing Python with arguments: $Args"
            $process = Start-Process -FilePath $pythonExe -ArgumentList $Args -NoNewWindow -Wait -PassThru
            Write-Host "Exit code: $($process.ExitCode)"
        } else {
            Write-Host "Starting Python shell in virtual environment '$EnvName'"
            & $pythonExe
        }
    }

    [void] AddVenv([string]$EnvName) {
        $this.AddVenv($EnvName, $null)
    }

    [void] AddVenv([string]$EnvName, [string]$Version, [int]$Activate) {
    
        $venvPath = Join-Path -Path $this.ENVS_PATH -ChildPath $EnvName 
    
        if (Test-Path -Path $venvPath) {
            Write-Host "Error: Virtual environment '$EnvName ' already exists in '$($this.ENVS_PATH)'." -ForegroundColor Red
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
    
        Write-Host "Creating virtual environment '$EnvName' with $usedLauncher..." -ForegroundColor Green
        if ($Version) {
            & $pythonExe -$Version -m venv $venvPath
        } else {
            & $pythonExe -m venv $venvPath
        }
        if (Test-Path -Path $venvPath) {
            Write-Host "Virtual environment '$EnvName' created successfully using $usedLauncher." -ForegroundColor Green
            if ($Activate -eq 1){
                $this.EnableVenv($EnvName)
            }
        } else {
            Write-Host "Error: Virtual environment '$EnvName' was not created in '$($this.ENVS_PATH)'." -ForegroundColor Red
            exit 1
        }
    }

    [void] ShowVenvs() {
        Write-Host "Listing all Apps in '$($this.ENVS_PATH)'..." -ForegroundColor Green
        Get-ChildItem -Path $this.ENVS_PATH -Directory | ForEach-Object {
            Write-Host $_.Name
        }
    }

    [void] RemoveVenv([string]$EnvName) {
        $venvPath = Join-Path -Path $this.ENVS_PATH -ChildPath $EnvName 
        if (-not (Test-Path -Path $venvPath)) {
            Write-Host "Error: Virtual environment '$EnvName' does not exist in '$($this.ENVS_PATH)'." -ForegroundColor Red
            exit 1
        }
        Write-Host "Deleting virtual environment '$EnvName'..." -ForegroundColor Green
        Remove-Item -Recurse -Force -Path $venvPath
        Write-Host "Virtual environment '$EnvName' deleted successfully."
    }
}


class Interpreter {

    static [PSCustomObject[]] GetAvailablePythonVersions() {        
        $main = winget search --id Python.Python --source winget |
            Select-String -Pattern "Python.Python" |
            ForEach-Object {
                $line = $_.Line
                $parts = $line -split '\s+'
                [PSCustomObject]@{
                    Name    = $parts[0..($parts.Length - 3)] -join ' '
                    Id      = $parts[-2]
                    Version = $parts[-1]
                    Source  = "winget"
                    Code    = $parts[1]
                }
            } |
            Where-Object { $_.Code -notin @("2", "3.1", "3.0") }
        
        $jobs = @()
        foreach ($version in $main) {
            $jobs += Start-Job -ScriptBlock {
                param($version)
                $minors = winget search --id Python.Python --source $using:version.Source --versions $using:version.Code | Select-String -Pattern '^\d'
                $results = @()
                foreach ($minor in $minors) {
                    $results += [PSCustomObject]@{
                        Name    = $using:version.Name
                        Id      = $using:version.Id
                        Version = $minor
                        Source  = "winget"
                    }
                }
                $results
            } -ArgumentList $version
        }
        
        # Wait for all jobs to complete and collect the results
        $collection = [System.Collections.Generic.List[PSObject]]::new()
        $jobs | ForEach-Object {
            $_ | Wait-Job
            $results = Receive-Job -Job $_
            foreach ($result in $results) {
                $collection.Add($result)
            }
            Remove-Job -Job $_
        } | Out-Null
                
        return $collection | Select-Object Name, Id, Version, Source | Format-Table -AutoSize
    }

    static [void] InstallPython([string]$Version, [string]$Scope = 'user') {
        $versionParts = $Version -split '\.'
        if ($versionParts.Length -gt 3 -or $versionParts.Length -lt 2) {
            Write-Host "Error: This '$Version' is not a valid Python version." -ForegroundColor Red
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

    static [void] RemovePython([string]$Version) {
        $versionParts = $Version -split '\.'
        if ($versionParts.Length -gt 3 -or $versionParts.Length -lt 2) {
            Write-Host "Error: This '$Version' is not valid python version." -ForegroundColor Red
            exit 1
        }
        $versionMajor = "$($versionParts[0]).$($versionParts[1])"
        Write-Output "Try to uninstall Python version $Version..."
        winget uninstall --id Python.Python.$versionMajor
    }

    static [PSCustomObject[]] GetInstalledPythonVersions() {
        $installedVersions = winget list --id Python.Python | Select-String -Pattern "Python.Python" | ForEach-Object {
            $line = $_.Line
            $parts = $line -split '\s+'
            [PSCustomObject]@{
                Name    = $parts[0..($parts.Length - 4)] -join ' '
                Id      = $parts[-3]
                Version = $parts[-2]
                Source  = $parts[-1]
            }
        }
        return $installedVersions
    }
}


class App {
    [Venv]$venv
    [JsonFileHandler]$handler
    [string]$ENVS_PATH
    [string]$APPS_PATH

    App() {
        $this.venv = [Venv]::new()
        $this.handler = [JsonFileHandler]::new()
        $this.ENVS_PATH = $Env:PY_ENVS_PATH
        $this.APPS_PATH = $Env:PY_APPS_PATH
    }

    [void] ShowApps(){
        Write-Host "Listing all Appliocations in '$($this.APPS_PATH)'..." -ForegroundColor Green
        Get-ChildItem -Path $this.APPS_PATH | Where-Object {$_.Name -Match ".ps1"} | ForEach-Object {
            Write-Host $_.Name
        }
    }

    [void] AddApp([string]$AppName, [string]$EnvName ,[string]$Version){
        # TODO: Check if .exe exist othervise remove the app. If it exists also add to mapping 
        if(($null -eq $EnvName) -or ($EnvName = ' ') ){
            $EnvName = $AppName
        }
        $this.venv.AddVenv($EnvName, $Version, 0)
        Write-Host "Pip installing '$AppName'." -ForegroundColor Green
        $this.venv.InvokePip($EnvName, "install $AppName")
        $executable = "$($this.ENVS_PATH)\$EnvName\Scripts\$AppName.exe"
        if (Test-Path -Path $executable){
            Write-Host "Creating '$AppName.ps1' executable." -ForegroundColor Green
            $global = "$($this.APPS_PATH)\$AppName.ps1"

            $scriptContent = @"
param (
    [Parameter(ValueFromRemainingArguments=`$true)]
    [string[]]`$Parameters
)
`$pth = '$executable'
`& `$pth @Parameters
"@
            Set-Content -Path $global -Value $scriptContent
            $this.handler.Create($AppName, $EnvName)
        } else {
            Write-Host "Removing '$AppName.ps1' since it does not contain a '$AppName.exe'." -ForegroundColor Red
            $this.venv.RemoveVenv($EnvName)
        }
    }

    [void] RemoveApp([string]$AppName){
        Write-Host "Searching for `EnvName` of '$AppName'." -ForegroundColor Green
        $envName = $this.handler.GetItem($AppName)
        Write-Host "Removing `EnvName ($envName)` of App: '$AppName'." -ForegroundColor Green
        $this.handler.Delete($AppName)
        $this.venv.RemoveVenv($envName)
        Write-Host "Removing executable '$AppName.ps1'." -ForegroundColor Green
        Remove-Item -Path "$($this.APPS_PATH)\$AppName.ps1"
    }

    [void] InvokePip ([string]$AppName, [string]$ArgsString){
        $envName = $this.handler.GetItem($AppName)
        $this.venv.InvokePip($envName, $ArgsString)
    }
}


function Show-Help {
    Write-Host @"
Usage: winpyenv <tool> <command>

Tool options:
  - venv
  Commands:
    - list
    - create
    - activate
    - delete
    - shell
    - pip

  - interpreter
  Commands:
    - list-available
    - install
    - uninstall
    - list-installed 

  - app
  Commands:
    - list
    - install
    - uninstall
    - pip

  - help


Examples:
  winpyenv venv list                                         -> Lists all available venvs created on the path Env:ENVS_PATH
  winpyenv venv create -EnvName venv_name                    -> Creates a python venv with the biggest python version if not defined othervise
  winpyenv venv create -EnvName venv_name -Version 3.9       -> Creates a python venv with python version 3.9 (if 3.9 is installed)
  winpyenv venv create -EnvName venv_name -Activate 1        -> Creates a python venv with the default interpreter and activates the environment.
  winpyenv venv activate -EnvName venv_name                  -> Activates the virtual environment that goes by the name venv_name
  winpyenv venv delete -EnvName venv_name                    -> Removes the virtual environmet that goes by the name venv_name if exists.
  winpyenv venv shell -EnvName venv_name                     -> Starts the python shell of the selected environment.
  winpyenv venv shell -EnvName venv_name '-c "a = input(''Type you\''re name >''); print(f''Hello {a}'')"' -> Executes the provided commands aginst the python interpreter of the environment that goes by the name venv_name.
  winpyenv venv pip -EnvName venv_name freeze                -> Provides a list of installed packages in the environment that goes by the name venv_name.
  winpyenv venv pip -EnvName venv_name install package_name  -> Installs the package_name directly into the environment that goes by the name venv_name.

  winpyenv interpreter list-available
  winpyenv interpreter install -Version 3.9 -Sope machine    -> system-wide installation of python version 3.9.latest
  winpyenv interpreter install -Version 3.9.1 -Sope machine  -> system-wide installation of python version 3.9.1
  winpyenv interpreter install -Version 3.9                  -> This is an example of user installation, same as -Scope user
  winpyenv interpreter uninstall -Version 3.9                -> Removes the instalation of python 3.9.x (Only one 3.9 can be installed)
  winpyenv interpreter list-installed                        -> Lists all python versions installed on pc that can be seen by winget

  winpyenv app list                                          -> Lists all python applications Installed
  winpyenv app install -AppName venv_name                    -> Will install the python appplication venv_name, and the EnvName will also be venv_name
  winpyenv app install -AppName venv_name -EnvName another   -> Will install the python appplication venv_name, under the EnvName another
  winpyenv app install -AppName venv_name -Version 3.9       -> Will install the python appplication venv_name, with python version 3.9
  winpyenv app install -AppName venv_name -Version 3.9 -EnvName another -> Will install the python appplication venv_name, under the EnvName `another` with python version 3.9
  winpyenv app uninstall -AppName venv_name                  -> Will remove the venv_name.ps1 file from Env:PY_APPS_PATH and remove the corresponding env folder in Env:PY_ENVS_PATH
  winpyenv app pip -AppName venv_name freeze                 -> Will invoke pip from the application envoronment and execute freeze against it.
  winpyenv app pip -AppName venv_name install package        -> Will invoke pip from the application envoronment and execute install package against it.

  winpyenv help                                              -> Shows this message
"@
}


function Select-VenvOption {
    param (
        [Parameter(Position=0)]
        [ValidateSet("activate", "create", "list", "delete", "pip", "shell")]
        [string]$command
    )
    $venv = New-Object Venv
    switch ($command) {
        "activate" { 
            if (-not $EnvName ) {
                Write-Host "Error: 'activate' action requires <EnvName>." -ForegroundColor Red
                Show-Help
                exit 1
            }
            $venv.EnableVenv($EnvName)  
        }
        "create" { 
            if (-not $EnvName ) {
                Write-Host "Error: 'create' action requires <EnvName>." -ForegroundColor Red
                Show-Help
                exit 1
            }
            $venv.AddVenv($EnvName, $Version, $Activate)
        }
        "list" { $venv.ShowVenvs() }
        "delete" { 
            if (-not $EnvName ) {
                Write-Host "Error: 'delete' action requires <EnvName>." -ForegroundColor Red
                Show-Help
                exit 1
            }
            $venv.RemoveVenv($EnvName)  
        }
        "pip" {
            if (-not $EnvName ) {
                Write-Host "Error: 'pip' action requires <EnvName> and arguments what it should do." -ForegroundColor Red
                Show-Help
                exit 1
            }
            $venv.InvokePip($EnvName,($Parameters -join ' '))
        }
        "shell"{
            if (-not $EnvName ) {
                Write-Host "Error: 'shell' action requires <EnvName>." -ForegroundColor Red
                Show-Help
                exit 1
            }
            $venv.StartPythonShell($EnvName, ($Parameters -join ' '))
        }
    }
}


function Select-IntepreterOption {
    param (
        [Parameter(Position=0)]
        [ValidateSet("list-installed", "list-available", "install", "remove")]
        [string]$command
    )
    switch ($command) {
        "list-available" {
            [Interpreter]::GetAvailablePythonVersions() | Format-Table -AutoSize
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
            [Interpreter]::InstallPython($version, $scope)
        }
        "uninstall" {
            if ($Version -eq ''){
                $version = Read-Host "Enter the Python version to remove"
            } else {
                $version = $Version
            }
    
            [Interpreter]::RemovePython($version)
        }
        "list-installed" {
            [Interpreter]::GetInstalledPythonVersions() | Format-Table -AutoSize
        }
    }
}


function Select-AppOptions{
    param (
        [Parameter(Position=0)]
        [ValidateSet("install", "uninstall", "pip", "list")]
        [string]$command
    )
    $app = New-Object App
    switch ($command) {
        "list" {
            $app.ShowApps()
        }
        "install" { 
            $app.AddApp($AppName, $EnvName, $Version)
         }
        "uninstall"{
            $app.RemoveApp($AppName)
        }
        "pip"{
            $app.InvokePip($AppName, ($Parameters -join ' '))
        }
    }
}


switch ($Tool) {
    "venv" {
        Select-VenvOption($Command)
    }
    "interpreter"{
        Select-IntepreterOption($Command)
    }
    "app"{
        Select-AppOptions($Command)
    }
    "help" { Show-Help }
    default { Show-Help }

}
