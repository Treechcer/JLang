function raiseErr{
    param(
        $errMessage
    )

    Write-Host "$errMessage"
    Exit 1
}