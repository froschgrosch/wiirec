$games = 'Mario Kart Wii', 'New Super Mario Bros Wii', 'Super Mario Galaxy 2', 'Wii: Party', 'Wii: Play Motion'
$gamesShortened = 'MKWii', 'NSMBW', 'SMG2', 'WiiParty', 'WiiMotion'

$modes = '60fps copy', '30fps copy', '30fps x264 medium crf21'

$outputPath = 'G:\record' # without backslash!


# Select Game
#Write-Host '0 : Manuell aufnehmen'

$i = 1
foreach($game in $games){
    Write-Host "$i : $game"
    $i++   
}

do {
    $sel = [int]$(Read-Host -Prompt 'Spiel ausw�hlen')
} while (-not (1 .. ($games.Length)).Contains($sel))
$sel -= 1
#Write-Output $sel ' '


# Select Mode

$i = 1
foreach($mode in $modes){
    Write-Host "$i : $mode"
    $i++   
}

do {
    $selMode = [int]$(Read-Host -Prompt 'Modus ausw�hlen')
} while (-not (1 .. ($modes.Length)).Contains($selMode))
#Write-Output $selMode ' '

$filename = Get-Date -UFormat '%Y-%m-%d_%H-%M-%S'
$filename += "-m$selMode-"
$filename += $gamesShortened[$sel]


Write-Output ' ' "Recording now to $filename. Press q to stop." ' '
switch ($selMode) {
    1 { # 60fps copy
        ./ffmpeg.exe -hide_banner -y -f dshow -video_size 640x480 -framerate 60 -sample_rate 48k -i video="USB Video":audio="Eingang (Realtek High Definition Audio)" -c copy "$outputPath\$filename.mkv"    
    }

    2 { # 30fps copy
        ./ffmpeg.exe -hide_banner -y -f dshow -video_size 640x480 -framerate 30 -sample_rate 48k -pixel_format yuyv422 -i video="USB Video":audio="Eingang (Realtek High Definition Audio)" -c copy "$outputPath\$filename.mkv"
    }
    
    3 { # 30fps x264 medium crf21
        ./ffmpeg.exe -hide_banner -y -f dshow -video_size 640x480 -framerate 30 -sample_rate 48k -pixel_format yuyv422 -i video="USB Video":audio="Eingang (Realtek High Definition Audio)" -c:v libx264 -crf:v 21 -tune:v animation -preset:v medium -c:a libopus -b:a 64k -aspect 16:9 "$outputPath\$filename.mp4"
    }
}

pause