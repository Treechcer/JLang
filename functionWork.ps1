function checkFunction {
    param (
        $name
    )

    foreach ($f in $global:functions){
        if ($f.NAME -eq $name){
            return $true
        }
    }
    
    return $false
}

function getIndex {
    param (
        $name
    )
    
    $counter = 0

    foreach ($f in $global:functions){
        if ($f.NAME -eq $name){
            return $counter
        }
        $counter++
    }
}