# Encoding should be UTF8 with BOM to support emojicons.


function Show-Image {
    param(
      [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=0)][String]$path,
      [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, Position=1)][String]$title = "Image Viewer"
    )
    #cleanup
    get-job -Name "pictureViewer" -ErrorAction SilentlyContinue | Remove-Job -ErrorAction SilentlyContinue
  
    $ScriptBlock = {
      $path = $args[0]
      $title = $args[1]
  
      [void][reflection.assembly]::LoadWithPartialName("System.Windows.Forms")
      $file = (get-item $path)
      $img = [System.Drawing.Image]::Fromfile($file);
  
      [System.Windows.Forms.Application]::EnableVisualStyles();
      $form = new-object Windows.Forms.Form
      $form.Text = $title
      $form.Width = $img.Size.Width;
      $form.Height =  $img.Size.Height;
      $pictureBox = new-object Windows.Forms.PictureBox
      $pictureBox.Width =  $img.Size.Width;
      $pictureBox.Height =  $img.Size.Height;
  
      $pictureBox.Image = $img;
  
      $pictureBox.Add_click( { $form.Close() } )
  
      $form.controls.add($pictureBox)
      $form.Add_Shown( { $form.Activate() } )
      $form.ShowDialog()
    }
    $null = Start-Job $ScriptBlock -Name "pictureViewer" -ArgumentList $path, $title
    $null = Wait-Job -name "pictureViewer"
}


function Write-HostCenter {
    param($Message)
    Write-Host ("{0}{1}" -f (' ' * (([Math]::Max(0, $Host.UI.RawUI.BufferSize.Width / 2) - [Math]::Floor($Message.Length / 2)))), $Message)
}

<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    Example of how to use this cmdlet
.EXAMPLE
    Another example of how to use this cmdlet
#>
function Write-TextOnImage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$ImagePath,
        [Parameter(Mandatory=$true)][string]$Text
    )
    
    begin {
        $hex = "#ebe9e4", "#9bbdc7", "#ccc6cf" | get-random
        $Fill = New-Object ImageMagick.MagickColor($hex)
        $Black = New-Object ImageMagick.MagickColor("#000")
        $Transparent = New-Object ImageMagick.MagickColor("Transparent")

        $font = (Get-Childitem "$PSScriptRoot/Assets/Fonts" | Get-Random).FullName

        $Setting = New-Object ImageMagick.MagickReadSettings
        $Setting.TextGravity = "Center"
        $Setting.FillColor = $Fill
        #$Setting.StrokeColor = $Black
        $Setting.BackgroundColor = $Transparent
        $Setting.Width = 860
        $Setting.Height = 120
        Write-Host -f green "Font: $font"
        $Setting.Font = "$font"
        #$Setting.Font = 'Arial', 'Arial Black', 'Impact' | Get-Random
    }
    
    process {
        $Art = New-Object ImageMagick.MagickImage($ImagePath)
        $caption = New-Object ImageMagick.MagickImage("caption:$Text", $Setting)

        #$Art.Composite($caption, 20, 40, [ImageMagick.CompositeOperator]::Over)
        $Art.Composite($caption, 20, 40, [ImageMagick.CompositeOperator]::Difference)
        #$Art.Composite($caption, 20, 40, [ImageMagick.CompositeOperator]::BumpMap)
        #  [ImageMagick.CompositeOperator]::Screen
        #
        $Art
    }
    
    end {
    }
}


if ($PSVersionTable.PSEdition -ne 'Core') {
    Write-Host "This script should be run from PWSH (Powershell Core)."
} else {
    Add-Type -Path '.\Magick.NET-Q16-AnyCPU.dll'
    $wikiUri = "https://en.wikipedia.org/api/rest_v1/page/random/summary"
    $unsplashUri = "https://source.unsplash.com/random/900x900"




    Write-Host "`n`n"
    Write-HostCenter "----------------------------"
    Write-HostCenter "👨‍🎤 Random Album Cover Generator 👩‍🎤"
    Write-HostCenter "----------------------------"
    Write-Host "`n`n"

    
    $wikiRes = Invoke-RestMethod -uri $wikiUri
    $bandName = $wikiRes.Title
    Write-Host "Wikipedia Article: $BandName"

    if ($bandName -match "olympics") {
        Write-Host "Didn't like it, regenerating band name..."
        # So many "olympics" titles. And they doesn't make good band names.
        $wikiRes = Invoke-RestMethod -uri $wikiUri
        $bandName = $wikiRes.Title
        Write-Host "Wikipedia Article: $BandName"
    }

    # Convert long names to 3 word names:
    if ($bandName.Length -gt 30) {
        $bandName = ($bandName -split " ")[0..2] -join ' '
    }

 
    # Clean or regenerate Band name here.
    $bandName  = $bandName  -replace "List\Wof\W|\W\(.+\)",""

    # Convert band name to Title Case.
    $bandName = (Get-Culture).TextInfo.ToTitleCase($bandName)

    Write-Host "Assigned band name: $bandName"


    $ArtFile = New-TemporaryFile
    Write-Host "Downloading cover art..."
    #$ProgressPreference = 'SilentlyContinue'    
    Invoke-RestMethod -Uri $unsplashUri -OutFile $ArtFile.Fullname
    #$ProgressPreference = 'Continue'

    # Magic
    # Create Canvas
    #$Canvas = New-Object ImageMagick.MagickImage("$PSScriptRoot/Assets/Canvas.png")
    $Canvas = New-Object ImageMagick.MagickImage("$PSScriptRoot/Assets/wood.png")

    # Add text to coverart
    $ArtWithText = Write-TextOnImage -ImagePath $ArtFile.Fullname -Text $bandName
    # Extend (transparent frame):
    $Transparent = New-Object ImageMagick.MagickColor("Transparent")
    $ArtWithText.Extent(1000,1000, [ImageMagick.Gravity]::Center, $Transparent)

    # Load and Add effects
    $Wrinkles = New-Object ImageMagick.MagickImage("$PSScriptRoot/Assets/OldCover.png")
    $ArtWithText.Composite($Wrinkles, 50, 40, [ImageMagick.CompositeOperator]::Screen)
    
    # Add Stickers
    $stickerPath = (Get-Childitem "$PSScriptRoot/Assets/Sticker_*" | Get-Random).Fullname
    $sticker = New-Object ImageMagick.MagickImage($stickerPath)
    $sticker.BackgroundColor = $Transparent
    $sticker.Rotate((Get-Random -Minimum -10 -Maximum 10))

    # Sticker position
    $stickerX = Get-Random -Minimum 780 -Maximum 820
    $StickerY = (Get-Random -Minimum 130 -Maximum 200), (Get-Random -Minimum 760 -Maximum 820) | Get-Random
    # Place sticker
    $ArtWithText.Composite($sticker, $stickerX, $StickerY, [ImageMagick.CompositeOperator]::Over)

    if ((Get-Random -Minimum 1 -Maximum 3) -eq 1) {
        $ParenalAdvisorySticker = New-Object ImageMagick.MagickImage("$PSScriptRoot/Assets/ParenalAdvisorySticker.png")
        $ArtWithText.Composite($ParenalAdvisorySticker, 100, 801, [ImageMagick.CompositeOperator]::Over)
    }

    # Add mask
    $IMask = New-Object ImageMagick.MagickImage("$PSScriptRoot/Assets/InverseMask.png")
    $ArtWithText.Composite($IMask, 50, 40, [ImageMagick.CompositeOperator]::CopyAlpha)

    $Record = New-Object ImageMagick.MagickImage("$PSScriptRoot/Assets/VinylRecord.png")

    $Canvas.Composite($Record, 400, 61, [ImageMagick.CompositeOperator]::Over)
    $Canvas.Composite($ArtWithText, 25, 10, [ImageMagick.CompositeOperator]::Over)
    #$ArtWithText.Composite($Record, 250, 50, [ImageMagick.CompositeOperator]::DstOver)

    $OutFile = (New-TemporaryFile).FullName
    $Canvas.Write($OutFile)
    #$ArtWithText.Write("c:\temp\art.png")
    Show-Image -Path $OutFile -Title $BandName

    #$imageShowJob = Show-Image -Path $ArtFile.Fullname -title $bandName

}
