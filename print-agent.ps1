### 셀프 포토 프린트 에이전트 ###
# 이 스크립트를 Windows 데스크탑에서 실행하세요.

Add-Type -AssemblyName System.Drawing

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Printing;

public class PhotoPrinter {
    public static void PrintFile(string path) {
        Bitmap bmp = new Bitmap(path);
        bool landscape = (bmp.Width > bmp.Height);
        PrintDocument doc = new PrintDocument();
        doc.DefaultPageSettings.Landscape = landscape;
        doc.DefaultPageSettings.PaperSize = new PaperSize("4x6", 400, 600);
        doc.DefaultPageSettings.Margins = new Margins(0, 0, 0, 0);
        doc.PrintPage += delegate(object s, PrintPageEventArgs e) {
            float pw = e.PageBounds.Width;
            float ph = e.PageBounds.Height;
            float r = Math.Min(pw / bmp.Width, ph / bmp.Height);
            int dw = (int)(bmp.Width * r);
            int dh = (int)(bmp.Height * r);
            int dx = (int)((pw - dw) / 2);
            int dy = (int)((ph - dh) / 2);
            e.Graphics.DrawImage(bmp, dx, dy, dw, dh);
        };
        doc.Print();
        doc.Dispose();
        bmp.Dispose();
    }
}
"@

$siteUrl = "https://creative-naiad-54f6d9.netlify.app"
$checkInterval = 5

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
                $jobData = Invoke-RestMethod -Uri "$siteUrl/.netlify/functions/get-job?id=$jobId" -Method Get -ErrorAction Stop
                $base64 = $jobData.imageData -replace '^data:image/\w+;base64,', ''
                $imageBytes = [Convert]::FromBase64String($base64)

                $tempFile = "$env:TEMP\photo_print_$jobId.jpg"
                [System.IO.File]::WriteAllBytes($tempFile, $imageBytes)

                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 인쇄 중..." -ForegroundColor Green
                [PhotoPrinter]::PrintFile($tempFile)

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
