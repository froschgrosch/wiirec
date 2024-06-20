###########################################################
# WiiRec Rewrite - https://github.com/froschgrosch/wiirec #
# Licensed under GNU GPLv3. - File: functions.ps1         #
###########################################################

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

function Add-NewProperty ($inputObject, $name){
    Add-ToObject $inputObject -name $name -value (New-Object -TypeName 'PSObject')
}

function Select-FromArray {
    Param (
        [Parameter(Mandatory=$true)] $arr,
        [Parameter(Mandatory=$true)] [String]$prompt,
        [Parameter(Mandatory=$false)] $ValidSelections = 0 .. ($arr.Length - 1),
        [Parameter(Mandatory=$false)] $NoExit = $false
    )  <# The selection index that is displayed to the user starts at 1, 
        # while the index returned by this function starts at 0. #>

    ## TODO ##
    # Fix error action that appears when entering non-numbers.
    
    $i = 1
    foreach($element in $arr){
        if ($validSelections.Contains($i - 1) -and -not $element.hide){
            Write-Host "$i`: $($element.name)"
        }
        $i++   
    }

    if (-not $noexit) {
        Write-Host "c: Exit program"
    }

    do {
        $sel = Read-Host -Prompt $prompt
        if ($sel -eq 'c' -and -not $noexit) { exit 0 }
    } while (-not $validSelections.Contains([int]$sel - 1))

    return $sel - 1
}

function Exit-Error {
    Param (
        [Parameter(Mandatory=$true)]  [String]$text,
        [Parameter(Mandatory=$false)] [int]$code = 1
    )

    Write-Output '=!= An Error has occurred. =!=' $text
    Pause # so that the user can read it
    exit $code
}

function Debug-Selection {
    Write-Output "DEBUG: Game $i_game (""$($games[$i_game].name)"")" 
    "DEBUG: Mode $i_mode (""$($config.modes.record[$i_mode].name)"")" 
}

function Show-SizeWithSuffix($num) # https://stackoverflow.com/a/40887001
{
    $suffix = "B", "KB", "MB", "GB", "TB"
    $index = 0
    while ($num -gt 1kb) {
        $num = $num / 1kb
        $index++
    } 
    "{0:N0} {1}" -f $num, $suffix[$index]
}
