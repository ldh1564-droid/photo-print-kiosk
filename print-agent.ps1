### 셀프 포토 프린트 에이전트 ###
# 이 스크립트를 Windows 데스크탑에서 실행하세요.
# 손님이 웹페이지에서 "프린트" 버튼을 누르면 자동으로 인쇄됩니다.

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Drawing.Printing

$siteUrl = "https://creative-naiad-54f6d9.netlify.app"
$checkInterval = 5

Write-Host ""
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "  셀프 포토 프린트 에이전트" -ForegroundColor Cyan
Write-Host "  인쇄 대기 중..." -ForegroundColor Cyan
Write-Host "  종료: Ctrl+C" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

function Print-Image {
    param([string]$FilePath)

    $bitmap = New-Object System.Drawing.Bitmap($FilePath)
    $isPortrait = $bitmap.Height -gt $bitmap.Width

    $doc = New-Object System.Drawing.Printing.PrintDocument
    $doc.DefaultPageSettings.Landscape = (-not $isPortrait)

    $handler = [System.Drawing.Printing.PrintPageEventHandler]{
        param($s, $e)
        $pw = $e.MarginBounds.Width
        $ph = $e.MarginBounds.Height
        $iw = $bitmap.Width
        $ih = $bitmap.Height
        $r = [Math]::Min($pw / $iw, $ph / $ih)
        $dw = [int]($iw * $r)
        $dh = [int]($ih * $r)
        $dx = $e.MarginBounds.X + [int](($pw - $dw) / 2)
        $dy = $e.MarginBounds.Y + [int](($ph - $dh) / 2)
        $e.Graphics.DrawImage($bitmap, $dx, $dy, $dw, $dh)
    }

    $doc.add_PrintPage($handler)
    $doc.Print()
    $doc.Dispose()
    $bitmap.Dispose()
}

while ($true) {
    try {
        $response = Invoke-RestMethod -Uri "$siteUrl/.netlify/functions/list-jobs" -Method Get -ErrorAction Stop

        foreach ($jobId in $response.jobs) {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 새 인쇄 작업 발견: $jobId" -ForegroundColor Yellow

            try {
                $jobData = Invoke-RestMethod -Uri "$siteUrl/.netlify/functions/get-job?id=$jobId" -Method Get -ErrorAction Stop
                $base64 = $jobData.imageData -replace '^data:image/\w+;base64,', ''
                $imageBytes = [Convert]::FromBase64String($base64)

                $tempFile = "$env:TEMP\photo_print_$jobId.jpg"
                [System.IO.File]::WriteAllBytes($tempFile, $imageBytes)

                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 인쇄 중..." -ForegroundColor Green
                Print-Image -FilePath $tempFile

                Invoke-RestMethod -Uri "$siteUrl/.netlify/functions/done-job?id=$jobId" -Method Get -ErrorAction SilentlyContinue | Out-Null
                Remove-Item $tempFile -ErrorAction SilentlyContinue

                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 인쇄 완료!" -ForegroundColor Green
                Write-Host ""
            }
            catch {
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 인쇄 오류: $_" -ForegroundColor Red
            }
        }
    }
    catch {
    }

    Start-Sleep -Seconds $checkInterval
}
