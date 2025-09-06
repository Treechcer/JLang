. ./err.ps1

function parse{
    param(
        [string]$file,
        [PSCustomObject]$variables
    )
    $JSON = Get-Content -Path "$file" -Raw | ConvertFrom-Json
    #$variables
    foreach ($lineRaw in $JSON.RUN){

        $line = $lineRaw -replace "\s", ""

        $split = $line.split("=")[0]
        $val = $line.split("=")[1]
        $varExists = contains $split
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

                $operators
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
                    $lineRaw.IF.CONDITION

                    $conditions = [string]$lineRaw.IF.CONDITION -split "[\<\><=>=]"
                    "SA"
                    $conditions

                    $temp = @()
                    foreach ($thing in $conditions){
                        if (-not ($thing -eq "")){
                            $thing = $thing -replace "\s", ""
                            $temp += $thing
                        }
                    }

                    $conditions = $temp
                    
                    ##TODO FINISH THIS PART

                    foreach($condition in $conditions){

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

    writeVars
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

    foreach($var in $variables){
        if ($var.Name -eq $split){
            return $true
        }
    }

    return $false
}