# === INITIALIZATION ===

. .\functions.ps1
Test-File .\data\config.json
$config = Read-Json .\data\config.json

Test-File .\data\config.json
$games = Read-Json .\data\config.json

Test-Folder $config.path.ingest
Test-Folder $config.path.output
