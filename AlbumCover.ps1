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
        $Setting.Width = 900
        $Setting.Height = 120
        $Setting.Font = 'Arial'
    }
    
    process {
        $Art = New-Object ImageMagick.MagickImage($ImagePath)
        $caption = New-Object ImageMagick.MagickImage("caption:$Text", $Setting)

        $Art.Composite($caption, 0, 0, [ImageMagick.CompositeOperator]::Over)
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
    $bandName

    # Clean or regenerate Band name here.

    $ArtFile = New-TemporaryFile
    Write-Host "Downloading cover art..."
    #$ProgressPreference = 'SilentlyContinue'    
    Invoke-RestMethod -Uri $unsplashUri -OutFile $ArtFile.Fullname
    #$ProgressPreference = 'Continue'

    # Magic
    $ArtWithText = Write-TextOnImage -ImagePath $ArtFile.Fullname -Text $bandName
    $ArtWithText.Write("c:\temp\art.png")
    & "c:\temp\art.png"

    #$imageShowJob = Show-Image -Path $ArtFile.Fullname -title $bandName

}