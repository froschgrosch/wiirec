# WiiRec Rewrite - https://github.com/froschgrosch/wiirec
# === FUNCTIONS ===
function Write-RecordInfo {
    Write-Json $recordinfo "$($config.path.record)\\$filename.json"
}

function Add-RecordInfo ($value, $name) {
    Add-ToObject $recordinfo $value $name
}


function Test-RecordingMode ($id) {
    if ($config.skipTest.mode) { return $true }

    $arguments = '-hide_banner', '-y', '-t 1' + $config.modes.record[$id].data + "$($config.path.record)\test.mkv"
    $proc = Start-Process -PassThru -Wait -FilePath 'ffmpeg' -ArgumentList $arguments
    
    if(Test-Path -PathType leaf "$($config.path.record)\test.mkv") {
        Remove-Item "$($config.path.record)\test.mkv"
    }
    return $proc.ExitCode -eq 0
}
 
# === INITIALIZATION ===
Write-Output '=== WiiRec Rewrite ==='

. .\functions.ps1
Test-File .\data\config.json
$config = Read-Json .\data\config.json

Test-File .\data\games.json
$games = Read-Json .\data\games.json

Test-Folder $config.path.record

# select game and mode
$i_game = Select-FromArray $games 'Select game' #(0 .. 3) ##DEBUG##
$i_mode = -1

if ($games[$i_game].modes.Length -gt 1){
    Write-Output "There are multiple valid modes availabe for the game ""$($games[$i_game].name)""." 
    $i_mode = Select-FromArray $config.modes.record 'Select mode' $games[$i_game].modes
} 
elseif ($games[$i_game].modes.Length -eq 1){
    $i_mode = $games[$i_game].modes[0]
}
else {
    Write-Output "No valid modes are availabe for the game ""$($games[$i_game].name)""." 
    if (Confirm-YN 'Do you want to select a mode manually?') {
        $i_mode = Select-FromArray 'Select mode'
    }
    else {
        exit 1
    }
}
Debug-Selection

# test mode
if (-not (Test-RecordingMode $i_mode)) {
    Exit-Error "The selected mode ""$($config.modes.record[$i_mode].name)"" does not seem to work. Please investigate."
}

# === RECORDING ===

# set up recording information
$recordinfo = New-Object -TypeName 'PSObject'

$filename = (Get-Date -UFormat '%Y-%m-%d_%H-%M-%S-') + $games[0].shortName
Add-RecordInfo $filename 'filename'
