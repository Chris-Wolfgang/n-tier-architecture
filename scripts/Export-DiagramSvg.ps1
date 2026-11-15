#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Regenerates the SVG export of a Visio diagram in docs/diagrams.

.DESCRIPTION
    GitHub cannot preview .vsdx files, so each diagram is committed with an .svg export
    next to it. Run this script after every change to the .vsdx and commit both files in
    the same PR, otherwise the SVG goes stale.

    The script opens the .vsdx READ-ONLY in an invisible Visio instance (the .vsdx is never
    modified), exports the page to SVG, and crops the SVG's width, height and viewBox to the
    drawing plus a margin. Visio always exports the whole page, which is much larger than
    the drawing.

    Requires Windows with Microsoft Visio installed. If the diagram is open in Visio, save
    it first; the export reads the file on disk.

.PARAMETER Path
    The .vsdx to export. Defaults to "docs/diagrams/n-tier Model Object Diagram.vsdx".
    Relative paths are resolved against the repository root.

.PARAMETER OutFile
    The .svg to write. Defaults to the .vsdx path with an .svg extension.

.PARAMETER Page
    The 1-based page number to export. Defaults to 1.

.PARAMETER Margin
    Margin around the drawing, in inches. Defaults to 0.5.

.EXAMPLE
    pwsh ./scripts/Export-DiagramSvg.ps1
    Re-exports docs/diagrams/n-tier Model Object Diagram.svg.

.EXAMPLE
    pwsh ./scripts/Export-DiagramSvg.ps1 -Path docs/diagrams/other.vsdx -Margin 0.25
#>
param(
    [string]$Path = 'docs/diagrams/n-tier Model Object Diagram.vsdx',
    [string]$OutFile,
    [ValidateRange(1, 1000)]
    [int]$Page = 1,
    [ValidateRange(0, 10)]
    [double]$Margin = 0.5
)

$ErrorActionPreference = 'Stop'
$inv = [Globalization.CultureInfo]::InvariantCulture

$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not [IO.Path]::IsPathRooted($Path)) { $Path = Join-Path $repoRoot $Path }
$Path = [IO.Path]::GetFullPath($Path)
if (-not (Test-Path -LiteralPath $Path)) { throw "Diagram not found: $Path" }
if (-not $OutFile) { $OutFile = [IO.Path]::ChangeExtension($Path, '.svg') }
elseif (-not [IO.Path]::IsPathRooted($OutFile)) { $OutFile = Join-Path $repoRoot $OutFile }
$OutFile = [IO.Path]::GetFullPath($OutFile)

try {
    $visio = New-Object -ComObject Visio.InvisibleApp
}
catch {
    throw "Microsoft Visio is required to export the diagram (could not start Visio.InvisibleApp): $($_.Exception.Message)"
}

$xs = [Collections.Generic.List[double]]::new()
$ys = [Collections.Generic.List[double]]::new()
try {
    $visio.AlertResponse = 1                                  # answer any dialog with OK
    $doc = $visio.Documents.OpenEx($Path, 2)                  # 2 = visOpenRO: never modify the .vsdx
    try {
        $pg = $doc.Pages.Item($Page)
        $pageWidth = $pg.PageSheet.CellsU('PageWidth').ResultIU
        $pageHeight = $pg.PageSheet.CellsU('PageHeight').ResultIU

        # Extent of the drawing, from every top-level shape (connectors by their end points).
        foreach ($s in $pg.Shapes) {
            if ($s.OneD) {
                $xs.Add($s.CellsU('BeginX').ResultIU); $xs.Add($s.CellsU('EndX').ResultIU)
                $ys.Add($s.CellsU('BeginY').ResultIU); $ys.Add($s.CellsU('EndY').ResultIU)
            }
            else {
                $x0 = $s.CellsU('PinX').ResultIU - $s.CellsU('LocPinX').ResultIU
                $y0 = $s.CellsU('PinY').ResultIU - $s.CellsU('LocPinY').ResultIU
                $xs.Add($x0); $xs.Add($x0 + $s.CellsU('Width').ResultIU)
                $ys.Add($y0); $ys.Add($y0 + $s.CellsU('Height').ResultIU)
            }
        }
        if ($xs.Count -eq 0) { throw "Page $Page of $Path has no shapes." }

        $pg.Export($OutFile)
    }
    finally {
        $doc.Saved = $true                                    # read-only: discard any recalculation
        $doc.Close()
    }
}
finally {
    $visio.Quit()
    [void][Runtime.InteropServices.Marshal]::ReleaseComObject($visio)
}

$minX = ($xs | Measure-Object -Minimum).Minimum
$maxX = ($xs | Measure-Object -Maximum).Maximum
$minY = ($ys | Measure-Object -Minimum).Minimum
$maxY = ($ys | Measure-Object -Maximum).Maximum
if ($minX -lt 0 -or $minY -lt 0 -or $maxX -gt $pageWidth -or $maxY -gt $pageHeight) {
    throw ("A shape lies outside the {0} x {1} in page (x {2:F2}..{3:F2}, y {4:F2}..{5:F2}). " +
        "Fix the shape in Visio before exporting." -f $pageWidth, $pageHeight, $minX, $maxX, $minY, $maxY)
}

# Crop: Visio's SVG uses 72 user units per inch with y measured from the top of the page.
# 0.0, not 0: an int literal makes PowerShell pick Math.Max(int, int) and round the edge.
$x0 = [Math]::Max(0.0, $minX - $Margin); $x1 = [Math]::Min($pageWidth, $maxX + $Margin)
$y0 = [Math]::Max(0.0, $minY - $Margin); $y1 = [Math]::Min($pageHeight, $maxY + $Margin)
$units = 72

$svg = [IO.File]::ReadAllText($OutFile, [Text.Encoding]::UTF8).Replace("`r`n", "`n")
$root = [regex]::Match($svg, '<svg\b[^>]*>')
if (-not $root.Success) { throw "No <svg> element in $OutFile" }
$tag = $root.Value
$vb = [regex]::Match($tag, 'viewBox="([^"]+)"')
$vbValues = if ($vb.Success) { $vb.Groups[1].Value -split '\s+' | ForEach-Object { [double]::Parse($_, $inv) } } else { @() }
if ($vbValues.Count -ne 4 -or $vbValues[0] -ne 0 -or $vbValues[1] -ne 0 -or
    [Math]::Abs($vbValues[2] - $pageWidth * $units) -gt 0.01 -or [Math]::Abs($vbValues[3] - $pageHeight * $units) -gt 0.01) {
    throw "Unexpected viewBox in Visio's export: '$($vb.Value)'. Expected the full page at $units units per inch."
}

$newViewBox = 'viewBox="{0} {1} {2} {3}"' -f `
    ($x0 * $units).ToString('F2', $inv), (($pageHeight - $y1) * $units).ToString('F2', $inv),
    (($x1 - $x0) * $units).ToString('F2', $inv), (($y1 - $y0) * $units).ToString('F2', $inv)
$newTag = $tag.Replace($vb.Value, $newViewBox)
$newTag = [regex]::Replace($newTag, 'width="[^"]*in"', ('width="{0}in"' -f ($x1 - $x0).ToString('G4', $inv)))
$newTag = [regex]::Replace($newTag, 'height="[^"]*in"', ('height="{0}in"' -f ($y1 - $y0).ToString('G4', $inv)))

$svg = $svg.Substring(0, $root.Index) + $newTag + $svg.Substring($root.Index + $root.Length)
[IO.File]::WriteAllText($OutFile, $svg, [Text.UTF8Encoding]::new($false))

Write-Host ("Exported {0} -> {1} ({2} x {3} in)" -f (Split-Path -Leaf $Path), (Split-Path -Leaf $OutFile),
    ($x1 - $x0).ToString('F2', $inv), ($y1 - $y0).ToString('F2', $inv))
