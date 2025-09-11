. ./varWork.ps1

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
        $variables = createVar $prop.Name $prop.Value $variables
    }

    return $variables
}

function initF {
    param (
        [string]$file
    )

    $JSON = Get-Content -Path "$file" -Raw | ConvertFrom-Json

    $functions = @()
    for ($i = 0; $i -lt $JSON.FUNCTIONS.Length; $i++) {
        foreach ($prop in $JSON.FUNCTIONS[$i].PSObject.Properties){
            if ($prop.Name[0] -ne "_"){
                raiseErr 5
            }
            $functions += $prop.Name
        }
    }

    return $functions
}