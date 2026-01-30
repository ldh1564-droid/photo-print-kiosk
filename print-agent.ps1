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
            e.Graphics.DrawImage(bmp, 0, 0, pw, ph);
        };
        doc.Print();
        doc.Dispose();
        bmp.Dispose();
    }
}
"@

$supabaseUrl = "https://czvaoseccmeosvzawryf.supabase.co"
$supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN6dmFvc2VjY21lb3N2emF3cnlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk3MzA0OTIsImV4cCI6MjA4NTMwNjQ5Mn0.Wy_Izc_Ggfa9FZ-EPLJ9RY4i_fLhlcxZoFuRsjMrfow"
$headers = @{ "apikey" = $supabaseKey; "Authorization" = "Bearer $supabaseKey" }
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
        $jobs = Invoke-RestMethod -Uri "$supabaseUrl/rest/v1/print_jobs?select=id&order=id.asc" -Headers $headers -Method Get -ErrorAction Stop

        foreach ($job in $jobs) {
            $jobId = $job.id
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 새 인쇄 작업 발견: $jobId" -ForegroundColor Yellow

            try {
                $rows = Invoke-RestMethod -Uri "$supabaseUrl/rest/v1/print_jobs?id=eq.$jobId&select=image_data" -Headers $headers -Method Get -ErrorAction Stop
                $raw = $rows[0].image_data
                $parsed = $raw | ConvertFrom-Json
                $base64 = $parsed.imageData -replace '^data:image/\w+;base64,', ''
                $imageBytes = [Convert]::FromBase64String($base64)

                $tempFile = "$env:TEMP\photo_print_$jobId.jpg"
                [System.IO.File]::WriteAllBytes($tempFile, $imageBytes)

                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 인쇄 중..." -ForegroundColor Green
                [PhotoPrinter]::PrintFile($tempFile)

                $delHeaders = @{ "apikey" = $supabaseKey; "Authorization" = "Bearer $supabaseKey" }
                Invoke-RestMethod -Uri "$supabaseUrl/rest/v1/print_jobs?id=eq.$jobId" -Headers $delHeaders -Method Delete -ErrorAction SilentlyContinue | Out-Null
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
