<#
.SYNOPSIS
    Runs a new instance of auto-editor.
.DESCRIPTION
    Runs a new instance of auto-editor by using several folders.
    It also installs auto-editor if it is not present, however it still needs the user to choose the proper version of ffmpeg from a webpage.
    
    Run this file in a folder that contains the auto-editor folder or edit the default value for -Loc (Currently Line 46), or always specify -Loc.
    
    For more information see 'get-help .\auto-edit.ps1 -full'
.EXAMPLE
    .\auto-edit video.mov
.EXAMPLE
    .\auto-edit.ps1 ".\Videos\Baum.mp4" -f 7 -p "--background-music 'C:\Users\Tree\birds.mp3' --frame_quality 5" -o '~\tree.mp4'
.LINK
    .\auto-edit.ps1 a -p '-h'  # This displays the internal help of auto-editor
#>

param(
    [Parameter(Mandatory=$true, HelpMessage='The path to the video or alternatively a YouTube link')]
    #The path to the video or alternatively a YouTube link. Mandatory argument.
    [string] $path = '',

    #The path of the output video. Aliases: o, out, out-path, out_path, outPath, output-file, output_file, outputFile
    [Alias('o','out', "out-path","out_path", "output-file", "output_file", "outputFile")]
    [string] $outPath = '',

    #Aliases: silent_speed, silentSpeed, silent-speed,f, s, fast_speed, fast-speed, fastSpeed
    [Alias("silent_speed","silentSpeed","silent-speed","f","s","fast_speed","fast-speed")]
    [decimal] $fastSpeed = 8,
    
    #Aliases : video_speed, videoSpeed, video-speed, normal-speed, normal_speed, loud_speed, loud-speed, loudSpeed, ls, n, ns, v
    [Alias("video_speed","videoSpeed","video-speed", "normal-speed", "normal_speed", "loud_speed", "loud-speed", "loudSpeed" ,"ls","n","ns","v")]
    [decimal] $normalSpeed = 1,
    
    #A string to be passed to auto-editor as parameter list. For example: '--loudness_threshold 0.7 --hardware_accel qsv'. Paths must be absolute. Aliases: p, param, params, par
    [Alias("p","param","params","par")]
    [string] $parameters = "--hardware_accel qsv",

    #If you don't want the Youtube downloader to view an old web_download as your new video. Aliases: download, rd, forceDownload, reDownload
    [Alias("download","rd","forceDownload")]  
    [switch] $redownload = $false, 

    #The installation location. EDIT THIS FOR YOUR CONVENIENCE. Aliases: Location, Loc, install_folder, installFolder, install-folder
    [Alias("Location", "install_folder", "installFolder", "install-folder")]
    [string] $Loc = "A:\VS Projekte\Jumpcutter", 

    #If you want to skip the questions during installation. You should know what you are doing.
    [Alias("skipQuestions")]
    [switch] $install = $false

)

#Pre-stuff

$yesAnswers = "y","yes","ja",'j','oui','confirm'

$oldLocation = Get-Location

if(Test-Path $path) {
    $path = Resolve-Path $path # This makes $path independent of location it was relative before
}
if($outPath -ne '' -and (Test-Path $outPath)) {
    $outPath = Resolve-Path $outPath # This makes $outPath independent of location it was relative before
}

if ($Loc.EndsWith('\')) {
    $Loc = $Loc.Remove($Loc.Length-1) 
}
if ($Loc -eq '') {
    $Loc = "."
}

#CHECK INSTALLATION 

while ($true) {
    $response = pip3 --version
    if ($response.startsWith("pip")) {
        break    
    }
    Write-Host "You have to install python (version 3) (including the packet manager pip (pip3)) first" -ForegroundColor DarkYellow
    Write-Host "Running 'python3' should redirect you to the Microsoft Store from where you can install it."
    Write-Host "You can always leave by (Ctrl-Break) or (Ctrl-C)" -ForegroundColor Red
    Read-Host
}

while (!(Test-Path $Loc)) {
    Write-Host "The specified location $($Loc) was not found. You can specify the correct location with -Loc. Alternatively, edit this script's beginning. We can also create this folder." -ForegroundColor DarkYellow
    if (!$install) {
        $answer = Read-Host "Create the folder $($Loc)\ ?"
        if (!($yesAnswers -contains $answer)) {
            Write-Host "You can always leave by (Ctrl-Break) or (Ctrl-C)" -ForegroundColor Red
            continue
        }
    }

    New-Item -Path $Loc -ItemType Directory >$null
}

$Loc = Resolve-Path $Loc # Location was not changed before this. This makes $Loc independent of location it was relative before
$LocRep = $Loc + "\auto-editor"


Set-Location $Loc  #############################

while (!(Test-Path "$($LocRep)\auto-editor.py")) {
    Write-Host "The specified location $($Loc) did not contain auto-editor. You can specify the correct location with -Loc. Alternatively, edit this script's beginning. We can also try to download it." -ForegroundColor DarkYellow
    if (!$install) {
        $answer = Read-Host "Download auto-editor and dependencies? This requires git and python (v3) to be installed."
        if (!($yesAnswers -contains $answer)) {
            Write-Host "You can always leave by (Ctrl-Break) or (Ctrl-C)" -ForegroundColor Red
            continue
        }
    }

    Write-Host "Red is not necessarily bad here:" -ForegroundColor Gray
    
    #HERE THE INSTALLING HAPPENS
    git clone 'https://github.com/WyattBlue/auto-editor.git'
    pip3 install -r "$($LocRep)\requirements.txt"
}
while (!(Test-Path "$($LocRep)\ffmpeg.exe") -or !(Test-Path "$($LocRep)\ffprobe.exe")) {
    Write-Host "The specified location $($LocRep) did not contain ffmpeg." -ForegroundColor DarkYellow
    if (!$install) {
        $answer = Read-Host "Please download ffmpeg from here: https://ffmpeg.zeranoe.com/builds/ into the default download folder. Start this webpage?"
        if ($yesAnswers -contains $answer) {
            start https://ffmpeg.zeranoe.com/builds/
        }
        Read-Host "When finished, press enter"
    }
    if ((Test-Path "$($LocRep)\ffmpeg.exe") -and (Test-Path "$($LocRep)\ffprobe.exe")) {
        break
    }
    Set-Location ~\Downloads ############
    $ffmpegFiles = Get-Childitem –Path .\* -Include ffmpeg*.zip -File -Recurse
    if ($ffmpegFiles -eq $null) {
        Write-Host "No ffmpeg*.zip was found in Downloads." -ForegroundColor DarkYellow
        continue
    }
    Write-Host "The following files were found:"
    Write-Host $ffmpegFiles -Separator "`n" -ForegroundColor DarkBlue
    $answer = Read-Host "Specify your correct ffmpeg download by index (0-based).`nEnter anything wrong to try again or nothing to accept the first entry."

    $ffmpegFile = $ffmpegFiles[$answer]
    if (!($ffmpegFile -in $ffmpegFiles)) {
        continue
    }
    #HERE FFMPEG IS EXTRACTED
    $ffmpegFolder = "$($LocRep)\ffmpegFolder\"
    Expand-Archive $ffmpegFile -DestinationPath $ffmpegFolder -Force
    Set-Location $LocRep ##################
    $ffmpegEXE = Get-Childitem -Filter ffmpeg*.exe -File -Recurse -Name
    Copy-Item $ffmpegEXE .\ -Force
    $ffmpegEXE = Get-Childitem -Filter ffprobe*.exe -File -Recurse -Name
    Copy-Item $ffmpegEXE .\ -Force
    Remove-Item $ffmpegFolder -Recurse
}

#FIND FREE FOLDER TO USE auto-editor IN

for ($i=0; $i -le 100; $i++)
{
    if (!(Test-Path "$($LocRep)$($i)"))
    {
        Write-Host "New folder $($LocRep)$($i)\ will be created and filled with a copy of auto-editor and ffmpeg."
        New-Item -Path "$($LocRep)$($i)" -ItemType Directory >$null
        Set-Location $LocRep ###############
        $folderStructure = Get-ChildItem -Recurse -Directory -Name
        $folderStructure | ForEach-Object { #This is so that it will not recurse on itself if it somehow copies into the source folder
                New-Item -Path "$($LocRep)$($i)\$($_)" -ItemType Directory -Force >$null
            }
        $pythonFiles = Get-ChildItem -Filter "*.py" -Recurse -File -Name 
        $pythonFiles | ForEach-Object {
                Copy-Item -Path $_ -Destination "$($LocRep)$($i)\$($_)" -Force
            }
        $ffmpegFiles = Get-ChildItem -Filter "*.exe" -Recurse -File -Name 
        $ffmpegFiles | ForEach-Object {
                Copy-Item -Path $_ -Destination "$($LocRep)$($i)\$($_)" -Force
            }
    }

    Set-Location "$($LocRep)$($i)" ##############

    if ((Test-Path 'in-progress')) {
        Write-Host "Folder $(Get-Location) was skipped because another script runs there (in-progress folder exists)"
        continue # Try next number
    }
    if ($redownload -and (Test-Path '.\web_download.mp4')) {
        Write-Host "Folder $(Get-Location) was skipped because we want to keep it intact: It contained a web_download which you wanted not to reuse."
        continue
    }
    break # We have found the working folder
}

#START auto-editor IN CLOSED FOLDER

New-Item 'in-progress' -ItemType Directory >$null
Write-Host "We will now start auto-editor in location $(Get-Location)." -ForegroundColor Green

$parameters = " --silent_speed $($fastSpeed) --video_speed $($normalSpeed) $($parameters)"
if ($outPath -ne '') {
    $parameters =  " --output_file '$($outPath)' $($parameters)"
}

Invoke-Expression "python .\auto-editor.py '$($path)' $($parameters)"

Write-Host "auto-editor finished. " -ForegroundColor Green -NoNewline
Remove-Item 'in-progress'
Write-Host "$(Get-Location) is open for use again. Your video is there unless you specified an out_path."
Set-Location $oldLocation ############