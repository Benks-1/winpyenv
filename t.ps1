class JsonFileHandler {
    [string]$FilePath

    JsonFileHandler([string]$filePath) {
        $this.FilePath = $filePath
    }

    # Method to read data from the JSON file
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

    # Method to write data to the JSON file
    [void] SetData([hashtable]$data) {
        $json = $data | ConvertTo-Json -Depth 10
        Set-Content -Path $this.FilePath -Value $json
    }

    # Method to create or add a new entry to the JSON file
    [void] Create([string]$key, $value) {
        $data = $this.GetData()
        $data[$key] = $value
        $this.SetData($data)
    }

    # Method to read a specific entry from the JSON file
    [string] GetItem([string]$key) {
        $data = $this.GetData()
        return $data[$key]
    }

    # Method to update an existing entry in the JSON file
    [void] Update([string]$key, $value) {
        $data = $this.GetData()
        if ($data.ContainsKey($key)) {
            $data[$key] = $value
            $this.SetData($data)
        } else {
            throw [System.Exception] "Key '$key' does not exist."
        }
    }

    # Method to delete an entry from the JSON file
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

# Example usage
$handler = [JsonFileHandler]::new("$Env:PY_APPS_PATH\mapping.json")

# Create a new entry
$handler.Create("name", "John Doe")
$handler.Create("age", 30)

# Read an entry
$name = $handler.GetItem("name")
Write-Output "Name: $name"
$age = $handler.GetItem("age")
Write-Output "Age: $age"

# Update an entry
$handler.Update("age", 31)
$age = $handler.GetItem("age")
Write-Output "Age: $age"

# Delete an entry
$handler.Delete("name")

$age = $handler.GetData()
Write-Output "Age: $age"
