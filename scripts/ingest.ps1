$inputPath = 'D:\Simon\WiiRec1'
$outputPath = 'C:\WiiRec\out'

$games = Get-Content .\data\games.json | ConvertFrom-Json

if (-not (Test-Path $outputPath)){
    Write-Host 'The specified output path does not exist.' $outputPath
    pause
    exit 1
} 
elseif (-not (Test-Path $outputPath)){
    Write-Host 'The specified output path does not exist.' $outputPath
    pause
    exit 1
}

:fileloop foreach ($f in Get-ChildItem $inputPath) {
    $name = $f.Name
    $newName = $f.Name.Replace('-m','_m').Remove(20,3).Replace('.mkv','.mp4')

    $host.ui.RawUI.WindowTitle = "Encoding $newName"

    $crop = $games | Where-Object shortName -eq $name.Substring(23).Replace('.mkv','')
    $crop = $crop.crop

    switch ($f.Name.Substring(20,2)){
        'm1' { # 60fps copy
            ffmpeg -y -i "$inputPath\$name" -c:v libx264 -tune:v animation -crf:v 21 -preset:v medium -c:a libopus -b:a 64k -aspect 16:9 -movflags +faststart ".\ingest_temp\$newName"
        }
        'm2' { # 30fps copy
            ffmpeg -y -i "$inputPath\$name" -c:v libx264 -tune:v animation -crf:v 20 -preset:v medium -c:a libopus -b:a 64k -aspect 16:9 -movflags +faststart ".\ingest_temp\$newName"
        }

        'm4' { # 60fps FFV1 FLAC
             ffmpeg -y -i "$inputPath\$name" -c:v libx264 -tune:v animation -crf:v 21 -preset:v medium -c:a aac -b:a 128k -aspect 16:9 -vf "crop=$crop" -movflags +faststart ".\ingest_temp\$newName"           
        }
        'm5' { # 30fps FFV1 FLAC
             ffmpeg -y -i "$inputPath\$name" -c:v libx264 -tune:v animation -crf:v 20 -preset:v medium -c:a aac -b:a 128k -aspect 16:9 -vf "crop=$crop" -movflags +faststart ".\ingest_temp\$newName"           
        }
        
        'm3' {
            Move-Item "$inputPath\$name"
            continue :fileloop
        }
    }
    Move-Item ".\ingest_temp\$newName" "$outputPath\$newName"
    #Remove-Item "$inputPath\$name"
}

$host.ui.RawUI.WindowTitle = 'Encoding finished'
pause
