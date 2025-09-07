function raiseErr{
    param(
        [int]$errCode
    )

    $errMessage = ""

    switch ($errCode) {
        1 {
            $errMessage = "you can't do 'something=' you have to add value"
        }
        2{
            $errMessage = "you can't just call variable"
        }
        3{
            $errMessage = "you have to use real variables"
        }
        4{
            $errMessage = "you don't have STD (standart) library"
        }
        5{
            $errMessage = "functions have to start with '_'"
        }
        6{
            $errMessage = "invalid function name"
        }
        Default {
            "WRONG ERROR CODE"
            Exit 1
        }
    }

    Write-Host "$errMessage"
    Exit 1
}