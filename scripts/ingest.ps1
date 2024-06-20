###########################################################
# WiiRec Rewrite - https://github.com/froschgrosch/wiirec #
# Licensed under GNU GPLv3. - File: ingest.ps1            #
###########################################################

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
