param(
    [Parameter(Mandatory = $true)][string]$In,
    [Parameter(Mandatory = $true)][string]$Out
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$html = [System.IO.File]::ReadAllText((Resolve-Path $In).Path, [System.Text.Encoding]::UTF8)
$html = [regex]::Replace($html, '(?is)<head.*?</head>', '')
$bm = [regex]::Match($html, '(?is)<body[^>]*>(.*)</body>')
$bodyHtml = if ($bm.Success) { $bm.Groups[1].Value } else { $html }

# ---------------- phan tich HTML thanh cay ----------------
function Parse-Html([string]$s) {
    $root = @{ tag = '#root'; attrs = @{}; children = (New-Object System.Collections.ArrayList) }
    $stack = New-Object System.Collections.Stack
    $stack.Push($root)
    $voids = @('br', 'img', 'hr', 'meta', 'input', 'link')
    $rx = [regex]'(?s)<(/?)([a-zA-Z][a-zA-Z0-9]*)((?:[^>"'']|"[^"]*"|''[^'']*'')*?)(/?)>'
    $pos = 0
    foreach ($m in $rx.Matches($s)) {
        if ($m.Index -gt $pos) {
            $text = $s.Substring($pos, $m.Index - $pos)
            $text = [System.Net.WebUtility]::HtmlDecode($text)
            if ($text.Trim().Length -gt 0) {
                [void]$stack.Peek().children.Add(@{ tag = '#text'; text = $text })
            }
        }
        $closing = ($m.Groups[1].Value -eq '/')
        $tag = $m.Groups[2].Value.ToLower()
        $attrText = $m.Groups[3].Value
        $selfClose = ($m.Groups[4].Value -eq '/')

        if ($closing) {
            # dong the: pop toi khi gap the tuong ung
            $found = $false
            foreach ($n in $stack) { if ($n.tag -eq $tag) { $found = $true; break } }
            if ($found) {
                while ($stack.Count -gt 1) {
                    $top = $stack.Pop()
                    if ($top.tag -eq $tag) { break }
                }
            }
        } else {
            $attrs = @{}
            foreach ($am in [regex]::Matches($attrText, '([a-zA-Z0-9:\-_]+)\s*=\s*("([^"]*)"|''([^'']*)'')')) {
                $val = if ($am.Groups[3].Success) { $am.Groups[3].Value } else { $am.Groups[4].Value }
                $attrs[$am.Groups[1].Value.ToLower()] = $val
            }
            $node = @{ tag = $tag; attrs = $attrs; children = (New-Object System.Collections.ArrayList) }
            [void]$stack.Peek().children.Add($node)
            if (-not $selfClose -and -not ($voids -contains $tag)) { $stack.Push($node) }
        }
        $pos = $m.Index + $m.Length
    }
    if ($pos -lt $s.Length) {
        $text = [System.Net.WebUtility]::HtmlDecode($s.Substring($pos))
        if ($text.Trim().Length -gt 0) { [void]$stack.Peek().children.Add(@{ tag = '#text'; text = $text }) }
    }
    return $root
}

$doc = Parse-Html $bodyHtml

# ---------------- tien ich XML ----------------
$NAVY = '1F3864'

function Esc-Xml([string]$t) {
    return ($t -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;')
}

function Get-Attr($node, [string]$name) {
    if ($null -eq $node.attrs) { return $null }
    if ($node.attrs.ContainsKey($name)) { return $node.attrs[$name] }
    return $null
}

function Has-Class($node, [string]$cls) {
    $c = Get-Attr $node 'class'
    if (-not $c) { return $false }
    return ($c -split '\s+') -contains $cls
}

function Run-Props($f) {
    $x = '<w:rPr>'
    if ($f.font) { $x += '<w:rFonts w:ascii="' + $f.font + '" w:hAnsi="' + $f.font + '" w:cs="' + $f.font + '"/>' }
    if ($f.bold) { $x += '<w:b/><w:bCs/>' }
    if ($f.italic) { $x += '<w:i/><w:iCs/>' }
    if ($f.color) { $x += '<w:color w:val="' + $f.color + '"/>' }
    $sz = if ($f.size) { $f.size } else { 24 }
    $x += '<w:sz w:val="' + $sz + '"/><w:szCs w:val="' + $sz + '"/>'
    $x += '</w:rPr>'
    return $x
}

function New-Run([string]$text, $f) {
    if ([string]::IsNullOrEmpty($text)) { return '' }
    $t = Esc-Xml $text
    return '<w:r>' + (Run-Props $f) + '<w:t xml:space="preserve">' + $t + '</w:t></w:r>'
}

function New-Para([string]$runs, [hashtable]$p) {
    # Thu tu phan tu trong w:pPr phai theo schema OOXML, neu sai Word se bao loi mo tep
    $ppr = '<w:pPr>'
    if ($p.style) { $ppr += '<w:pStyle w:val="' + $p.style + '"/>' }
    if ($p.keepNext) { $ppr += '<w:keepNext/>' }
    if ($p.border) {
        $ppr += '<w:pBdr><w:left w:val="single" w:sz="18" w:space="6" w:color="' + $p.border + '"/></w:pBdr>'
    }
    elseif ($p.borderBottom) {
        $ppr += '<w:pBdr><w:bottom w:val="single" w:sz="12" w:space="3" w:color="' + $p.borderBottom + '"/></w:pBdr>'
    }
    if ($p.shade) { $ppr += '<w:shd w:val="clear" w:color="auto" w:fill="' + $p.shade + '"/>' }
    $before = if ($null -ne $p.before) { $p.before } else { 0 }
    $after = if ($null -ne $p.after) { $p.after } else { 0 }
    $ppr += '<w:spacing w:before="' + $before + '" w:after="' + $after + '" w:line="276" w:lineRule="auto"/>'
    if ($p.hanging) { $ppr += '<w:ind w:left="' + $p.indent + '" w:hanging="' + $p.hanging + '"/>' }
    elseif ($p.indent) { $ppr += '<w:ind w:left="' + $p.indent + '" w:right="' + $p.indent + '"/>' }
    if ($p.align) {
        # OOXML dung "both" cho can deu hai ben; "justify" la gia tri CSS, Word se tu choi tep
        $a = $p.align
        if ($a -eq 'justify') { $a = 'both' }
        $ppr += '<w:jc w:val="' + $a + '"/>'
    }
    $ppr += '</w:pPr>'
    return '<w:p>' + $ppr + $runs + '</w:p>'
}

# ---------------- noi tuyen ----------------
function Render-Inline($children, $f) {
    $sb = New-Object System.Text.StringBuilder
    foreach ($c in $children) {
        if ($c.tag -eq '#text') {
            $t = [regex]::Replace($c.text, '\s+', ' ')
            if ($t.Trim().Length -eq 0) { continue }
            [void]$sb.Append((New-Run $t $f))
        }
        elseif ($c.tag -eq 'br') {
            [void]$sb.Append('<w:r>' + (Run-Props $f) + '<w:br/></w:r>')
        }
        else {
            $nf = @{ bold = $f.bold; italic = $f.italic; color = $f.color; size = $f.size; font = $f.font }
            switch ($c.tag) {
                'b'      { $nf.bold = $true }
                'strong' { $nf.bold = $true }
                'i'      { $nf.italic = $true }
                'em'     { $nf.italic = $true }
                'code'   { $nf.font = 'Consolas'; $nf.size = 19 }
                'span'   { }
            }
            [void]$sb.Append((Render-Inline $c.children $nf))
        }
    }
    return $sb.ToString()
}

function Has-InlineContent($node) {
    foreach ($c in $node.children) {
        if ($c.tag -eq '#text' -and $c.text.Trim().Length -gt 0) { return $true }
        if ($c.tag -ne '#text' -and $c.tag -notin @('p', 'table', 'div', 'ul', 'ol', 'h1', 'h2', 'h3')) { return $true }
    }
    return $false
}

# ---------------- bang ----------------
function Render-Table($node) {
    $rows = @()
    foreach ($c in $node.children) { if ($c.tag -eq 'tr') { $rows += , $c } }
    if ($rows.Count -eq 0) { return '' }

    # do rong cot tu the th cua hang dau
    $pcts = @()
    $first = $rows[0]
    foreach ($cell in $first.children) {
        if ($cell.tag -ne 'th' -and $cell.tag -ne 'td') { continue }
        $style = Get-Attr $cell 'style'
        $pct = 0
        if ($style) {
            $m = [regex]::Match($style, 'width\s*:\s*([0-9.]+)\s*%')
            if ($m.Success) { $pct = [double]$m.Groups[1].Value }
        }
        $pcts += $pct
    }
    $nCol = $pcts.Count
    if ($nCol -eq 0) { return '' }
    $sum = ($pcts | Measure-Object -Sum).Sum
    if ($sum -le 0) { $pcts = @(); for ($i = 0; $i -lt $nCol; $i++) { $pcts += (100.0 / $nCol) } ; $sum = 100.0 }
    $totalW = 10166
    $widths = @()
    for ($i = 0; $i -lt $nCol; $i++) { $widths += [int][math]::Round($totalW * $pcts[$i] / $sum) }

    $BORDER = '<w:tblBorders>' +
        '<w:top w:val="single" w:sz="4" w:space="0" w:color="7F7F7F"/>' +
        '<w:left w:val="single" w:sz="4" w:space="0" w:color="7F7F7F"/>' +
        '<w:bottom w:val="single" w:sz="4" w:space="0" w:color="7F7F7F"/>' +
        '<w:right w:val="single" w:sz="4" w:space="0" w:color="7F7F7F"/>' +
        '<w:insideH w:val="single" w:sz="4" w:space="0" w:color="7F7F7F"/>' +
        '<w:insideV w:val="single" w:sz="4" w:space="0" w:color="7F7F7F"/>' +
        '</w:tblBorders>'

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('<w:tbl><w:tblPr><w:tblW w:w="' + $totalW + '" w:type="dxa"/>' + $BORDER + '<w:tblLayout w:type="fixed"/><w:tblCellMar><w:top w:w="43" w:type="dxa"/><w:left w:w="57" w:type="dxa"/><w:bottom w:w="43" w:type="dxa"/><w:right w:w="57" w:type="dxa"/></w:tblCellMar></w:tblPr><w:tblGrid>')
    foreach ($w in $widths) { [void]$sb.Append('<w:gridCol w:w="' + $w + '"/>') }
    [void]$sb.Append('</w:tblGrid>')

    $rowIndex = 0
    foreach ($tr in $rows) {
        $isHeader = ($rowIndex -eq 0 -and $tr.children[0].tag -eq 'th')
        $shade = $null
        if (Has-Class $tr 'alt') { $shade = 'F2F5FA' }
        if (Has-Class $tr 'tot') { $shade = 'E6E6E6' }
        $rowBold = Has-Class $tr 'tot'

        [void]$sb.Append('<w:tr>')
        if ($isHeader) { [void]$sb.Append('<w:trPr><w:tblHeader/></w:trPr>') }
        $ci = 0
        foreach ($cell in $tr.children) {
            if ($cell.tag -ne 'th' -and $cell.tag -ne 'td') { continue }
            if ($ci -ge $nCol) { break }
            $w = $widths[$ci]
            $cellShade = if ($isHeader) { $NAVY } else { $shade }
            [void]$sb.Append('<w:tc><w:tcPr><w:tcW w:w="' + $w + '" w:type="dxa"/>')
            if ($cellShade) { [void]$sb.Append('<w:shd w:val="clear" w:color="auto" w:fill="' + $cellShade + '"/>') }
            [void]$sb.Append('<w:vAlign w:val="top"/></w:tcPr>')

            $f = @{ size = 18; bold = ($isHeader -or $rowBold); italic = $false; color = $(if ($isHeader) { 'FFFFFF' } else { $null }); font = $null }
            $align = if ((Has-Class $cell 'c') -or $isHeader) { 'center' } else { 'left' }
            $runs = Render-Inline $cell.children $f
            if ([string]::IsNullOrWhiteSpace(($runs -replace '<[^>]+>', ''))) { $runs = New-Run ' ' $f }
            [void]$sb.Append((New-Para $runs @{ align = $align; after = 0; before = 0 }))
            [void]$sb.Append('</w:tc>')
            $ci++
        }
        [void]$sb.Append('</w:tr>')
        $rowIndex++
    }
    [void]$sb.Append('</w:tbl>')
    # doan trong sau bang
    [void]$sb.Append((New-Para '' @{ after = 0; before = 0 }))
    return $sb.ToString()
}

# ---------------- khoi ----------------
function Render-Blocks($children, $ctx) {
    $sb = New-Object System.Text.StringBuilder
    $buffer = New-Object System.Collections.ArrayList

    $flush = {
        if ($buffer.Count -gt 0) {
            $runs = Render-Inline $buffer $ctx.fmt
            if (-not [string]::IsNullOrWhiteSpace(($runs -replace '<[^>]+>', ''))) {
                [void]$sb.Append((New-Para $runs $ctx.para))
            }
            $buffer.Clear()
        }
    }

    foreach ($c in $children) {
        if ($c.tag -eq '#text') { [void]$buffer.Add($c); continue }

        switch ($c.tag) {
            { $_ -in @('b', 'strong', 'i', 'em', 'code', 'span') } { [void]$buffer.Add($c); break }
            'br' { [void]$buffer.Add($c); break }
            'h1' {
                & $flush
                $f = $ctx.fmt.Clone(); $f.bold = $true; $f.size = 30; $f.color = $NAVY
                $runs = Render-Inline $c.children $f
                [void]$sb.Append((New-Para $runs @{ align = 'center'; before = 0; after = 120; keepNext = $true }))
                break
            }
            'h2' {
                & $flush
                $f = $ctx.fmt.Clone(); $f.bold = $true; $f.size = 26; $f.color = $NAVY
                [void]$sb.Append((New-Para (Render-Inline $c.children $f) @{ before = 360; after = 140; keepNext = $true; borderBottom = $NAVY }))
                break
            }
            'h3' {
                & $flush
                $f = $ctx.fmt.Clone(); $f.bold = $true; $f.size = 23; $f.color = $NAVY
                [void]$sb.Append((New-Para (Render-Inline $c.children $f) @{ before = 260; after = 100; keepNext = $true }))
                break
            }
            'p' {
                & $flush
                if (Has-Class $c 'sub') {
                    $f = $ctx.fmt.Clone(); $f.italic = $true; $f.size = 21; $f.color = '444444'
                    [void]$sb.Append((New-Para (Render-Inline $c.children $f) @{ align = 'center'; after = 320 }))
                }
                elseif (Has-Class $c 'cap') {
                    $f = $ctx.fmt.Clone(); $f.italic = $true; $f.size = 18; $f.color = '555555'
                    [void]$sb.Append((New-Para (Render-Inline $c.children $f) @{ align = 'center'; before = 40; after = 240 }))
                }
                elseif (Has-Class $c 'small') {
                    $f = $ctx.fmt.Clone(); $f.size = 18; $f.color = '555555'
                    [void]$sb.Append((New-Para (Render-Inline $c.children $f) @{ align = 'justify'; before = 80; after = 120 }))
                }
                else {
                    [void]$sb.Append((New-Para (Render-Inline $c.children $ctx.fmt) @{ align = 'justify'; after = 140 }))
                }
                break
            }
            'table' {
                & $flush
                [void]$sb.Append((Render-Table $c))
                break
            }
            'div' {
                & $flush
                $shade = $null; $border = $null
                if (Has-Class $c 'note') { $shade = 'F2F5FA'; $border = $NAVY }
                if (Has-Class $c 'warn') { $shade = 'FDF1E8'; $border = 'B36B00' }
                $sub = @{ fmt = $ctx.fmt.Clone(); para = @{ align = 'justify'; after = 140 } }
                if ($shade) {
                    $sub.fmt.size = 21
                    $sub.para = @{ align = 'justify'; after = 0; before = 80; shade = $shade; border = $border; indent = 170 }
                    $inner = Render-Blocks $c.children $sub
                    [void]$sb.Append($inner)
                    [void]$sb.Append((New-Para '' @{ after = 0; before = 0; shade = $shade; indent = 170 }))
                } else {
                    [void]$sb.Append((Render-Blocks $c.children $sub))
                }
                break
            }
            'ul' {
                & $flush
                foreach ($li in $c.children) {
                    if ($li.tag -ne 'li') { continue }
                    $f = $ctx.fmt.Clone()
                    $runs = (New-Run ([char]0x2022 + "  ") $f) + (Render-Inline $li.children $f)
                    [void]$sb.Append((New-Para $runs @{ align = 'justify'; after = 60; indent = 340; hanging = 170 }))
                }
                break
            }
            'ol' {
                & $flush
                $n = 0
                foreach ($li in $c.children) {
                    if ($li.tag -ne 'li') { continue }
                    $n++
                    $f = $ctx.fmt.Clone()
                    $runs = (New-Run ("$n.  ") $f) + (Render-Inline $li.children $f)
                    [void]$sb.Append((New-Para $runs @{ align = 'justify'; after = 60; indent = 340; hanging = 170 }))
                }
                break
            }
            default { }
        }
    }
    & $flush
    return $sb.ToString()
}

$ctx = @{ fmt = @{ size = 24; bold = $false; italic = $false; color = $null; font = $null }; para = @{ align = 'justify'; after = 140 } }
$bodyXml = Render-Blocks $doc.children $ctx

$sectPr = '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="850" w:right="840" w:bottom="850" w:left="900" w:header="708" w:footer="708" w:gutter="0"/><w:cols w:space="708"/><w:docGrid w:linePitch="360"/></w:sectPr>'

$NS = 'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"'
$documentXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document ' + $NS + '><w:body>' + $bodyXml + $sectPr + '</w:body></w:document>'

$stylesXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" w:eastAsia="Times New Roman" w:cs="Times New Roman"/><w:sz w:val="24"/><w:szCs w:val="24"/></w:rPr></w:rPrDefault><w:pPrDefault><w:pPr><w:spacing w:after="0" w:line="276" w:lineRule="auto"/></w:pPr></w:pPrDefault></w:docDefaults><w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:qFormat/></w:style></w:styles>'

$contentTypes = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/><Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/><Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/></Types>'

$rootRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/><Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/></Relationships>'

$docRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>'

$now = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
$title = [System.IO.Path]::GetFileNameWithoutExtension($Out)
$coreXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><dc:title>' + (Esc-Xml $title) + '</dc:title><dc:creator>Nhom 8 - MIS3047</dc:creator><cp:lastModifiedBy>Nhom 8 - MIS3047</cp:lastModifiedBy><dcterms:created xsi:type="dcterms:W3CDTF">' + $now + '</dcterms:created><dcterms:modified xsi:type="dcterms:W3CDTF">' + $now + '</dcterms:modified></cp:coreProperties>'

$appXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes"><Application>MIS3047 HtmlToDocx</Application></Properties>'

# kiem tra XML hop le truoc khi dong goi
foreach ($pair in @(@('document.xml', $documentXml), @('styles.xml', $stylesXml), @('core.xml', $coreXml))) {
    try { [void][xml]$pair[1] } catch { throw ("XML khong hop le trong " + $pair[0] + ": " + $_.Exception.Message) }
}

$outPath = [System.IO.Path]::GetFullPath($Out)
if (Test-Path $outPath) { Remove-Item $outPath -Force }
$enc = New-Object System.Text.UTF8Encoding($false)
$zip = [System.IO.Compression.ZipFile]::Open($outPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    $parts = [ordered]@{
        '[Content_Types].xml'      = $contentTypes
        '_rels/.rels'              = $rootRels
        'word/document.xml'        = $documentXml
        'word/styles.xml'          = $stylesXml
        'word/_rels/document.xml.rels' = $docRels
        'docProps/core.xml'        = $coreXml
        'docProps/app.xml'         = $appXml
    }
    foreach ($k in $parts.Keys) {
        $entry = $zip.CreateEntry($k, [System.IO.Compression.CompressionLevel]::Optimal)
        $stream = $entry.Open()
        $bytes = $enc.GetBytes($parts[$k])
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Close()
    }
} finally {
    $zip.Dispose()
}

$fi = Get-Item $outPath
$paras = ([regex]::Matches($documentXml, '<w:p>')).Count
$tables = ([regex]::Matches($documentXml, '<w:tbl>')).Count
"OK -> $($fi.FullName)"
"Kich thuoc: $([math]::Round($fi.Length/1KB,1)) KB | Doan van: $paras | Bang: $tables"
