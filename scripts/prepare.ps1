###########################################################
# WiiRec Rewrite - https://github.com/froschgrosch/wiirec #
# Licensed under GNU GPLv3. - File: prepare.ps1           #
###########################################################

# === FUNCTIONS ===
# ...

# === INITIALIZATION ===
Write-Output '=== WiiRec Rewrite ==='

. .\functions.ps1
$config = Get-Config
# $games = Get-Games

# Create session
$session = New-Object -TypeName 'PSObject'
    
Add-NewProperty $session 'time'
Add-ToObject $session.time 'start' (Get-Date -UFormat '%Y-%m-%d %H-%M-%S')

Add-ToObject $session 'list' @()
:getRecordings foreach($file in (Get-ChildItem $config.path.record | Where-Object -Property 'Extension' -EQ '.json')){
    if ($file.name.EndsWith('.skip.json')){ #exclude file from list
        Write-Output "Skipping file ""$($file.name)""..."
        continue :getRecordings
    }

    if (Test-Path -PathType Leaf -Path ($config.path.output + '\' + $file.name.Replace('.json','.*'))){ 
        Write-Output """$($file.name.Replace('.json',''))"" has already been transcoded at some point."
        if (-not (Confirm-YN 'Do you want to transcode it again?')) {
            continue :getRecordings
        } else {
            Remove-Item ($config.path.output + '\' + $file.name.Replace('.json','.*'))
        }
    }

    $rec = New-Object -TypeName 'PSObject'
    Add-ToObject $rec 'name' $file.Name.Replace('.json','')

    Write-Output "Adding file ""$($file.name)""..."
    $session.list += $rec
}
Write-Session
