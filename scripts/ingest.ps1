###########################################################
# WiiRec Rewrite - https://github.com/froschgrosch/wiirec #
# Licensed under GNU GPLv3. - File: ingest.ps1            #
###########################################################

# === FUNCTIONS ===
# ...

# === INITIALIZATION ===
Write-Output '=== WiiRec Rewrite ==='

. .\functions.ps1
$config = Get-Config
$games = Get-Games
