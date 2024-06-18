# === INITIALIZATION ===

./functions.ps1
Test-File .\data\config.json
$config = Get-Content .\data\config.json | ConvertFrom-Json

Test-Folder $config.path.ingest
Test-Folder $config.path.output
