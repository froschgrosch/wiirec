# WiiRec Rewrite - https://github.com/froschgrosch/wiirec
# === FUNCTIONS ===
function Write-Info {
    Write-Json  $recordinfo "$($config.path.record)\\$filename.json"
}

function Test-Mode ($id) {
    $env:FFREPORT = '' # 'file=C:/Users/Simon/Downloads/wiirectest/rec/ffreport.log:level=32'

    $arguments = "-hide_banner", "-y", "-t 1" + $config.modes.record[$id].data + "$($config.path.record)\test.mkv"

    $proc = Start-Process -PassThru -Wait -FilePath "ffmpeg" -ArgumentList $arguments
    
    return $proc
}
 
# === INITIALIZATION ===
./functions.ps1
Test-File .\data\config.json
$config = Read-Json .\data\config.json

Test-File .\data\games.json
$games = Read-Json .\data\games.json

Test-Folder $config.path.record

# test modes


# set up recording information
$recordinfo = New-Object -TypeName 'PSObject'

$filename = (Get-Date -UFormat '%Y-%m-%d_%H-%M-%S-') + $games[0].shortName
Add-ToObject $recordinfo 'filename' $filename
#echo $filename

$proc = Test-Mode 0