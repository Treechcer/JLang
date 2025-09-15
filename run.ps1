. ./err.ps1
. ./varWork.ps1

function parse{
    param(
        [string]$file,
        $variables,
        $functions
    )

    $JSON = Get-Content -Path "$file" -Raw | ConvertFrom-Json
    #$variables

    foreach ($lineRaw in $JSON.RUN){

        $variables = executeCode $lineRaw $variables

    }

    writeVars $variables
}

function executeCode{
    param(
        $lineRaw,
        $variables
    )

    if ($lineRaw -is [string]){
        $variables = doVars $lineRaw $variables
    }
    elseif ($lineRaw -is [PSCustomObject]){
        checkBlockCode $variables $lineRaw
    }


    return $variables
}

function doVars{
    param(
        $lineRaw,
        $variables
    )

    if ($lineRaw -like "*=*"){
        $leftSide = ($lineRaw.split("=")[0].Trim())
        $rightSide = ($lineRaw.split("=")[1].Trim())

        $createVar = $true

        if (contains $leftSide $variables){
            $createVar = $false
        }

        if (contains $rightSide $variables){
            $val = getValue $rightSide $variables
        }
        elseif ($rightSide -match "[\+\-\*/]") { 

            $split = $rightSide -split "[\+\-\*/]"
            $ops = $rightSide -split "[^\+\-\*/]"

            $split = $split -ne ""
            $ops = $ops -ne ""

            for ($i = 0; $i -lt $split.Length; $i++){
                $split[$i] = $split[$i].Trim()
            }

            for ($i = 0; $i -lt $split.Length; $i++){
                if (contains $split[$i] $variables){
                    $split[$i] = getValue $split[$i] $variables
                }
            }

            $expr = ""

            for ($i = 0; $i -lt $ops.Length; $i++){
                $expr += [string] $split[$i] + [string] $ops[$i]
            }
            $expr += $split[$split.Length - 1]

            $val = Invoke-Expression $expr
        }
        else{
            $val = $rightSide
        }
        
        if ($createVar){
            $variables = createVar $leftSide $rightSide $variables
            return $variables
        }
        else{
            $variables = changeVar $leftSide $val $variables
            return $variables
        }
    }
}

function checkBlockCode{
    param(
        $variables,
        $lineRaw
    )

    if ($lineRaw.NAME -eq "WHILE"){
        $cond = evalCondition $lineRaw.CONDITION $variables
        while ($cond) {
            writeVars $variables
            foreach ($cml in $lineRaw.CODE){
                $variables = executeCode $cml $variables
            }
            $cond = evalCondition $lineRaw.CONDITION $variables
        }
        
        return $variables
    }
}