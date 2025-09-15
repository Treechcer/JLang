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

function evalCondition{
    param(
        $condition,
        $variables
    )

    $conditional = ""
    $op = ""

    if ($condition -match ">"){
        $conditional = "-gt"
        $op = ">"
    }
    elseif ($condition -match "<"){
        $conditional = "-lt"
        $op = "<"
    }
    elseif ($condition -match "=="){
        $conditional = "-eq"
        $op = "=="
    }
    elseif ($condition -match "<="){
        $conditional = "-le"
        $op = "<="
    }
    elseif ($condition -match ">="){
        $conditional = "-ge"
        $op = ">="
    }
    else{
        raiseErr 10
    }

    $left = $condition.split($op)[0].Trim()
    $right = $condition.split($op)[1].Trim()

    if (contains $left $variables){
        $left = getValue $left $variables
    }

    if (contains $right $variables){
        $right = getValue $right $variables
    }

    $cond = "$left $conditional $right"

    return Invoke-Expression $cond 
}