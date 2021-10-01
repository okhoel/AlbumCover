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
    Start-Job $ScriptBlock -Name "pictureViewer" -ArgumentList $path, $title
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
        $White = New-Object ImageMagick.MagickColor("#fff")
        $Black = New-Object ImageMagick.MagickColor("#000")
        $Transparent = New-Object ImageMagick.MagickColor("Transparent")

        $Setting = New-Object ImageMagick.MagickReadSettings

        $Setting.TextGravity = "Center"
        $Setting.FillColor = $White
        $Setting.StrokeColor = $Black
        $Setting.BackgroundColor = $Transparent
        $Setting.Width = 880
        $Setting.Height = 120
        $Setting.Font = 'Arial', 'Arial Black', 'Impact' | Get-Random
    }
    
    process {
        $Art = New-Object ImageMagick.MagickImage($ImagePath)
        $caption = New-Object ImageMagick.MagickImage("caption:$Text", $Setting)

        $Art.Composite($caption, 10, 20, [ImageMagick.CompositeOperator]::Over)
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

    if ($bandName -match "olympics") {
        # So many "olympics" titles. And they doesn't make good band names.
        $wikiRes = Invoke-RestMethod -uri $wikiUri
        $bandName = $wikiRes.Title
    }

    # Convert long names to 3 word names:
    if ($bandName.Length -gt 30) {
        $bandName = ($bandName -split " ")[0..2] -join ' '
    }

 
    # Clean or regenerate Band name here.
    $bandName  = $bandName  -replace "List\Wof\W|\W\(.+\)",""
    
    Write-Host "Assigned band name: $bandName"


    $ArtFile = New-TemporaryFile
    Write-Host "Downloading cover art..."
    #$ProgressPreference = 'SilentlyContinue'    
    Invoke-RestMethod -Uri $unsplashUri -OutFile $ArtFile.Fullname
    #$ProgressPreference = 'Continue'

    # Magic
    # Create Canvas
    $Canvas = New-Object ImageMagick.MagickImage("$PSScriptRoot/Assets/Canvas.png")


    # Add text to coverart
    $ArtWithText = Write-TextOnImage -ImagePath $ArtFile.Fullname -Text $bandName

    # Add clean cover to canvas
    $Canvas.Composite($ArtWithText, 50, 50, [ImageMagick.CompositeOperator]::Over)

    # Load and Add effects
    $Wrinkles = New-Object ImageMagick.MagickImage("$PSScriptRoot/Assets/OldCover.png")
    $Canvas.Composite($Wrinkles, 50, 40, [ImageMagick.CompositeOperator]::Screen)

    # Add mask
    $Mask = New-Object ImageMagick.MagickImage("$PSScriptRoot/Assets/Mask.png")
    $Canvas.Composite($Mask, 50, 40, [ImageMagick.CompositeOperator]::Over)

    $Canvas.Write("c:\temp\art.png")
    & "c:\temp\art.png"

    #$imageShowJob = Show-Image -Path $ArtFile.Fullname -title $bandName

}