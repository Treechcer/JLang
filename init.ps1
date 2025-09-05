function test {
    "TEST"
}

function initV {
    param (
        [string]$file
    )
    
    $variables = @{}

    $JSON = Get-Content -Path "$file" -Raw | ConvertFrom-Json

    $variables = $JSON.init

    return $variables
}