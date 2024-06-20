############################################################
# WiiRec Rewrite - https://github.com/froschgrosch/wiirec #
# Licensed under GNU GPLv3. - File: record.ps1            #
############################################################

# === FUNCTIONS ===
function Write-RecordInfo {
    Write-Json $recordinfo ($config.path.record + '\' + $recordinfo.file.name + '.json')
}

function Test-RecordingMode ($id) {
    if ($config.skipTest.mode) { return $true }
    $arguments = '-hide_banner', '-y', '-t 1' + $config.modes.record[$id].data + "$($config.path.record)\test.mkv"

    $Env:FFREPORT = 'file=test.ff.log:level=48'
    $proc = Start-Process -PassThru -Wait -FilePath 'ffmpeg' -WindowStyle Hidden -ArgumentList $arguments -WorkingDirectory $config.path.record
    $Env:FFREPORT = ''
    
    if($success = $proc.ExitCode -eq 0) {
        Remove-Item "$($config.path.record)\test.*"
    }
    return $success
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

Add-ToObject $recordinfo 'game' $i_game
Add-ToObject $recordinfo 'mode' $i_mode
Add-ToObject $recordinfo 'recorder' $Env:USERNAME
Add-NewProperty $recordinfo 'file'
Add-ToObject $recordinfo.file 'name'  (($starttime | Get-Date -UFormat '%Y-%m-%d_%H-%M-%S_') + $games[$i_game].shortName)
Add-NewProperty $recordinfo 'time'
Add-ToObject $recordinfo.time 'start' ($starttime | Get-Date -UFormat '%Y-%m-%d %H-%M-%S')

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

Add-NewProperty $recordinfo.file 'size'
Add-ToObject $recordinfo.file.size 'raw'  (Get-Item $filepath).Length

Write-RecordInfo
if (-not $config.displayStats) { exit }

# display stats
Write-Output ' ' '=== Recording Stats ==='
Write-Output "Started at: $($recordinfo.time.start)" 
Write-Output "Stopped at: $($recordinfo.time.stop)" 
Write-Output "Duration: $($recordinfo.time.duration)"
Write-Output "Raw file size: $(Show-SizeWithSuffix $recordinfo.file.size.raw)"
Pause
