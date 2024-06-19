# WiiRec Rewrite - https://github.com/froschgrosch/wiirec
# === FUNCTIONS ===
function Write-RecordInfo {
    Write-Json $recordinfo ($config.path.record + '\' + $recordinfo.file.name + '.json')
}

function Test-RecordingMode ($id) {
    if ($config.skipTest.mode) { return $true }
    $filepath = "$($config.path.record)\test.mkv"
    $arguments = '-hide_banner', '-y', '-t 1' + $config.modes.record[$id].data + $filepath

    $proc = Start-Process -PassThru -Wait -FilePath 'ffmpeg' -ArgumentList $arguments
    
    if(Test-Path -PathType leaf $filepath) {
        Remove-Item $filepath
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

# test mode
if (-not (Test-RecordingMode $i_mode)) {
    Exit-Error "The selected mode ""$($config.modes.record[$i_mode].name)"" does not seem to work. Please investigate."
}

# === RECORDING ===
# set up recording information
$recordinfo = New-Object -TypeName 'PSObject'
$starttime = Get-Date

Add-ToObject $recordinfo        'game' $i_game
Add-ToObject $recordinfo        'mode' $i_mode
Add-ToObject $recordinfo        'recorder' $Env:USERNAME
Add-ToObject $recordinfo        'file' (New-Object -TypeName 'PSObject')
Add-ToObject $recordinfo.file   'name' (($starttime | Get-Date -UFormat '%Y-%m-%d_%H-%M-%S_') + $games[$i_game].shortName)
Add-ToObject $recordinfo        'time' (New-Object -TypeName 'PSObject')
Add-ToObject $recordinfo.time   'start' ($starttime | Get-Date -UFormat '%Y-%m-%d %H-%M-%S')

Write-RecordInfo

# start recording
Clear-Host
Write-Output "Recording $($games[$i_game].name) in $($config.modes.record[$i_mode].name)." "Filename: $($recordinfo.file.name) - Press q to stop." ' '

$filepath = $config.path.record + '\' + $recordinfo.file.name + '.' + $config.modes.record[$i_mode].extension
$arguments = '-hide_banner', '-y' + $config.modes.record[$i_mode].data + $filepath
$proc = Start-Process -NoNewWindow -PassThru -FilePath 'ffmpeg' -ArgumentList $arguments

# see https://learn.microsoft.com/en-us/dotnet/api/system.diagnostics.processpriorityclass?view=net-8.0
$proc.PriorityClass = $config.processPriority 
$proc.WaitForExit()

# post-recording
$stoptime = Get-Date
Add-ToObject $recordinfo.time 'stop' ($stoptime | Get-Date -UFormat '%Y-%m-%d %H-%M-%S')
Add-ToObject $recordinfo.time 'duration' (($stoptime - $starttime).ToString('hh\:mm\:ss\.ff'))

Add-ToObject $recordinfo.file      'size' (New-Object -TypeName 'PSObject')
Add-ToObject $recordinfo.file.size 'raw'  (Get-Item $filepath).Length

Write-RecordInfo
if (-not $config.displayStats) { exit }

Write-Output ' ' '=== Recording Stats ===' "Started at: $($recordinfo.time.start)" "Stopped at: $($recordinfo.time.stop)" "Duration: $($recordinfo.time.duration)"
Pause
