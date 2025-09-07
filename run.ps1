. ./err.ps1

function parse{
    param(
        [string]$file,
        [PSCustomObject]$variables,
        $functions
    )
    $JSON = Get-Content -Path "$file" -Raw | ConvertFrom-Json
    #$variables
    foreach ($lineRaw in $JSON.RUN){

        executeCode $lineRaw $variables

    }

    writeVars $variables
}

function executeCode{
    param(
        $lineRaw,
        $variables
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

                $value = makeIF $lineRaw.IF.CONDITION

                if ($value){
                    foreach ($parts in $lineRaw.IF.CODE){
                        executeCode $parts
                    } 
                }
                if (-not $value -and $lineRaw.PSObject.Properties.Name -contains "ELSEIF") {
                    for ($i = 0; $i -lt $lineRaw.ELSEIF.Length; $i++){
                        $value = makeIF $lineRaw.ELSEIF[$i].CONDITION
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
            elseif ($lineRaw.PSObject.Properties.Name -contains "WHILE") {
                $value = makeIF $lineRaw.WHILE.CONDITION
                while ($value) {
                    foreach ($parts in $lineRaw.WHILE.CODE){
                        executeCode $parts
                    }
                    $value = makeIF $lineRaw.WHILE.CONDITION
                }
            }
        }

        $isNotVar = $true

        if($lineRaw[0] -eq "_"){
            $exists = $false
            $fName = $($lineRaw.split(' '))[0]
            foreach ($f in $functions){
                if ($fName -eq $f){
                    $exists = $true
                    break
                }
            }
            if (-not $exists){
                raiseErr 6
            }

            $imports = @()
            $imports += ($file.split(".")[0])
            $imports += $JSON.IMPORT

            $codeFunc = ""
            #$JSONname = ""
            $laterArgs = @()
            $passable = @{}

            foreach ($fileJ in $imports){
                $tempJSON = Get-Content -Path "$fileJ.json" -Raw | ConvertFrom-Json

                foreach ($func in $tempJSON.FUNCTIONS) {
                    foreach ($prop in $func.PSObject.Properties) {
                        if ($prop.Name -eq $fName){
                            #$JSONname = "$fileJ.json"

                            $codeFunc = $prop.Value.CODE

                            $arguments = $prop.Value.ARGUMENTS

                            $laterArgs = $arguments

                            foreach ($arg in $arguments.PSObject.Properties) {
                                $key = $arg.Name
                                $value = $arg.Value
                                $passable[$key] = $value
                            }

                            $arguments = $arguments.PSObject.Properties.Count

                            $count = 0
                            foreach($arg in $arguments){
                                $count++
                            }
                        }
                    }
                }
            }

            $vars = @()
            foreach($coder in $codeFunc){
                if (($coder.split(" ")[0]) -eq "OUT"){
                    Write-Host "test"
                }
                else{
                    $params = @()
                    $sub = $lineRaw.split(" ")

                    for ($i = 1; $i -lt $sub.Length; $i++){
                        #"------"
                        #$sub[$i]
                        #"------"

                        #$passable
                        if ($sub[$i][0] -eq "'" -and $sub[$i][$sub.Length[$i] - 1] -eq "'"){
                            $params += $sub[$i].split("'")[1]
                            
                            foreach ($prop in $laterArgs.PSObject.Properties) {

                                $types = $prop.Value.split(",")

                                for ($i = 0; $i -lt $types.Length - 1; $i++){
                                    $types[$i] = ($types[$i] -replace "\s", "")
                                }

                                if (-not ($types -contains "STR")){
                                    raiseErr 8
                                }

                                $vars += [PSCustomObject]@{
                                    Name  = $prop.Name
                                    Value = $sub[$i].split("'")[1]
                                    Type  = $prop.Value.GetType().Name
                                }
                            }
                        }
                        else{
                            if (contains ($sub[$i])){
                                $variablesTemp = @{}
                                foreach ($v in $variables) {
                                    $variablesTemp[$v.Name] = $v.Value
                                }
                                $sub[$i] = $variablesTemp[$sub[$i]]

                                #TODO MAKE THIS WORK NIFASNBFOABFOSAJD"AIGADIGBALODASKL
                            }
                            else {
                                try {
                                    $sub[$i] = [int] $sub[$i]
                                    foreach ($prop in $laterArgs.PSObject.Properties) {
                                        $types = $prop.Value.split(",")

                                        for ($y = 0; $y -lt $types.Length - 1; $y++){
                                            $types[$y] = ($types[$y] -replace "\s", "")
                                        }

                                        if (-not ($types -contains "INT")){
                                            raiseErr 8
                                        }

                                        $vars += [PSCustomObject]@{
                                            Name  = $prop.Name
                                            Value = $sub[$i]
                                            Type  = $prop.Value.GetType().Name
                                        }
                                    }
                                }
                                catch {
                                    raiseErr 3
                                }
                            }
                        }
                    }

                    executeCode $coder $vars
                }
            }
        }
        else{
            $isNotVar = $false
        }

        if (-not ($line -match "=") -and -not ($isNotVar)){
            raiseErr 2
        }

        $value = $line.Split("=")[1]
        if ($value -eq "" -and -not ($isNotVar)){
            raiseErr 1
        }
    }

    writeVars $variables
}

function makeIF {
    param(
        $CONDITION
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
    param(
        $v
    )
    foreach ($var in $v){
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