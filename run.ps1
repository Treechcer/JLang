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
        if (contains ($lineRaw.split("=")[0].Trim()) $variables){
            changeVar $lineRaw.split("=")[0].Trim() $lineRaw.split("=")[1].Trim() $variables
            return $variables
        }
        else{
            $variables = createVar $lineRaw.split("=")[0].Trim() $lineRaw.split("=")[1].Trim() $variables
            return $variables
        }
    }
}