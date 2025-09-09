param(
    [string]$file = "code.json"
)


$global:version = "0.6.1"

. .\init.ps1
. .\run.ps1

$file = [string]$file
$valid = $false

for ($i = 0; $i -lt $file.Length; $i++){
    try {
        if ($($file[$i]) -eq "."){
            if (($file[$i + 1].ToString().ToLower() -eq "j") -and ($file[$i + 2].ToString().ToLower() -eq "s") -and ($file[$i + 3].ToString().ToLower() -eq "o") -and ($file[$i + 4].ToString().ToLower() -eq "n") -and (Test-Path -Path $file)){
                $valid = $true
                break
            }
        }
    }
    catch {
        break
    }

}

if (-not (Test-Path -Path "STD.json")){
    raiseErr 4
}

if (-not $valid){
    Write-Host "You have to parse JSON in not other formats + file that exists"
}
else {
    $variables = initV "$file"

    $JSON = Get-Content -Path "$file" -Raw | ConvertFrom-Json

    $functions = @()

    foreach($import in $JSON.IMPORT){
        $functions += initF "$import.json"
    }

    $functions += initF "$file"

    #$variables.GetType()

    parse "$file" $variables $functions
}