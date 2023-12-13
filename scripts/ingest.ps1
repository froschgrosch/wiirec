$inputPath = 'F:\record'
$outputPath = 'D:\Bibliotheken\Videos\Captures\Wii'

$files = Get-ChildItem $inputPath

foreach ($f in $files) {
    $name = $f.Name
    $newName = $f.Name.Replace('-m','_m').Remove(20,3)
    #Write-Output $f.Name
    
    switch ($f.Name.Substring(20,2)){
        'm1' {
            # ffmpeg -f dshow -video_size 640x480 -framerate 60 -sample_rate 48k -i video="USB Video":audio="Eingang (Realtek High Definition Audio)" -c copy "$outputPath\$filename.mkv"    
            ffmpeg -y -i "$inputPath\$name" -c:v libx264 -tune:v animation -crf:v 21 -preset:v medium -c:a libopus -b:a 64k -aspect 16:9 -movflags +faststart ".\ingest_temp\$newName"
            Move-Item ".\ingest_temp\$newName" "$outputPath\$newName"
            Remove-Item "$inputPath\$name"
        }
        'm2' {
            # ffmpeg -f dshow -video_size 640x480 -framerate 30 -sample_rate 48k -pixel_format yuyv422 -i video="USB Video":audio="Eingang (Realtek High Definition Audio)" -c copy "$outputPath\$filename.mkv"
            ffmpeg -y -i "$inputPath\$name" -c:v libx264 -tune:v animation -crf:v 20 -preset:v medium -c:a libopus -b:a 64k -aspect 16:9 -movflags +faststart ".\ingest_temp\$newName"
            Move-Item ".\ingest_temp\$newName" "$outputPath\$newName"
            Remove-Item "$inputPath\$name"
        }
        'm3' {
            Move-Item "$inputPath\$name"
        }
    }
}
Pause