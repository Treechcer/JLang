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

    if ($lineRaw -like "*=*"){
        $leftSide = ($lineRaw.split("=")[0].Trim())
        $rightSide = ($lineRaw.split("=")[1].Trim())

        $createVar = $true

        if (contains $leftSide $variables){
            $createVar = $false
        }

        if (contains $rightSide $variables){
            $value = getValue $rightSide $variables
        }
        elseif ($rightSide -match "[\+\-\*/]") {
            $val = Invoke-Expression $rightSide
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