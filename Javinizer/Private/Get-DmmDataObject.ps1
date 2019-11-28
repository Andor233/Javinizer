function Get-DmmDataObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Id
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        $movieDataObject = @()
    }

    process {
        # ! Current limitation: relies on the video being available on R18.com to generate the DMM link
        $r18Url = Get-R18Url -Id $Id
        $r18Id = (($r18Url -split 'id=')[1] -split '\/')[0]
        $dmmUrl = 'https://www.dmm.co.jp/digital/videoa/-/detail/=/cid=' + $r18Id
        Write-Debug "[$($MyInvocation.MyCommand.Name)] R18 ID is: $r18Id"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] DMM url is: $dmmUrl"

        if ($null -ne $dmmUrl) {
            try {
                $webRequest = Invoke-WebRequest -Uri $dmmUrl
            } catch {
                throw $_
            }

            $movieDataObject = [pscustomobject]@{
                Url           = $dmmUrl
                ContentId     = Get-DmmContentId -WebRequest $webRequest
                Title         = Get-DmmTitle -WebRequest $webRequest
                Description   = Get-DmmDescription -WebRequest $webRequest
                Date          = Get-DmmReleaseDate -WebRequest $webRequest
                Year          = Get-DmmReleaseYear -WebRequest $webRequest
                Length        = Get-DmmLength -WebRequest $webRequest
                Director      = Get-DmmDirector -WebRequest $webRequest
                Maker         = Get-DmmMaker -WebRequest $webRequest
                Label         = Get-DmmLabel -WebRequest $webRequest
                Series        = Get-DmmSeries -WebRequest $webRequest
                Rating        = Get-DmmRating -WebRequest $webRequest
                Actress       = Get-DmmActress -WebRequest $webRequest
                Genre         = Get-DmmGenre -WebRequest $webRequest
                CoverUrl      = Get-DmmCoverUrl -WebRequest $webRequest
                ScreenshotUrl = Get-DmmScreenshotUrl -WebRequest $webRequest
            }
        }

        $movieDataObject | Format-List | Out-String | Write-Debug
        Write-Output $movieDataObject
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}

function Get-DmmContentId {
    param (
        [object]$WebRequest
    )

    process {
        $contentId = ((($WebRequest.Content -split '<td align="right" valign="top" class="nw">品番：<\/td>')[1] -split '<\/td>')[0] -split '<td>')[1]
        $contentId = Convert-HtmlCharacter -String $contentId
        Write-Output $contentId
    }
}

function Get-DmmTitle {
    param (
        [object]$WebRequest
    )

    process {
        $title = (($WebRequest.Content -split '<h1 id="title" class="item fn">')[1] -split '<\/h1>')[0]
        $title = Convert-HtmlCharacter -String $title
        Write-Output $title
    }
}

function Get-DmmDescription {
    param (
        [object]$WebRequest
    )

    process {
        $description = (($WebRequest.Content -split '<meta name="description" content=')[1] -split '\/>')[0]
        # Remove the first 14 characters of the description string
        # This will remove the 'Fanza' string prepending the description in the html
        $description = $description.Substring(14)
        # Remove the last 2 characters of the description string
        # This will remove the extra quotation mark at the end of the description
        $description = $description.Substring(0, $description.Length - 2)
        Write-Output $description
    }
}

function Get-DmmReleaseDate {
    param (
        [object]$WebRequest
    )

    process {
        $releaseDate = ((($WebRequest.Content -split '<td align="right" valign="top" class="nw">配信開始日：<\/td>')[1] -split '<\/td>')[0] -split '<td>')[1]
        $releaseDate = Convert-HtmlCharacter -String $releaseDate
        $year, $month, $day = $releaseDate -split '/'
        $releaseDate = Get-Date -Year $year -Month $month -Day $day -Format "yyyy-MM-dd"
        Write-Output $releaseDate
    }
}

function Get-DmmReleaseYear {
    param (
        [object]$WebRequest
    )

    process {
        $releaseYear = Get-DmmReleaseDate -WebRequest $WebRequest
        $releaseYear = ($releaseYear -split '-')[0]
        Write-Output $releaseYear
    }
}

function Get-DmmLength {
    param (
        [object]$WebRequest
    )

    process {
        $length = ((($WebRequest.Content -split '<td align="right" valign="top" class="nw">収録時間：<\/td>')[1] -split '<\/td>')[0] -split '<td>')[1]
        $length = ($length -split '分')[0]
        Write-Output $length
    }
}

function Get-DmmDirector {
    param (
        [object]$WebRequest
    )

    process {
        $director = ((($WebRequest.Content -split '監督：<\/td>')[1] -split '<\/a>')[0] -split '>')[2]
        $director = Convert-HtmlCharacter -String $director

        if ($director -eq '</tr') {
            $director = $null
        }

        Write-Output $director
    }
}

function Get-DmmMaker {
    param (
        [object]$WebRequest
    )

    process {
        $maker = ((($WebRequest.Content -split '<td align="right" valign="top" class="nw">メーカー：<\/td>')[1] -split '<\/a>')[0] -split '>')[2]
        $maker = Convert-HtmlCharacter -String $maker
        Write-Output $maker
    }
}

function Get-DmmLabel {
    param (
        [object]$WebRequest
    )

    process {
        $label = ((($WebRequest.Content -split '<td align="right" valign="top" class="nw">レーベル：<\/td>')[1] -split '<\/a>')[0] -split '>')[2]
        $label = Convert-HtmlCharacter -String $label
        Write-Output $label
    }
}

function Get-DmmSeries {
    param (
        [object]$WebRequest
    )

    process {
        $series = ((($WebRequest.Content -split '<td align="right" valign="top" class="nw">シリーズ：<\/td>')[1] -split '<\/a>')[0] -split '>')[2]
        $series = Convert-HtmlCharacter -String $series

        if ($series -eq '</tr') {
            $series = $null
        }

        Write-Output $series
    }
}

function Get-DmmRating {
    param (
        [object]$WebRequest
    )

    process {
        $rating = (((($WebRequest.Content -split '<p class="d-review__average">')[1] -split '<\/strong>')[0] -split '<strong>')[1] -split '点')[0]
        # Multiply the rating value by 2 to conform to 1-10 rating standard
        $integer = [int]$rating * 2
        $rating = $integer.Tostring()
        Write-Output $rating
    }
}

function Get-DmmActress {
    param (
        [object]$WebRequest
    )

    begin {
        $actressArray = @()
    }

    process {
        $actressHtml = ((($WebRequest.Content -split '出演者：<\/td>')[1] -split '<\/td>')[0] -split '<span id="performer">')[1]
        $actressHtml = $actressHtml -replace '<a href="\/digital\/videoa\/-\/list\/=\/article=actress\/id=(.*)\/">', ''
        $actressHtml = $actressHtml -split '<\/a>', ''

        foreach ($actress in $actressHtml) {
            $actress = Convert-HtmlCharacter -String $actress
            if ($actress -ne '') {
                $actressArray += $actress -replace '<\/a>', ''
            }
        }

        Write-Output $actressArray
    }
}

function Get-DmmGenre {
    param (
        [object]$WebRequest
    )

    begin {
        $genreArray = @()
    }

    process {
        $genre = (((($WebRequest.Content -split 'ジャンル：<\/td>')[1] -split '<\/td>')[0] -split '<td>')[1] -split '">')
        $genre = ($genre -replace '<\/a>', '') -replace '&nbsp;&nbsp;', ''
        $genre = $genre -replace '<a href="\/digital\/videoa\/-\/list\/=\/article=keyword\/id=(.*)\/'

        foreach ($entry in $genre) {
            $entry = Convert-HtmlCharacter -String $entry
            if ($entry -ne '') {
                $genreArray += $entry
            }
        }

        Write-Output $genreArray
    }
}

function Get-DmmCoverUrl {
    param (
        [object]$WebRequest
    )

    process {
        $coverUrl = ((($WebRequest.Content -split '<div class="center" id="sample-video">')[1] -split '" target')[0] -split '<a href="')[1]
        $coverUrl = Convert-HtmlCharacter -String $coverUrl
        Write-Output $coverUrl
    }
}

function Get-DmmScreenshotUrl {
    param (
        [object]$WebRequest
    )

    begin {
        $screenshotUrl = @()
    }

    process {
        $screenshotUrl = $WebRequest.Images | Where-Object { $_.src -like 'https://pics.dmm.co.jp/digital/video/*' -and $_.id -notlike 'package-src-*' }
        $screenshotUrl = $screenshotUrl.'src'
        Write-Output $screenshotUrl
    }
}
