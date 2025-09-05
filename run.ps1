. ./err.ps1

function parse{
    param(
        [string]$file,
        [PSCustomObject]$variables
    )
    $JSON = Get-Content -Path "$file" -Raw | ConvertFrom-Json
    $variables
    foreach ($line in $JSON.RUN){
        $split = $line.split("=")[0]
        if ($variables.PSObject.Properties.Name -contains $split){
            Write-Host $variables
            Write-Host "TEST $line"
            if ($line.Split("=")[1] -eq ""){
                raiseErr "error, this variable doesn't exist"
            }
            $variables.$split = $line.Split("=")[1]
            Write-Host $variables
        }
    }
}