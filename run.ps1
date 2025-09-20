. ./err.ps1
. ./varWork.ps1
. ./functionWork.ps1

function parse{
    param(
        [string]$file,
        $variables,
        $functions
    )

    $global:functions = $functions

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
        if ($lineRaw -like "*=*"){
            $variables = doVars $lineRaw $variables
        }
        elseif ($lineRaw -like "*_*"){
            $variables = callFunc $lineRaw $variables
        }
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

    if ($lineRaw.NAME -eq "IF"){
        $cond = evalCondition $lineRaw.IF.CONDITION $variables

        if ($cond){
            foreach ($cml in $lineRaw.IF.CODE){
                $variables = executeCode $cml $variables
            }

            return $variables
        }

        try {
            foreach ($elseif in $lineRaw.ELSEIF){
                $cond = evalCondition $elseif.CONDITION $variables
                if ($cond){
                    foreach ($cml in $elseif.CODE){
                        $variables = executeCode $cml $variables
                    }

                    return $variables
                }
            }
        }
        catch {

        }

        try {
            foreach ($cml in $lineRaw.ELSE.CODE){
                $variables = executeCode $cml $variables
            }

            return $variables
        }
        catch {
            return $variables        
        }

        return $variables
    }
}

function callFunc {

    #-----------------------------------
    #TODO - Add WORKING fVars (function Variables)
    #     - make the variables 'disapeas' when functions ends
    #     - also make it working lol 
    #-----------------------------------

    param (
        $lineRaw,
        $variables
    )
    
    $fName = $lineRaw.split(" ")[0]
    $exists = checkFunction $fName

    if ($exists){
        #$unchangedVars = $variables

        $index = getIndex $fName 
        $fVars = @()

        $counter = 1

        if ($lineRaw.split(" ").Length-1 -ne $global:functions[$index].ARGUMENTS.Length){
            raiseErr 11
        }

        foreach ($arg in $global:functions[$index].ARGUMENTS){
            $fVars += createReturnVar $arg.NAME $lineRaw.split(" ")[$counter]
            $counter++
            #FVARS DOES NOT WORK IDK WHY I'LL FIX IT TOMORROW
        }

        Write-Host "$fVars"
        $variables += $fVars

        Write-Host "$variables"

        foreach ($l in $global:functions[$index].CODE){
            if ($l.split(" ")[0]){
                #Write-Host $l.split(" ")[0] #this is temp, I have to add function variables
            }
            $variables = executeCode $l $variables
        }
    }
    else{
        raiseErr 6
    }
}