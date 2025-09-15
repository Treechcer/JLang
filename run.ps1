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
        doVars
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

        writeVars "$rightSide"

        if (contains $rightSide $variables){
            $value = getValue $rightSide $variables
            writeVars "contejns"
        }
        elseif ($rightSide -match "[\+\-\*/]") {
            $rightSideSplit -split("[\+\-\*/]")

            $val = Invoke-Expression $rightSide

            writeVars "6554545454"
        }
        else{
            $val = $rightSide
            writeVars "faifnhoafpganhbuiog"
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