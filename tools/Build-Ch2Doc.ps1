$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root 'docs\chuong-2\2.1_2.3_Mo_hinh_ASIS_va_ngoai_le.html'
$out = Join-Path $root 'docs\chuong-2\2.1_2.3_Mo_hinh_ASIS_va_ngoai_le.docx'
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $word.Documents.Open($src, $false, $false, $false)
$ps = $doc.PageSetup
$ps.TopMargin = 42.5; $ps.BottomMargin = 42.5; $ps.LeftMargin = 45; $ps.RightMargin = 42
$ps.PaperSize = 7
try { $doc.Styles.Item('Normal').Font.Name = 'Times New Roman'; $doc.Styles.Item('Normal').Font.Size = 12 } catch {}
$doc.SaveAs2($out, 16)
"PAGES=" + $doc.ComputeStatistics(2)
$doc.Close(0)
$word.Quit()
Get-Item $out | Select-Object Name, Length
