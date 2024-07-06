# Enable Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Configure Paths"
$form.Size = New-Object System.Drawing.Size(400, 200)
$form.StartPosition = "CenterScreen"

# Default values
$defaultEnvPath = Join-Path $Env:HOMEDRIVE "PythonEnvironment"
$defaultAppsPath = Join-Path $Env:HOMEDRIVE "PythonApps"

# Create the labels
$label1 = New-Object System.Windows.Forms.Label
$label1.Text = "PY_ENVS_PATH:"
$label1.Location = New-Object System.Drawing.Point(10, 20)
$label1.Size = New-Object System.Drawing.Size(100, 20)
$form.Controls.Add($label1)

$label2 = New-Object System.Windows.Forms.Label
$label2.Text = "PY_APPS_PATH:"
$label2.Location = New-Object System.Drawing.Point(10, 60)
$label2.Size = New-Object System.Drawing.Size(100, 20)
$form.Controls.Add($label2)

# Create the text boxes with default values
$textBox1 = New-Object System.Windows.Forms.TextBox
$textBox1.Text = $defaultEnvPath
$textBox1.Location = New-Object System.Drawing.Point(120, 20)
$textBox1.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($textBox1)

$textBox2 = New-Object System.Windows.Forms.TextBox
$textBox2.Text = $defaultAppsPath
$textBox2.Location = New-Object System.Drawing.Point(120, 60)
$textBox2.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($textBox2)

# Create the buttons
$button1 = New-Object System.Windows.Forms.Button
$button1.Text = "Browse..."
$button1.Location = New-Object System.Drawing.Point(330, 20)
$button1.Size = New-Object System.Drawing.Size(50, 20)
$form.Controls.Add($button1)

$button2 = New-Object System.Windows.Forms.Button
$button2.Text = "Browse..."
$button2.Location = New-Object System.Drawing.Point(330, 60)
$button2.Size = New-Object System.Drawing.Size(50, 20)
$form.Controls.Add($button2)

# FolderBrowserDialog
$folderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog

$button1.Add_Click({
    if ($folderBrowserDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $textBox1.Text = $folderBrowserDialog.SelectedPath
    }
})

$button2.Add_Click({
    if ($folderBrowserDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $textBox2.Text = $folderBrowserDialog.SelectedPath
    }
})

# Create the radio buttons
$radioButton1 = New-Object System.Windows.Forms.RadioButton
$radioButton1.Text = "User Profile"
$radioButton1.Location = New-Object System.Drawing.Point(10, 100)
$radioButton1.Size = New-Object System.Drawing.Size(100, 20)
$form.Controls.Add($radioButton1)
$radioButton1.Checked = $true  # Default selection

$radioButton2 = New-Object System.Windows.Forms.RadioButton
$radioButton2.Text = "System Wide"
$radioButton2.Location = New-Object System.Drawing.Point(120, 100)
$radioButton2.Size = New-Object System.Drawing.Size(100, 20)
$form.Controls.Add($radioButton2)

# Create the Save button
$saveButton = New-Object System.Windows.Forms.Button
$saveButton.Text = "Save"
$saveButton.Location = New-Object System.Drawing.Point(300, 130)
$saveButton.Size = New-Object System.Drawing.Size(80, 30)
$form.Controls.Add($saveButton)

# Save button functionality
$saveButton.Add_Click({
    $envsPath = $textBox1.Text
    $appsPath = $textBox2.Text

    # Create directories if they don't exist
    if (-not (Test-Path -Path $envsPath)) {
        New-Item -ItemType Directory -Path $envsPath | Out-Null
    }
    if (-not (Test-Path -Path $appsPath)) {
        New-Item -ItemType Directory -Path $appsPath | Out-Null
    }

    if ($radioButton1.Checked) {
        $newPath = (Get-Location).Path
        $currentPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        [System.Environment]::SetEnvironmentVariable("PY_ENVS_PATH", $envsPath, "User")
        [System.Environment]::SetEnvironmentVariable("PY_APPS_PATH", $appsPath, "User")
        
                if ($currentPath -notlike "*$newPath*") {
                    $newPathToAdd = "$currentPath;$newPath;%PY_APPS_PATH%"
                    [System.Environment]::SetEnvironmentVariable("Path", $newPathToAdd, "User")
                }

    } elseif ($radioButton2.Checked) {
        $newPath = (Get-Location).Path
        $currentPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
        
        [System.Environment]::SetEnvironmentVariable("PY_ENVS_PATH", $envsPath, "Machine")
        [System.Environment]::SetEnvironmentVariable("PY_APPS_PATH", $appsPath, "Machine")
        
                if ($currentPath -notlike "*$newPath*") {
                    $newPathToAdd = "$currentPath;$newPath;%PY_APPS_PATH%"
                    [System.Environment]::SetEnvironmentVariable("PATH", $newPathToAdd, "Machine")
                }
    }

    # Define the names for the self-signed certificates
    $certificateNames = @("WinPyEnv")

    # Using the folder path of the current location of this script
    $scriptPath = $PSScriptRoot

    # Create and install self-signed certificates
    foreach ($name in $certificateNames) {
        # Create a self-signed certificate
        $cert = New-SelfSignedCertificate -CertStoreLocation Cert:\LocalMachine -Subject "CN=$name" -KeySpec Signature -Type CodeSigningCert

        # Assign the certificate to a file (if it exists)
        $fileToSign = Join-Path $scriptPath "$name.ps1"
        if (Test-Path $fileToSign) {
            Set-AuthenticodeSignature -FilePath $fileToSign -Certificate $cert
            Write-Host "Certificate assigned to $fileToSign"
        } else {
            Write-Host "File $fileToSign not found."
        }
    } 
    
    $form.Close()
})

# Display the form
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
