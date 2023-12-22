$games = Get-Content .\data\games.json | ConvertFrom-Json
$modes = '60fps copy', '30fps copy', '30fps x264 medium crf21', '60fps FFV1 FLAC', '30fps FFV1 FLAC'

$outputPath = 'D:\Simon\WiiRec1' # without backslash!

# Check output folder
if (-not (Test-Path $outputPath)){
    Write-Host 'The specified output path does not exist.' $outputPath
    pause
    exit 1
}


# Select Game
$i = 1
foreach($game in $games){
    Write-Host "$i : $($game.name)"
    $i++   
}

do {
    $sel = [int]$(Read-Host -Prompt 'Spiel auswählen')
} while (-not (1 .. ($games.Length)).Contains($sel))
$sel -= 1


# Select Mode
$i = 1
foreach($mode in $modes){
    Write-Host "$i : $mode"
    $i++   
}

do {
    $selMode = [int]$(Read-Host -Prompt 'Modus auswählen')
} while (-not (1 .. ($modes.Length)).Contains($selMode))

$filename = Get-Date -UFormat '%Y-%m-%d_%H-%M-%S'
$filename += "-m$selMode-"
$filename += $games[$sel].shortName

Write-Output ' ' "Recording $($games[$sel].name) in mode $($modes[$selMode])." "Filename: $filename - Press q to stop." ' '

switch ($selMode) {
    1 { # 60fps copy
        ffmpeg -hide_banner -y -f dshow -video_size 640x480 -framerate 60 -sample_rate 48k -i video="USB Video":audio="Eingang (Realtek High Definition Audio)" -c copy "$outputPath\$filename.mkv"    
    }

    2 { # 30fps copy
        ffmpeg -hide_banner -y -f dshow -video_size 640x480 -framerate 30 -sample_rate 48k -pixel_format yuyv422 -i video="USB Video":audio="Eingang (Realtek High Definition Audio)" -c copy "$outputPath\$filename.mkv"
    }
    
    3 { # 30fps x264 medium crf21
        ffmpeg -hide_banner -y -f dshow -video_size 640x480 -framerate 30 -sample_rate 48k -pixel_format yuyv422 -i video="USB Video":audio="Eingang (Realtek High Definition Audio)" -c:v libx264 -crf:v 21 -tune:v animation -preset:v medium -c:a libopus -b:a 64k -aspect 16:9 "$outputPath\$filename.mp4"
    }

    4 { # 60fps FFV1 FLAC
        ffmpeg -hide_banner -y -f dshow -video_size 640x480 -framerate 60 -sample_rate 48k -rtbufsize 20M        -i video="USB Video":audio="Eingang (Realtek High Definition Audio)" -c:v ffv1 -c:a flac "$outputPath\$filename.mkv"    
    }

    5 { # 30fps FFV1 FLAC
        ffmpeg -hide_banner -y -f dshow -video_size 640x480 -framerate 30 -sample_rate 48k -pixel_format yuyv422 -i video="USB Video":audio="Eingang (Realtek High Definition Audio)" -c:v ffv1 -c:a flac "$outputPath\$filename.mkv"
    }
}
pause
