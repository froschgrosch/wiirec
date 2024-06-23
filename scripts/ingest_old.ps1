###########################################################
# WiiRec Rewrite - https://github.com/froschgrosch/wiirec #
# Licensed under GNU GPLv3. - File: ingest_old.ps1        #
###########################################################

# === FUNCTIONS AND CONSTANTS ===
function Write-Session{
    Write-Json $session .\data\session.json
}

$confirmSelectionText = ('[{"name": "Confirm session"},{"name":"Inspect session"},{"name":"Discard session"}]' | ConvertFrom-Json)

# === INITIALIZATION ===
Write-Output '=== WiiRec Rewrite ==='

. .\functions.ps1
$config = Get-Config
$games = Get-Games

$directOutput = $true
Test-Folder $config.path.output

# Only use a temporary ingest path for transcoding if the property has been set in the config.
# Otherwise, transcode directly in the output path. Useful to minimize disk wear on the output drive.
if ($config.path.ingest){ 
    Test-Folder $config.path.ingest
    $directOutput = $false
}

# === RESUME / CREATE SESSION ===
if (Test-Path -PathType Leaf .\data\session.json) { # Read existing ingest session
    $session = Read-Json '.\data\session.json'
        
    Add-ToObject $session.time 'resumed' (Get-Date -UFormat '%Y-%m-%d %H-%M-%S')
    Write-Output "Resuming session from $($session.time.start)..."
}
else { # Create fresh session
    $session = New-Object -TypeName 'PSObject'
    
    Add-NewProperty $session 'time'
    Add-ToObject $session.time 'start' (Get-Date -UFormat '%Y-%m-%d %H-%M-%S')

    Write-Output "Creating fresh session at $($session.time.start)..."

    Add-ToObject $session 'list' @()
    :getRecordings foreach($file in (Get-ChildItem $config.path.record | Where-Object -Property 'Extension' -EQ '.json')){
        if ($file.name.EndsWith('.skip.json')){ #exclude file from list
            Write-Output "Skipping file ""$($file.name)""..."
            continue :getRecordings
        }

        $rec = New-Object -TypeName 'PSObject'
        Add-ToObject $rec 'name' $file.Name.Replace('.json','')

        Write-Output "Adding file ""$($file.name)""..."
        $session.list += $rec
    }
}
Write-Session

if ($config.confirmSession) {
    Write-Output ' '
    Switch (Select-FromArray $confirmSelectionText 'Choose action'){
        0 { # Confirm
            Write-Output ' ' 'Session has been confirmed.'
        }
        1 { # Inspect

            # rename file to make default txt editor work
            $file = Rename-Item -PassThru -Path '.\data\session.json' -NewName 'session.json.txt'
            Start-Process -Wait -FilePath $file
            Rename-Item -Path $file -NewName 'session.json'
            
            Write-Output ' ' 'Session has possibly been edited. Reloading...'
            $session = Read-Json .\data\session.json
        }
        2 { # Discard session
            Remove-Item .\data\session.json
            exit
        }
    }
}

:transcodeLoop foreach($file in (Get-ChildItem $config.path.record | Where-Object -Property 'Extension' -EQ '.json')) {
    $recordinfo = Read-Json $file.FullName
    $ingestMode = $config.modes.ingest[$config.modes.record[$recordinfo.mode].ingestMode]

    Write-Output "Transcoding ""$($recordinfo.file.name)""..."
    Write-Output "Recording started at: $($recordinfo.time.start)" 
    Write-Output "Recording stopped at: $($recordinfo.time.stop)" 
    Write-Output "Record duration: $($recordinfo.time.duration)"

    ## TODO ## Add session start time

    # set default cropping (no cropping) value if necessary
    if ($null -eq $games[$recordinfo.game].crop){
        Add-ToObject $games[$recordInfo.game] 'crop' 'iw:ih:0:0'
    }

    # determine file paths
    $filepath_in = $config.path.record + '\' + $recordinfo.file.name + '.' + $config.modes.record[$recordInfo.mode].extension

    if ($directOutput) {
        $folder = $config.path.output
    } 
    else {
        $folder = $config.path.ingest
    }
    $filepath_out = $folder + '\' + $recordinfo.file.name + '.' + $ingestMode.extension
    
    # determine arguments
    $arguments = '-hide_banner', '-y', '-i' + $filepath_in + $ingestMode.data + "-vf crop=$($games[$recordinfo.game].crop)" + $filepath_out
    
    $proc = Start-Process -Wait -NoNewWindow -PassThru -FilePath 'ffmpeg' -ArgumentList $arguments

    ## TODO ## Add finished flag to session file
    ## TODO ## Add stop time to session 

    if (-not $directOutput) {
        Move-Item -Path $filepath_out -Destination ($config.path.output + '\' + $recordinfo.file.name + '.' + $ingestMode.extension)
    } 
}

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

# TODO - Remove / tag source files as finished
# TODO - Remove / archive session file
# TODO - Add error handling
