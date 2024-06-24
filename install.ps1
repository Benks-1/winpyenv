# Restart as Admin if not started as such.
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Start-Process pwsh.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Define the names for the self-signed certificates
$certificateNames = @("pyvenv", "pywinget", "winpyenv")

# žUsing the folder path of the current location of this script
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
# Add the current folder to the system PATH environment variable
$env:Path += ";" + (Get-Location).Path

# Use a folder browser dialog to ask the user for the PY_ENVS_PATH
Add-Type -AssemblyName System.Windows.Forms
$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$folderBrowser.Description = "Select the PY_ENVS_PATH"
$folderBrowser.UseDescriptionForTitle = $true

# Show the folder browser dialog
if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $pyEnvsPath = $folderBrowser.SelectedPath
    [System.Environment]::SetEnvironmentVariable("PY_ENVS_PATH", $pyEnvsPath, [System.EnvironmentVariableTarget]::User)
    Write-Host "PY_ENVS_PATH set to $pyEnvsPath"
} else {
    Write-Host "PY_ENVS_PATH selection was canceled."
}

# Output to indicate completion
Write-Host "Installation complete."

