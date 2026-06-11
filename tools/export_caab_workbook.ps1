param(
  [string]$SourcePath = "Data\caab_species_20260611.xls",
  [string]$CsvPath = ".local\caab_species_20260611.csv"
)

$ErrorActionPreference = "Stop"

$resolvedSource = Resolve-Path -LiteralPath $SourcePath
$resolvedCsv = Join-Path (Get-Location) $CsvPath
$csvDirectory = Split-Path -Parent $resolvedCsv

if (-not (Test-Path -LiteralPath $csvDirectory)) {
  New-Item -ItemType Directory -Path $csvDirectory | Out-Null
}

if (Test-Path -LiteralPath $resolvedCsv) {
  Remove-Item -LiteralPath $resolvedCsv -Force
}

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
$workbook = $null

try {
  $workbook = $excel.Workbooks.Open($resolvedSource.Path, 0, $true)
  $workbook.SaveAs($resolvedCsv, 62)
  $workbook.Close($false)
  $workbook = $null
}
finally {
  if ($workbook -ne $null) {
    $workbook.Close($false) | Out-Null
  }

  $excel.Quit()
  [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel)
}

Get-Item -LiteralPath $resolvedCsv |
  Select-Object FullName, Length, LastWriteTime
