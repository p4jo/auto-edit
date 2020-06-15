<#
.SYNOPSIS
    Runs a new instance of auto-editor.
.DESCRIPTION
    Runs a new instance of auto-editor by using several folders.
    It also installs auto-editor if it is not present, however it still needs the user to choose the proper version of ffmpeg from a webpage.
    
    Run this file in a folder that contains the auto-editor folder or edit the default value for -Loc (Currently Line 32), or always specify -Loc.
    
    For more information see 'get-help .\auto-edit.ps1 -full'
.EXAMPLE
    .\auto-edit video.mov
.EXAMPLE
    .\auto-edit.ps1 "A:\Videos\Baum.mp4" -f 7 -p "--background-music 'C:\Users\Tree\birds.mp3' --frame_quality 5 -o 'A:\Videos\tree.mp4'"
.LINK
    .\auto-edit.ps1 a -p '-h'  # This displays the internal help of auto-editor
#>

param(
    [Parameter(Mandatory=$true, HelpMessage='The path to the video or alternatively a YouTube link')]
    #The path to the video or alternatively a YouTube link.
    [string] $path = '',

    [decimal] $fastSpeed = 8,
    [decimal] $normalSpeed = 1,
    
    #A string to be passed to auto-editor as parameter list. For example: '--loudness_threshold 0.7 --hardware_accel qsv'. Aliases: p, param, params, par
    [Alias("p","param","params","par")]
    [string] $parameters = "--hardware_accel qsv",

    #If you don't want the Youtube downloader to view an old web_download as your new video.
    [Alias("download","rd","forcedownload")]  
    [switch] $redownload = $false, 

    #The installation location. EDIT THIS FOR YOUR CONVENIENCE
    [string] $Loc = "", 

    #If you want to skip the questions during installation. You should know what you are doing.
    [switch] $install = $false

)
$yesAnswers = "y","Y","yes","Yes","ja",'j'

$oldPath = Get-Location
if(Test-Path $path) {
    $path = Resolve-Path $path
}

if ($Loc -eq '') {
    $Loc = Get-Location
}
if ($Loc.EndsWith('\')) {
    $Loc = $Loc.Remove($Loc.Length-1)
}
$Loc = $Loc + "\auto-editor"

#CHECK INSTALLATION 

while (!(Test-Path $Loc)) {
    Write-Host "The specified location $($Loc) was not found. You can specify the correct location with -Loc. Alternatively, edit this script's beginning. We can also create this folder."
    if (!$install) {
        $answer = Read-Host "Create the folder $($Loc)\ ?"
        if (!$yesAnswers.Contains($answer)) {
            Write-Host "You can always leave by (Ctrl-Break) or (Ctrl-C)"
            continue
        }
    }

    New-Item -Path $Loc -ItemType Directory >$null
}

cd $Loc

while (!(Test-Path "$($Loc)\auto-editor.py")) {
    Write-Host "The specified location $($Loc) did not contain auto-editor. You can specify the correct location with -Loc. Alternatively, edit this script's beginning. We can also try to download it."
    if (!$install) {
        $answer = Read-Host "Download auto-editor and dependencies? This requires git and python (v3) to be installed."
        if (!$yesAnswers.Contains($answer)) {
            Write-Host "You can always leave by (Ctrl-Break) or (Ctrl-C)"
            continue
        }
    }

    Write-Host "Red is not necessarily bad here:"
    #HERE THE INSTALLING HAPPENS
    git clone 'https://github.com/WyattBlue/auto-editor.git'
    Copy-Item -Path ".\auto-editor\auto-editor.py" ".\auto-editor.py" -Force
    pip3 install -r '.\auto-editor\requirements.txt'
}
while (!(Test-Path "$($Loc)\ffmpeg.exe") -or !(Test-Path "$($Loc)\ffprobe.exe")) {
    Write-Host "The specified location $($Loc) did not contain ffmpeg."
    if (!$install) {
        $answer = Read-Host "Please download ffmpeg from here: https://ffmpeg.zeranoe.com/builds/ into the default download folder. Start this webpage?"
        if ($yesAnswers.Contains($answer)) {
            start https://ffmpeg.zeranoe.com/builds/
        }
        Read-Host "When finished, press enter"
    }
    if ((Test-Path "$($Loc)\ffmpeg.exe") -and (Test-Path "$($Loc)\ffprobe.exe")) {
        break
    }
    Set-Location ~\Downloads
    $ffmpegFiles = Get-Childitem –Path .\* -Include ffmpeg*.zip -File -Recurse
    if ($ffmpegFiles -eq $null) {
        Write-Host "No ffmpeg*.zip was found in Downloads."
        continue
    }
    Write-Host "The following files were found:`n$($ffmpegFiles)"
    $answer = Read-Host "Specify your correct ffmpeg download by index (0-based). Enter anything wrong to try again or nothing to accept the first entry."

    $ffmpegFile = $ffmpegFiles[$answer]
    if (!($ffmpegFile -in $ffmpegFiles)) {
        continue
    }
    #HERE FFMPEG IS EXTRACTED
    $ffmpegFolder = "$($Loc)\ffmpegFolder\"
    Expand-Archive "$($ffmpegFile)" -DestinationPath "$($ffmpegFolder)" -Force
    Set-Location $Loc
    $ffmpegEXE = Get-Childitem -Filter ffmpeg*.exe -File -Recurse -Name
    Copy-Item $ffmpegEXE .\ -Force
    $ffmpegEXE = Get-Childitem -Filter ffprobe*.exe -File -Recurse -Name
    Copy-Item $ffmpegEXE .\ -Force
    Remove-Item $ffmpegFolder -Recurse
}

#FIND FREE FOLDER TO USE auto-editor IN

for ($i=0; $i -le 100;$i++)
{
    if (!(Test-Path "$($Loc)$($i)"))
    {
        Write-Host "New folder $($Loc)$($i)\ will be created and filled with a copy of auto-editor and ffmpeg."
        New-Item -Path "$($Loc)$($i)" -ItemType Directory >$null
        Copy-Item -Path "$($Loc)\ffmpeg.exe" -Destination "$($Loc)$($i)\ffmpeg.exe"
        Copy-Item -Path "$($Loc)\auto-editor.py" -Destination "$($Loc)$($i)\auto-editor.py"
        Copy-Item -Path "$($Loc)\ffprobe.exe" -Destination "$($Loc)$($i)\ffprobe.exe"
    }

    Set-Location "$($Loc)$($i)\"

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
Write-Host "We will start auto-editor in Location $(Get-Location) now."

Invoke-Expression "python '.\auto-editor.py' '$($path)' -s $($fastSpeed) -v $($normalSpeed) $($parameters)"

Write-Host "auto-editor finished. $(Get-Location) is open for use again"
Remove-Item 'in-progress'
Set-Location $oldPath