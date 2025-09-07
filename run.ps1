. ./err.ps1

function parse{
    param(
        [string]$file,
        [PSCustomObject]$variables
    )
    $JSON = Get-Content -Path "$file" -Raw | ConvertFrom-Json
    #$variables
    foreach ($lineRaw in $JSON.RUN){

        executeCode $lineRaw

    }

    writeVars
}

function executeCode{
    param(
        $lineRaw
    )
    $line = $lineRaw -replace "\s", ""

    $split = $line.split("=")[0]
    $val = $line.split("=")[1]
    $varExists = contains $split
    #writeVars
    if ($varExists){
        if ($val -match "\+" -or $val -match "-" -or $val -match "\*" -or $val -match "/"){
            $things = $val -split "[-+*/]"
            $operators = $val -split "[^-+*/]"

            $temp = @()
            foreach ($thing in $things){
                if (-not ($thing -eq "")){
                    $temp += $thing
                }
            }

            $things = $temp

            $temp = @()
            foreach ($operator in $operators){
                if (-not ($operator -eq "")){
                    $temp += $operator
                }
            }

            $operators = $temp

            for ($i = 0; $i -lt $things.Length; $i++){
                $thing = $things[$i]
                if ($thing -is [string]){
                    if (contains $thing){
                        $things[$i] = getValue $thing
                    }
                    else{
                        try {
                            $thing = [int] $thing
                        }
                        catch {
                            raiseErr 3
                        }
                    }
                }
            }
            
            $expr = ""
            for($i = 0; $i -lt $operators.Length; $i++){
                $expr += [string]$things[$i] + [string]$operators[$i]
            }

            $expr += [string]$things[$things.Length - 1]

            $value = Invoke-Expression $expr
        }
        else{
            $value = $line.Split("=")[1]
            if ($value -eq ""){
                raiseErr 1
            }

            if ($value[0] -eq "'" -and $value[$value.Length-1] -eq "'"){
                $value = $value.split("'")[1]
            }
        }
        changeVar $split $value
    }
    else{
        if ($lineRaw -is [pscustomobject]) {
            if ($lineRaw.PSObject.Properties.Name -contains "IF") {

                $value = makeIF $lineRaw.IF.CONDITION $lineRaw.IF.CODE

                if ($value){
                    foreach ($parts in $lineRaw.IF.CODE){
                        executeCode $parts
                    } 
                }
                if (-not $value -and $lineRaw.PSObject.Properties.Name -contains "ELSEIF") {
                    for ($i = 0; $i -lt $lineRaw.ELSEIF.Length; $i++){
                        $value = makeIF $lineRaw.ELSEIF[$i].CONDITION $lineRaw.ELSEIF.CODE
                        if ($value){
                            foreach ($parts in $lineRaw.ELSEIF[$i].CODE){
                                executeCode $parts
                            }
                            break
                        }
                    }
                }
                if (-not $value -and $lineRaw.PSObject.Properties.Name -contains "ELSE"){
                    foreach ($parts in $lineRaw.ELSE.CODE){
                        executeCode $parts
                    }
                }
            }
        }

        if (-not ($line -match "=")){
            raiseErr 2
        }

        $value = $line.Split("=")[1]
        if ($value -eq ""){
            raiseErr 1
        }
    }
}

function makeIF {
    param(
        $CONDITION,
        $CODE
    )
    $conditions = [string]$CONDITION -split "[\<\>\<=\>=]"
    $operators = [string]$CONDITION -split "[^\<\>\<=\>=]"

    $temp = @()
    foreach ($thing in $conditions){
        if (-not ($thing -eq "")){
            $thing = ($thing -replace "\s", "")
            $temp += $thing
        }
    }

    $conditions = $temp

    $temp = @()
    foreach ($thing in $operators){
        if (-not ($thing -eq "")){
            $thing = ($thing -replace "\s", "")
            $temp += $thing
        }
    }

    $operators = $temp

    for ($i = 0; $i -lt $conditions.Length; $i++){
        $condition = $conditions[$i]
        if (contains $condition){
            $conditions[$i] = getValue $condition
        }
        elseif ($condition[0] -eq "'" -and $condition[$condition.Length - 1] -eq "'") {
            #TODO add string comparisons...
        }
        else{
            try {
                $conditions[$i] = [int]($condition.Trim())
            }
            catch {
                raiseErr 3
            }
        }
    }

    $value = $false

    if ($operators[0] -eq ">"){
        $value = $conditions[0] -gt $conditions[1]
    }
    elseif ($operators[0] -eq ">="){
        $value = $conditions[0] -ge $conditions[1]
    }
    elseif ($operators[0] -eq "<"){
        $value = $conditions[0] -lt $conditions[1]
    }
    elseif ($operators[0] -eq "<="){
        $value = $conditions[0] -le $conditions[1]
    }
    elseif ($operators[0] -eq "=="){
        $value = $conditions[0] -eq $conditions[1]
    }

    return $value
}

function writeVars{
    foreach ($var in $variables){
        Write-Host $var
    }
}

function getValue{
    param(
        [string]$name
    )

    $name = $name -replace "\s", ""

    foreach($var in $variables){
        if ($var.Name -eq $name){
            return $var.Value
        }
    }
}

function changeVar{
    param(
        [string]$varName,
        $value
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
}

function contains {
    param(
        [string]$split
    )

    $split = $split -replace "\s", ""

    foreach($var in $variables){
        if ($var.Name -eq $split){
            return $true
        }
    }

    return $false
}