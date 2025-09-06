function test {
    "TEST"
}

function initV {
    param (
        [string]$file
    )

    $JSON = Get-Content -Path "$file" -Raw | ConvertFrom-Json

    $variables = @()

    foreach ($prop in $JSON.INIT.PSObject.Properties) {
        $variables += [PSCustomObject]@{
            Name  = $prop.Name
            Value = $prop.Value
            Type  = $prop.Value.GetType().Name
        }
    }

    return $variables
}