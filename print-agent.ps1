### 셀프 포토 프린트 에이전트 ###
# 이 스크립트를 Windows 데스크탑에서 실행하세요.
# 손님이 웹페이지에서 "프린트" 버튼을 누르면 자동으로 인쇄됩니다.

Add-Type -AssemblyName System.Drawing

$siteUrl = "https://creative-naiad-54f6d9.netlify.app"
$checkInterval = 5  # 초 단위

Write-Host ""
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "  셀프 포토 프린트 에이전트" -ForegroundColor Cyan
Write-Host "  인쇄 대기 중..." -ForegroundColor Cyan
Write-Host "  종료: Ctrl+C" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

while ($true) {
    try {
        $response = Invoke-RestMethod -Uri "$siteUrl/.netlify/functions/list-jobs" -Method Get -ErrorAction Stop

        foreach ($jobId in $response.jobs) {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 새 인쇄 작업 발견: $jobId" -ForegroundColor Yellow

            try {
                # 이미지 다운로드
                $jobData = Invoke-RestMethod -Uri "$siteUrl/.netlify/functions/get-job?id=$jobId" -Method Get -ErrorAction Stop
                $base64 = $jobData.imageData -replace '^data:image/\w+;base64,', ''
                $imageBytes = [Convert]::FromBase64String($base64)

                # 임시 파일로 저장
                $tempFile = "$env:TEMP\photo_print_$jobId.jpg"
                [System.IO.File]::WriteAllBytes($tempFile, $imageBytes)

                # 이미지 크기 확인 후 방향 맞춰 인쇄
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 인쇄 중..." -ForegroundColor Green

                $img = [System.Drawing.Image]::FromFile($tempFile)
                $isPortrait = $img.Height -gt $img.Width

                $printDoc = New-Object System.Drawing.Printing.PrintDocument
                $printDoc.DefaultPageSettings.Landscape = -not $isPortrait

                $printDoc.add_PrintPage({
                    param($sender, $e)
                    $pageW = $e.MarginBounds.Width
                    $pageH = $e.MarginBounds.Height
                    $imgW = $img.Width
                    $imgH = $img.Height
                    $ratio = [Math]::Min($pageW / $imgW, $pageH / $imgH)
                    $drawW = [int]($imgW * $ratio)
                    $drawH = [int]($imgH * $ratio)
                    $x = $e.MarginBounds.X + [int](($pageW - $drawW) / 2)
                    $y = $e.MarginBounds.Y + [int](($pageH - $drawH) / 2)
                    $e.Graphics.DrawImage($img, $x, $y, $drawW, $drawH)
                })

                $printDoc.Print()
                $printDoc.Dispose()
                $img.Dispose()

                # 완료 처리
                Invoke-RestMethod -Uri "$siteUrl/.netlify/functions/done-job?id=$jobId" -Method Get -ErrorAction SilentlyContinue | Out-Null

                # 임시 파일 삭제
                Remove-Item $tempFile -ErrorAction SilentlyContinue

                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 인쇄 완료!" -ForegroundColor Green
                Write-Host ""
            }
            catch {
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 인쇄 오류: $_" -ForegroundColor Red
                if ($img) { $img.Dispose() }
            }
        }
    }
    catch {
        # 네트워크 오류 시 무시하고 재시도
    }

    Start-Sleep -Seconds $checkInterval
}
