###########################################################
# WiiRec Rewrite - https://github.com/froschgrosch/wiirec #
# Licensed under GNU GPLv3. - File: transcode.ps1         #
###########################################################

# === FUNCTIONS ===
function Get-Session {
    Test-File .\data\session.json
    return (Read-Json .\data\session.json)
}

# === INITIALIZATION ===
Write-Output '=== WiiRec Rewrite ==='

. .\functions.ps1
$config = Get-Config
$games = Get-Games

$session = Get-Session

:transcodeLoop foreach($item in $session.list) {
    $recordinfo = Read-Json ($config.path.record + '\' + $item.name + '.json')
    $ingestMode = $config.modes.ingest[$config.modes.record[$recordinfo.mode].ingestMode]

    Write-Output "Transcoding ""$($recordinfo.file.name)""..."
    Write-Output "Recording started at: $($recordinfo.time.start)" 
    Write-Output "Recording stopped at: $($recordinfo.time.stop)" 
    Write-Output "Record duration: $($recordinfo.time.duration)"

    # add session start time
    Add-NewProperty $item 'time'
    Add-ToObject $item.time 'start' (($starttime = Get-Date) | Get-Date -UFormat '%Y-%m-%d %H-%M-%S')

    # set default cropping (no cropping) value if necessary
    if ($null -eq $games[$recordinfo.game].crop){
        Add-ToObject $games[$recordInfo.game] 'crop' 'iw:ih:0:0'
    }

    # determine file paths
    $filepath_in = $config.path.record + '\' + $recordinfo.file.name + '.' + $config.modes.record[$recordInfo.mode].extension

    $folder = $config.path.ingest
    if ($directOutput) {
        $folder = $config.path.output
    } 
    $filepath_out = $folder + '\' + $recordinfo.file.name + '.' + $ingestMode.extension
    
    # determine arguments
    $arguments = '-hide_banner', '-y', '-i' + $filepath_in + $ingestMode.data + "-vf crop=$($games[$recordinfo.game].crop)" + $filepath_out
    
    $proc = Start-Process -Wait -NoNewWindow -PassThru -FilePath 'ffmpeg' -ArgumentList $arguments

    if ($proc.ExitCode -ne 0) {
       Add-ToObject $item.time 'failure' (($stoptime = Get-Date) | Get-Date -UFormat '%Y-%m-%d %H-%M-%S')
        Write-Output "Failed to transcode ""$($recordinfo.file.name)""."
        continue :transcodeLoop
    }

    # add stop time to session 
    Add-ToObject $item.time 'stop' (($stoptime = Get-Date) | Get-Date -UFormat '%Y-%m-%d %H-%M-%S')
    Add-ToObject $item.time 'duration' (($stoptime - $starttime).ToString('hh\:mm\:ss\.ff'))
    
    Write-Session

    if (-not $directOutput) {
        Move-Item -Force -Path $filepath_out -Destination ($config.path.output + '\' + $recordinfo.file.name + '.' + $ingestMode.extension)
    } 

    if ($config.deleteSourceFiles) {
        Remove-Item ($config.path.record + '\' + $recordinfo.file.name + '.*')
        ## TODO ## archive / remove record info
    }
}

exit

Switch ($config.exit.behaviour){
    0 { # exit w/ pause
        exit
    }
    1 { # exit w/o pause
        Write-Output 'The ingestion process has finished.'
        Pause
        exit
    }
    2 { # shutdown
        shutdown -s -f -t $config.exit.shutdownTimeout -c "WiiRec Ingestion process has finished. Shutting down in $($config.exit.shutdownTimeout) seconds."
        if (YNquery('Cancel shutdown?')) { 
            shutdown -a
            Pause
        }
        exit
    }
}
