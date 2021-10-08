# Encoding should be UTF8 with BOM to support emojicons.


function Show-Image {
    param(
      [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=0)][String]$path,
      [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, Position=1)][String]$title = "Image Viewer"
    )
    #cleanup
    get-job -Name "pictureViewer" -ErrorAction SilentlyContinue | Remove-Job -ErrorAction SilentlyContinue
  
      [void][reflection.assembly]::LoadWithPartialName("System.Windows.Forms")
      $file = (get-item $path)
      $img = [System.Drawing.Image]::Fromfile($file);
  
      [System.Windows.Forms.Application]::EnableVisualStyles();
      $form = new-object Windows.Forms.Form
      $form.Text = $title
      $form.Width = $img.Size.Width;
      $form.Height =  $img.Size.Height;
      $pictureBox = new-object Windows.Forms.PictureBox
      $pictureBox.Width =  $img.Size.Width + 80;
      $pictureBox.Height =  $img.Size.Height + 80;
  
      $pictureBox.Image = $img;
  
      $pictureBox.Add_click( { $null = $form.Close() } )

      $ButtonSize = 120, 26
      $Button = New-Object System.Windows.Forms.Button
      $Button.Location = New-Object System.Drawing.Size(($img.Size.Width - $ButtonSize[0] - 10), 10)
      $Button.Size = New-Object System.Drawing.Size($ButtonSize[0], $ButtonSize[1])
      $Button.Text = "Save Album Cover"

      $Button.Add_click({
        $OpenFileDialog = New-Object System.Windows.Forms.SaveFileDialog
        $OpenFileDialog.initialDirectory = [environment]::GetFolderPath("MyPictures")
        $OpenFileDialog.filename = "albumcover.png"
        $OpenFileDialog.filter = "PNG Files (*.png)| *.png"
        $SaveDialogResult = $OpenFileDialog.ShowDialog()
        
        $savePath = $OpenFileDialog.filename

        if (($SaveDialogResult -ne "Cancel") -and ($savePath -ne '') -and ($savePath -ne $null)) {
            Copy-Item $path $savePath
        }
      })
    
      $form.controls.add($Button)
      $form.controls.add($pictureBox)
      $form.Add_Shown( { $form.Activate() } )
      $form.ShowDialog()
    
    #$null = Start-Job $ScriptBlock -Name "pictureViewer" -ArgumentList $path, $title
    #$null = Wait-Job -name "pictureViewer"
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

    }
    
    process {
        $hex = "#ebe9e4", "#9bbdc7", "#ccc6cf" | get-random
        #$Fill = New-Object ImageMagick.MagickColor($hex)
        $Black = New-Object ImageMagick.MagickColor("#0A0A0A")
        $White = New-Object ImageMagick.MagickColor("#EDEBEA")

        $Transparent = New-Object ImageMagick.MagickColor("Transparent")

        $font = (Get-Childitem "$PSScriptRoot/Assets/Fonts" | Get-Random).FullName

        $Art = New-Object ImageMagick.MagickImage($ImagePath)

        # Try to find average color for text background.        
        $Setting = New-Object ImageMagick.MagickReadSettings
        $Setting.TextGravity = "Center"
        #$Setting.StrokeColor = $Black
        $Setting.BackgroundColor = $Transparent
        $Setting.Width = 820
        $Setting.Height = 120
        Write-Host -f green "Font: $font"
        $Setting.Font = "$font"
        $TestCaption = New-Object ImageMagick.MagickImage("caption:$Text", $Setting)
        $TestCaption.Trim()
        $ActualTextWidth = $TestCaption.Width
        $ActualTextHeight = $TestCaption.Height
        $Xposition = (900 - $ActualTextWidth) / 2
        $GeoMetry = New-Object ImageMagick.MagickGeometry
        $GeoMetry.X = $Xposition
        $GeoMetry.Y = 40
        $GeoMetry.Height = $ActualTextHeight
        $GeoMetry.Width = $ActualTextWidth
        # Test text

        $BehindText = $Art.clone()
        $BehindText.crop($GeoMetry)
        #$BehindText.write("$PSScriptRoot/behind.png")
        $brightness = $BehindText.Statistics().Composite().Mean
        $BehindText.Resize(1,1)
        $BehindText.Negate()
        #$AverageBrightness = $BehindText.Statistics().Composite().Mean
        #Write-host -f cyan "brightness-diff: $($brightness - $AverageBrightness)"
        $AverageColorNegative = $BehindText.GetPixels().GetPixel(0,0).ToColor()
        #$brightness = $BehindText.Statistics().Composite().Mean

        if (($brightness -gt 30000) -and ($brightness -le 35000)) {
            $AverageColor = $Black
        }

        $Setting.FillColor = $AverageColorNegative

        $caption = New-Object ImageMagick.MagickImage("caption:$Text", $Setting)


        #$BehindText.write("$PSScriptRoot/behind.png")

        $Art.Composite($caption, 40, 60, [ImageMagick.CompositeOperator]::Over)
        #$Art.Composite($caption, 20, 40, [ImageMagick.CompositeOperator]::Difference)
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
    $Wrinkles = New-Object ImageMagick.MagickImage("$PSScriptRoot/Assets/OldCover2.png")
    $ArtWithText.Composite($Wrinkles, 50, 40, [ImageMagick.CompositeOperator]::Screen)
    
    # Add Stickers
    $stickerPath = (Get-Childitem "$PSScriptRoot/Assets/Sticker_*" | Get-Random).Fullname
    $sticker = New-Object ImageMagick.MagickImage($stickerPath)
    $sticker.BackgroundColor = $Transparent
    $sticker.Rotate((Get-Random -Minimum -10 -Maximum 10))

    # Sticker position
    $stickerX = Get-Random -Minimum 780 -Maximum 820
    $StickerY = (Get-Random -Minimum 190 -Maximum 250), (Get-Random -Minimum 760 -Maximum 820) | Get-Random
    # Place sticker
    $ArtWithText.Composite($sticker, $stickerX, $StickerY, [ImageMagick.CompositeOperator]::Over)

    if ((Get-Random -Minimum 1 -Maximum 3) -eq 1) {
        $ParenalAdvisorySticker = New-Object ImageMagick.MagickImage("$PSScriptRoot/Assets/ParenalAdvisorySticker.png")
        $ArtWithText.Composite($ParenalAdvisorySticker, 100, 801, [ImageMagick.CompositeOperator]::Over)
    }

    # Add mask
    $IMask = New-Object ImageMagick.MagickImage("$PSScriptRoot/Assets/InverseMask.png")
    $ArtWithText.Composite($IMask, 50, 40, [ImageMagick.CompositeOperator]::CopyAlpha)

    $Shadow= $ArtWithText.Clone()
    $Shadow.Shadow(0,0,2,70, (New-Object ImageMagick.MagickColor("#0A0A0A")))
    $Record = New-Object ImageMagick.MagickImage("$PSScriptRoot/Assets/VinylRecord.png")
    $RecordShadow = $Record.Clone()
    $RecordShadow.Shadow(0,0,2,70, (New-Object ImageMagick.MagickColor("#0A0A0A")))

    $Canvas.Composite($RecordShadow, 391, 61, [ImageMagick.CompositeOperator]::Over)
    $Canvas.Composite($Shadow, 16, 10, [ImageMagick.CompositeOperator]::Over)
    $Canvas.Composite($Record, 400, 61, [ImageMagick.CompositeOperator]::Over)
    $Canvas.Composite($ArtWithText, 25, 10, [ImageMagick.CompositeOperator]::Over)
    #$ArtWithText.Composite($Record, 250, 50, [ImageMagick.CompositeOperator]::DstOver)

    $OutFile = (New-TemporaryFile).FullName
    $Canvas.Write($OutFile)
    #$ArtWithText.Write("c:\temp\art.png")
    Show-Image -Path $OutFile -Title $BandName

    #$imageShowJob = Show-Image -Path $ArtFile.Fullname -title $bandName

}
