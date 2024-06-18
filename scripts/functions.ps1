# WiiRec Rewrite - https://github.com/froschgrosch/wiirec
function YNquery($prompt){ # Do a yes/no query and return $true/$false 
    do { 
        $msgboxResult = Read-Host "$prompt (y/n) "
    } while(-not @('y','n').Contains($msgboxResult))

    return $msgboxResult -eq 'y'
}

function Test-Folder ($path) {
    if (-not (Test-Path $path)){
        Write-Host "The folder ""$path"" does not exist."
        pause
        exit 1
    } 
}

function Test-File ($path) {
    if (-not (Test-Path -PathType leaf $path)){
        Write-Host "The file ""$path"" does not exist."
        pause
        exit 1
    } 
}

function Read-Json ($inputPath) {
    return Get-Content $inputPath | ConvertFrom-Json
}

function Write-Json ($inputObject, $outputPath){
    ConvertTo-Json -InputObject $inputObject | Out-File $outputPath
}

function Add-ToObject ($inputObject, $name, $value){
    Add-Member -Force -InputObject $inputObject -MemberType NoteProperty -Name $name -Value $value
}