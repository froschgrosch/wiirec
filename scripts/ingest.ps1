###########################################################
# WiiRec Rewrite - https://github.com/froschgrosch/wiirec #
# Licensed under GNU GPLv3. - File: ingest.ps1            #
###########################################################

# === FUNCTIONS AND CONSTANTS ===
function Write-Session{
    Write-Json $session .\data\session.json
}

$confirmSelectionText = ('[{"name": "Confirm session"},{"name":"Inspect session"},{"name":"Discard session"}]' | ConvertFrom-Json)

# === INITIALIZATION ===
Write-Output '=== WiiRec Rewrite ==='

. .\functions.ps1
Test-File .\data\config.json
$config = Read-Json .\data\config.json

Test-File .\data\config.json
$games = Read-Json .\data\config.json


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
