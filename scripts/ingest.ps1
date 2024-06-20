###########################################################
# WiiRec Rewrite - https://github.com/froschgrosch/wiirec #
# Licensed under GNU GPLv3. - File: ingest.ps1            #
###########################################################

# === FUNCTIONS AND CONSTANTS ===
function Write-Session{
    Write-Json $session .\data\session.json
}

Set-Variable confirmSelectionText -Option Constant -Value ('[{"name": "Confirm session"},{"name":"Inspect session"},{"name":"Exit application (Hint: This will delete the session file.)"}]' | ConvertFrom-Json)

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
if ($false -and (Test-Path -PathType Leaf .\data\session.json)) { # Read existing ingest session
    $session = Read-Json '.\data\session.json'
        
    Add-ToObject $session.time 'resumed' (Get-Date -UFormat '%Y-%m-%d %H-%M-%S')
}
else { # Create fresh session
    $session = New-Object -TypeName 'PSObject'
    
    Add-NewProperty $session 'time'
    Add-ToObject $session.time 'start' (Get-Date -UFormat '%Y-%m-%d %H-%M-%S')

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

if ($true -or $config.application.confirmSession) { ## DEBUG ## Remove $true when finished ##
    Switch ((Select-FromArray $confirmSelectionText 'Choose action' -NoExit $true)){
        0 { # Confirm

        }
        1 { # Inspect
            # TODO: start editor
            $session = Read-Session
        }
        2 { # Exit cleanly

        }
    }
}
