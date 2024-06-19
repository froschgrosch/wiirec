# WiiRec Rewrite - https://github.com/froschgrosch/wiirec
function Confirm-YN($prompt){ # Do a yes/no query and return $true/$false 
    do { 
        $msgboxResult = Read-Host "$prompt (y/n) "
    } while(-not @('y','n').Contains($msgboxResult))

    return $msgboxResult -eq 'y'
}

function Test-Folder ($path) {
    if (-not $config.skipTest.folder -and -not (Test-Path $path)){
        Exit-Error "The folder ""$path"" does not exist."
    } 
}

function Test-File ($path) {
    if (-not $config.skipTest.folder -and-not (Test-Path -PathType leaf $path)){
        Exit-Error "The file ""$path"" does not exist."
    } 
}

function Read-Json ($inputPath) {
    return Get-Content $inputPath | ConvertFrom-Json
}

function Write-Json ($inputObject, $outputPath){
    ConvertTo-Json -InputObject $inputObject | Out-File $outputPath
}

function Add-ToObject ($inputObject, $name, $value) {
    Add-Member -Force -InputObject $inputObject -MemberType NoteProperty -Name $name -Value $value
}

function Select-FromArray {
    Param (
        [Parameter(Mandatory=$true)] $arr,
        [Parameter(Mandatory=$true)] [String]$prompt,
        [Parameter(Mandatory=$false)] $validSelections = 0 .. ($arr.Length - 1)
    )  <# The selection index that is displayed to the user starts at 1, 
        # while the index returned by this function starts at 0. #>

    $i = 1
    foreach($element in $arr){
        if ($validSelections.Contains($i - 1)){
            Write-Host "$i`: $($element.name)"
        }
        $i++   
    }
    Write-Host "c: Exit program"

    do {
        $sel = Read-Host -Prompt $prompt
        if ($sel -eq 'c') { exit 0 }
    } while (-not $validSelections.Contains([int]$sel - 1))
    return $sel - 1
}

function Exit-Error {
    Param (
        [Parameter(Mandatory=$true)]  [String]$text,
        [Parameter(Mandatory=$false)] [int]$code = 1
    )

    Write-Host $text
    #pause
    exit $code
}

function Debug-Selection {
    Write-Output "DEBUG: Game $i_game (""$($games[$i_game].name)"")" 
    "DEBUG: Mode $i_mode (""$($config.modes.record[$i_mode].name)"")" 
}