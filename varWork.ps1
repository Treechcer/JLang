function createVar {
    param(
        $name,
        $value,
        $variables
    )

    #$name
    #$value

    $variables.GetType().Name #btw. if you delete tis it will crap itself and won't work

    $variables += [PSCustomObject]@{
        Name  = $name
        Value = $value
        Type  = $value.GetType().Name
    }

    return $variables 
}

function writeVars{
    param(
        $v
    )
    foreach ($var in $v){
        Write-Host $var
    }
}

function getValue{
    param(
        [string]$name,
        $variables
    )

    $name = $name -replace "\s", ""

    foreach($var in $variables){
        if ($var.Name -eq $name){
            return $var.Value
        }
    }
}

function changeVar {
    param(
        [string]$varName,
        $value,
        $variables
    )

    $varName = $varName -replace "\s", ""

    $found = $false
    foreach ($var in $variables){
        if ($var.Name -eq $varName){
            $var.Value = $value
            $var.Type = $value.GetType().Name
            $found = $true
            break
        }
    }

    if (-not $found){
        raiseErr 3
    }

    return $variables
}

function contains {
    param(
        [string]$split,
        $variables
    )

    $split = $split -replace "\s", ""
    foreach($var in $variables){
        if ($var.Name -eq $split){
            return $true
        }
    }

    return $false
}