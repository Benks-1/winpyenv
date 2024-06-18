# Define the names for the self-signed certificates
$certificateNames = @("cert1", "cert2", "cert3")

# Get the current script location
$scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# Create self-signed certificates and export them to PFX files in the current script location
foreach ($name in $certificateNames) {
    $cert = New-SelfSignedCertificate -DnsName "$name.local" -CertStoreLocation "cert:\LocalMachine\My"
    $password = ConvertTo-SecureString -String "password" -Force -AsPlainText
    $pfxPath = Join-Path $scriptPath "$name.pfx"
    Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $password
}

# Install certificates to the LocalMachine store
foreach ($name in $certificateNames) {
    $pfxPath = Join-Path $scriptPath "$name.pfx"
    $pfx = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $pfx.Import($pfxPath, $password, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store "My", "LocalMachine"
    $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    $store.Add($pfx)
    $store.Close()
}

$cert = @(Get-ChildItem -Path cert:\LocalMachine\My -CodeSigningCert)[0]
Set-AuthenticodeSignature -FilePath "C:\Path\To\Your\files.ps1" -Certificate $cert

# Add the current folder to the system PATH environment variable
$env:Path += ";" + (Get-Location).Path

# Ask the user for the PY_ENVS_PATH and set it
# ... [previous script content]

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

