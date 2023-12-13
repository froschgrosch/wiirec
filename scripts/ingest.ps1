$inputPath = 'F:\record'
$outputPath = 'D:\Bibliotheken\Videos\Captures\Wii'

$files = Get-ChildItem $inputPath

:fileloop foreach ($f in $files) {
    $name = $f.Name
    $newName = $f.Name.Replace('-m','_m').Remove(20,3).Replace('.mkv','.mp4')
    #Write-Output $f.Name
    
    switch ($f.Name.Substring(20,2)){
        'm1' { # 60fps copy
            ffmpeg -y -i "$inputPath\$name" -c:v libx264 -tune:v animation -crf:v 21 -preset:v medium -c:a libopus -b:a 64k -aspect 16:9 -movflags +faststart ".\ingest_temp\$newName"
        }
        'm2' { # 30fps copy
            ffmpeg -y -i "$inputPath\$name" -c:v libx264 -tune:v animation -crf:v 20 -preset:v medium -c:a libopus -b:a 64k -aspect 16:9 -movflags +faststart ".\ingest_temp\$newName"
        }

        'm4' { # 60fps FFV1 FLAC
             ffmpeg -y -i "$inputPath\$name" -c:v libx264 -tune:v animation -crf:v 21 -preset:v medium -c:a aac -b:a 128k -aspect 16:9 -vf "crop=609:457:18:11" -movflags +faststart ".\ingest_temp\$newName"           
        }
        'm5' { # 30fps FFV1 FLAC
             ffmpeg -y -i "$inputPath\$name" -c:v libx264 -tune:v animation -crf:v 20 -preset:v medium -c:a aac -b:a 128k -aspect 16:9 -vf "crop=609:457:18:11" -movflags +faststart ".\ingest_temp\$newName"           
        }
        
        'm3' {
            Move-Item "$inputPath\$name"
            continue :fileloop
        }
    }
    Move-Item ".\ingest_temp\$newName" "$outputPath\$newName"
    Remove-Item "$inputPath\$name"
}
pause
