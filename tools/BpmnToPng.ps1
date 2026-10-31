param(
    [Parameter(Mandatory = $true)][string]$In,
    [Parameter(Mandatory = $true)][string]$Out,
    [double]$Scale = 1.6
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$BPMN = 'http://www.omg.org/spec/BPMN/20100524/MODEL'
$BPMNDI = 'http://www.omg.org/spec/BPMN/20100524/DI'
$DC = 'http://www.omg.org/spec/DD/20100524/DC'
$DI = 'http://www.omg.org/spec/DD/20100524/DI'

[xml]$doc = Get-Content -Raw -Encoding UTF8 $In
$ns = New-Object System.Xml.XmlNamespaceManager($doc.NameTable)
$ns.AddNamespace('b', $BPMN); $ns.AddNamespace('d', $BPMNDI); $ns.AddNamespace('dc', $DC); $ns.AddNamespace('di', $DI)

function Get-Font($size, $bold) {
    $style = if ($bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
    return New-Object System.Drawing.Font('Segoe UI', [single]$size, $style, [System.Drawing.GraphicsUnit]::Pixel)
}

function Wrap-Text($g, $text, $font, $maxW) {
    if (-not $text) { return @() }
    $words = $text -split '\s+'
    $lines = New-Object System.Collections.ArrayList
    $cur = ''
    foreach ($wd in $words) {
        $try = if ($cur -eq '') { $wd } else { "$cur $wd" }
        if ($g.MeasureString($try, $font).Width -le $maxW -or $cur -eq '') { $cur = $try }
        else { [void]$lines.Add($cur); $cur = $wd }
    }
    if ($cur -ne '') { [void]$lines.Add($cur) }
    return $lines
}

function Draw-TextBlock($g, $text, $font, $brush, $cx, $cy, $maxW, $align) {
    $lines = Wrap-Text $g $text $font $maxW
    if ($lines.Count -eq 0) { return }
    $lh = $g.MeasureString('Ag', $font).Height
    $total = $lh * $lines.Count
    $y = $cy - $total / 2
    foreach ($ln in $lines) {
        $w = $g.MeasureString($ln, $font).Width
        $x = if ($align -eq 'left') { $cx } else { $cx - $w / 2 }
        $g.DrawString($ln, $font, $brush, [single]$x, [single]$y)
        $y += $lh
    }
}

function New-Pen($color, $width, $dash) {
    $p = New-Object System.Drawing.Pen($color, [single]$width)
    if ($dash) { $p.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash }
    return $p
}

function Draw-ArrowHead($g, $pen, $x1, $y1, $x2, $y2, $size, $filled) {
    $ang = [math]::Atan2($y2 - $y1, $x2 - $x1)
    $a1 = $ang - 0.42; $a2 = $ang + 0.42
    $p1 = New-Object System.Drawing.PointF([single]($x2 - $size * [math]::Cos($a1)), [single]($y2 - $size * [math]::Sin($a1)))
    $p2 = New-Object System.Drawing.PointF([single]($x2 - $size * [math]::Cos($a2)), [single]($y2 - $size * [math]::Sin($a2)))
    $p0 = New-Object System.Drawing.PointF([single]$x2, [single]$y2)
    if ($filled) {
        $pts = @($p0, $p1, $p2)
        $g.FillPolygon((New-Object System.Drawing.SolidBrush($pen.Color)), $pts)
    } else {
        $g.DrawLine($pen, $p2, $p0); $g.DrawLine($pen, $p0, $p1)
    }
}

# ---------- thu thap hinh hoc ----------
$shapes = @()
$edges = @()
$minX = 1e9; $minY = 1e9; $maxX = -1e9; $maxY = -1e9

foreach ($s in $doc.SelectNodes('//d:BPMNShape', $ns)) {
    $b = $s.SelectSingleNode('dc:Bounds', $ns)
    if (-not $b) { continue }
    $el = $doc.SelectSingleNode("//*[@id='$($s.bpmnElement)']")
    if (-not $el) { continue }
    $o = [ordered]@{
        id = $s.bpmnElement; type = $el.LocalName
        x = [double]$b.x; y = [double]$b.y; w = [double]$b.width; h = [double]$b.height
        name = $el.GetAttribute('name'); horizontal = ($s.isHorizontal -eq 'true')
    }
    $shapes += $o
    if ($o.x -lt $minX) { $minX = $o.x }; if ($o.y -lt $minY) { $minY = $o.y }
    if (($o.x + $o.w) -gt $maxX) { $maxX = $o.x + $o.w }; if (($o.y + $o.h) -gt $maxY) { $maxY = $o.y + $o.h }
}
foreach ($e in $doc.SelectNodes('//d:BPMNEdge', $ns)) {
    $pts = @()
    foreach ($w in $e.SelectNodes('di:waypoint', $ns)) { $pts += , @([double]$w.x, [double]$w.y) }
    if ($pts.Count -lt 2) { continue }
    $el = $doc.SelectSingleNode("//*[@id='$($e.bpmnElement)']")
    $edges += [ordered]@{ id = $e.bpmnElement; type = $el.LocalName; name = $el.GetAttribute('name'); pts = $pts }
}

$pad = 40
$minX -= $pad; $minY -= $pad; $maxX += $pad; $maxY += $pad
$imgW = [int](($maxX - $minX) * $Scale)
$imgH = [int](($maxY - $minY) * $Scale)

$bmp = New-Object System.Drawing.Bitmap($imgW, $imgH)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$g.Clear([System.Drawing.Color]::White)
$g.ScaleTransform($Scale, $Scale)
$g.TranslateTransform(-$minX, -$minY)

$black = [System.Drawing.Color]::FromArgb(40, 40, 40)
$gray = [System.Drawing.Color]::FromArgb(110, 110, 110)
$white = [System.Drawing.Color]::White
$bTask = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(253, 252, 248))
$bPool = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(252, 252, 252))
$bTxt = New-Object System.Drawing.SolidBrush($black)
$bLane = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(245, 245, 245))
$penPool = New-Pen $black 1.4 $false
$penLane = New-Pen ([System.Drawing.Color]::FromArgb(150, 150, 150)) 0.9 $false
$penFlow = New-Pen $black 1.3 $false
$penMsg = New-Pen $gray 1.1 $true
$penNode = New-Pen $black 1.3 $false

$fTask = Get-Font 13 $false
$fGw = Get-Font 11 $false
$fSmall = Get-Font 10.5 $false
$fPool = Get-Font 15 $true
$fLane = Get-Font 13 $true

# ---------- pool & lane ----------
$pools = @($shapes | Where-Object { $_.type -eq 'participant' })
foreach ($p in $pools) {
    $g.FillRectangle($bPool, [single]$p.x, [single]$p.y, [single]$p.w, [single]$p.h)
    $g.DrawRectangle($penPool, [single]$p.x, [single]$p.y, [single]$p.w, [single]$p.h)
    $g.FillRectangle($bLane, [single]$p.x, [single]$p.y, [single]30, [single]$p.h)
    $g.DrawRectangle($penPool, [single]$p.x, [single]$p.y, [single]30, [single]$p.h)
    $st = $g.Save()
    $g.TranslateTransform([single]($p.x + 21), [single]($p.y + $p.h / 2))
    $g.RotateTransform(-90)
    $sz = $g.MeasureString($p.name, $fPool)
    $g.DrawString($p.name, $fPool, $bTxt, [single](-$sz.Width / 2), [single](-$sz.Height / 2))
    $g.Restore($st)
}
$lanes = @($shapes | Where-Object { $_.type -eq 'lane' })
foreach ($l in $lanes) {
    $g.DrawRectangle($penLane, [single]$l.x, [single]$l.y, [single]$l.w, [single]$l.h)
    $g.DrawString($l.name, $fLane, $bTxt, [single]($l.x + 8), [single]($l.y + 4))
}

# ---------- edges ----------
foreach ($e in $edges) {
    $isMsg = ($e.type -eq 'messageFlow')
    $pen = if ($isMsg) { $penMsg } else { $penFlow }
    $pts = $e.pts
    for ($i = 0; $i -lt $pts.Count - 1; $i++) {
        $g.DrawLine($pen, [single]$pts[$i][0], [single]$pts[$i][1], [single]$pts[$i + 1][0], [single]$pts[$i + 1][1])
    }
    $n = $pts.Count
    Draw-ArrowHead $g $pen $pts[$n - 2][0] $pts[$n - 2][1] $pts[$n - 1][0] $pts[$n - 1][1] 9 (-not $isMsg)
    if ($isMsg) {
        $g.FillEllipse((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)), [single]($pts[0][0] - 4), [single]($pts[0][1] - 4), 8, 8)
        $g.DrawEllipse($pen, [single]($pts[0][0] - 4), [single]($pts[0][1] - 4), 8, 8)
    }
    if ($e.name) {
        $mid = [int]($n / 2)
        if ($n % 2 -eq 0) { $mx = ($pts[$mid - 1][0] + $pts[$mid][0]) / 2 } else { $mx = $pts[$mid][0] }
        $my = if ($n % 2 -eq 0) { ($pts[$mid - 1][1] + $pts[$mid][1]) / 2 } else { $pts[$mid][1] }
        Draw-TextBlock $g $e.name $fSmall $bTxt $mx ($my - 9) 130 'center'
    }
}

# ---------- node shapes ----------
function Draw-Marker($g, $kind, $x, $y, $pen) {
    # $x,$y = goc trai tren cua vung 16x16
    switch ($kind) {
        'userTask' {
            $g.DrawEllipse($pen, [single]($x + 4), [single]($y + 1), 7, 7)
            $g.DrawArc($pen, [single]($x + 1), [single]($y + 8), 13, 11, 200, 140)
        }
        'manualTask' {
            $gp = New-Object System.Drawing.Drawing2D.GraphicsPath
            $gp.AddLine($x + 2, $y + 14, $x + 2, $y + 6)
            $gp.AddArc($x + 1, $y + 2, 6, 8, 180, 180)
            $gp.AddLine($x + 7, $y + 5, $x + 12, $y + 5)
            $gp.AddArc($x + 9, $y + 1, 6, 8, 270, 180)
            $gp.AddLine($x + 15, $y + 9, $x + 13, $y + 14)
            $gp.AddLine($x + 13, $y + 14, $x + 2, $y + 14)
            $g.DrawPath($pen, $gp)
        }
        'serviceTask' {
            $g.DrawEllipse($pen, [single]($x + 3), [single]($y + 3), 10, 10)
            $g.DrawEllipse($pen, [single]($x + 6.5), [single]($y + 6.5), 3, 3)
            for ($a = 0; $a -lt 360; $a += 60) {
                $r = $a * [math]::PI / 180
                $g.DrawLine($pen, [single]($x + 8 + 5 * [math]::Cos($r)), [single]($y + 8 + 5 * [math]::Sin($r)), [single]($x + 8 + 7.5 * [math]::Cos($r)), [single]($y + 8 + 7.5 * [math]::Sin($r)))
            }
        }
        'sendTask' {
            $br = New-Object System.Drawing.SolidBrush($black)
            $g.FillRectangle($br, [single]($x + 1), [single]($y + 4), 15, 10)
            $wp = New-Object System.Drawing.SolidBrush($white)
            $g.DrawLine((New-Pen $white 1.2 $false), [single]($x + 2), [single]($y + 5), [single]($x + 8.5), [single]($y + 10))
            $g.DrawLine((New-Pen $white 1.2 $false), [single]($x + 15), [single]($y + 5), [single]($x + 8.5), [single]($y + 10))
        }
    }
}

foreach ($s in $shapes) {
    $x = $s.x; $y = $s.y; $w = $s.w; $h = $s.h; $cx = $x + $w / 2; $cy = $y + $h / 2
    switch ($s.type) {
        'userTask' { $g.FillRectangle($bTask, [single]$x, [single]$y, [single]$w, [single]$h); $g.DrawRectangle($penNode, [single]$x, [single]$y, [single]$w, [single]$h); Draw-Marker $g 'userTask' ($x + 6) ($y + 6) $penNode; Draw-TextBlock $g $s.name $fTask $bTxt $cx ($cy + 3) ($w - 16) 'center' }
        'manualTask' { $g.FillRectangle($bTask, [single]$x, [single]$y, [single]$w, [single]$h); $g.DrawRectangle($penNode, [single]$x, [single]$y, [single]$w, [single]$h); Draw-Marker $g 'manualTask' ($x + 6) ($y + 6) $penNode; Draw-TextBlock $g $s.name $fTask $bTxt $cx ($cy + 3) ($w - 16) 'center' }
        'serviceTask' { $g.FillRectangle($bTask, [single]$x, [single]$y, [single]$w, [single]$h); $g.DrawRectangle($penNode, [single]$x, [single]$y, [single]$w, [single]$h); Draw-Marker $g 'serviceTask' ($x + 6) ($y + 6) $penNode; Draw-TextBlock $g $s.name $fTask $bTxt $cx ($cy + 3) ($w - 16) 'center' }
        'sendTask' { $g.FillRectangle($bTask, [single]$x, [single]$y, [single]$w, [single]$h); $g.DrawRectangle($penNode, [single]$x, [single]$y, [single]$w, [single]$h); Draw-Marker $g 'sendTask' ($x + 6) ($y + 6) $penNode; Draw-TextBlock $g $s.name $fTask $bTxt $cx ($cy + 3) ($w - 16) 'center' }
        'subProcess' {
            $g.FillRectangle($bTask, [single]$x, [single]$y, [single]$w, [single]$h)
            $pen2 = New-Pen $black 1.8 $false
            $g.DrawRectangle($pen2, [single]$x, [single]$y, [single]$w, [single]$h)
            $g.DrawString($s.name, $fSmall, $bTxt, [single]($x + 6), [single]($y + 4))
            $g.DrawRectangle((New-Pen $black 1.2 $false), [single]($cx - 5), [single]($y + $h - 14), 10, 10)
            $g.DrawLine((New-Pen $black 1.2 $false), [single]($cx - 3), [single]($y + $h - 9), [single]($cx + 3), [single]($y + $h - 9))
        }
        'exclusiveGateway' {
            $pts = @((New-Object System.Drawing.PointF([single]$cx, [single]$y)), (New-Object System.Drawing.PointF([single]($x + $w), [single]$cy)), (New-Object System.Drawing.PointF([single]$cx, [single]($y + $h))), (New-Object System.Drawing.PointF([single]$x, [single]$cy)))
            $g.FillPolygon((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 248, 225))), $pts)
            $g.DrawPolygon($penNode, $pts)
            $d = 7
            $g.DrawLine($penNode, [single]($cx - $d), [single]($cy - $d), [single]($cx + $d), [single]($cy + $d))
            $g.DrawLine($penNode, [single]($cx - $d), [single]($cy + $d), [single]($cx + $d), [single]($cy - $d))
        }
        'parallelGateway' {
            $pts = @((New-Object System.Drawing.PointF([single]$cx, [single]$y)), (New-Object System.Drawing.PointF([single]($x + $w), [single]$cy)), (New-Object System.Drawing.PointF([single]$cx, [single]($y + $h))), (New-Object System.Drawing.PointF([single]$x, [single]$cy)))
            $g.FillPolygon((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(228, 240, 228))), $pts)
            $g.DrawPolygon($penNode, $pts)
            $d = 8
            $g.DrawLine($penNode, [single]($cx - $d), [single]$cy, [single]($cx + $d), [single]$cy)
            $g.DrawLine($penNode, [single]$cx, [single]($cy - $d), [single]$cx, [single]($cy + $d))
        }
        'eventBasedGateway' {
            $pts = @((New-Object System.Drawing.PointF([single]$cx, [single]$y)), (New-Object System.Drawing.PointF([single]($x + $w), [single]$cy)), (New-Object System.Drawing.PointF([single]$cx, [single]($y + $h))), (New-Object System.Drawing.PointF([single]$x, [single]$cy)))
            $g.FillPolygon((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(232, 236, 248))), $pts)
            $g.DrawPolygon($penNode, $pts)
            $g.DrawEllipse($penNode, [single]($cx - 7), [single]($cy - 7), 14, 14)
            $g.DrawEllipse($penNode, [single]($cx - 4), [single]($cy - 4), 8, 8)
        }
        'dataObjectReference' {
            $g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 253, 231))), [single]$x, [single]$y, [single]$w, [single]$h)
            $gp = New-Object System.Drawing.Drawing2D.GraphicsPath
            $gp.AddLine($x, $y, $x + $w - 10, $y)
            $gp.AddLine($x + $w - 10, $y, $x + $w, $y + 10)
            $gp.AddLine($x + $w, $y + 10, $x + $w, $y + $h)
            $gp.AddLine($x + $w, $y + $h, $x, $y + $h)
            $gp.CloseFigure()
            $g.DrawPath($penNode, $gp)
            $g.DrawLine($penNode, [single]($x + $w - 10), [single]$y, [single]($x + $w - 10), [single]($y + 10))
            $g.DrawLine($penNode, [single]($x + $w - 10), [single]($y + 10), [single]($x + $w), [single]($y + 10))
            Draw-TextBlock $g $s.name $fSmall $bTxt $cx ($y + $h + 12) 120 'center'
        }
        'dataStoreReference' {
            $eb = 8
            $g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 253, 231))), [single]$x, [single]($y + $eb), [single]$w, [single]($h - $eb))
            $g.FillEllipse((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 253, 231))), [single]$x, [single]$y, [single]$w, [single]$eb * 2)
            $g.DrawEllipse($penNode, [single]$x, [single]$y, [single]$w, [single]$eb * 2)
            $g.DrawArc($penNode, [single]$x, [single]($y + $h - $eb * 2), [single]$w, [single]$eb * 2, 0, 180)
            $g.DrawLine($penNode, [single]$x, [single]($y + $eb), [single]$x, [single]($y + $h - $eb))
            $g.DrawLine($penNode, [single]($x + $w), [single]($y + $eb), [single]($x + $w), [single]($y + $h - $eb))
            Draw-TextBlock $g $s.name $fSmall $bTxt $cx ($y + $h + 12) 120 'center'
        }
        default {
            if ($s.type -match 'Event$' -or $s.type -eq 'boundaryEvent') {
                $r = $w / 2
                $isEnd = ($s.type -eq 'endEvent')
                $fill = if ($s.type -eq 'startEvent') { [System.Drawing.Color]::FromArgb(232, 245, 232) } else { $white }
                $g.FillEllipse((New-Object System.Drawing.SolidBrush($fill)), [single]$x, [single]$y, [single]$w, [single]$h)
                $pw = if ($isEnd) { 2.6 } else { 1.4 }
                $g.DrawEllipse((New-Pen $black $pw $false), [single]$x, [single]$y, [single]$w, [single]$h)
                $ev = $null
                if ($s.id) { $ev = $doc.SelectSingleNode("//*[@id='$($s.id)']/*[local-name()='timerEventDefinition' or local-name()='messageEventDefinition' or local-name()='errorEventDefinition']") }
                $kind = if ($ev) { $ev.LocalName } else { '' }
                if ($kind -eq 'timerEventDefinition') {
                    $g.DrawEllipse($penNode, [single]($cx - 8), [single]($cy - 8), 16, 16)
                    $g.DrawLine($penNode, [single]$cx, [single]$cy, [single]$cx, [single]($cy - 5))
                    $g.DrawLine($penNode, [single]$cx, [single]$cy, [single]($cx + 4), [single]($cy + 2))
                } elseif ($kind -eq 'messageEventDefinition') {
                    $g.DrawRectangle($penNode, [single]($cx - 9), [single]($cy - 6), 18, 12)
                    $g.DrawLine($penNode, [single]($cx - 9), [single]($cy - 6), [single]$cx, [single]($cy + 1))
                    $g.DrawLine($penNode, [single]($cx + 9), [single]($cy - 6), [single]$cx, [single]($cy + 1))
                } elseif ($kind -eq 'errorEventDefinition') {
                    $pts = @(
                        (New-Object System.Drawing.PointF([single]($cx + 2), [single]($cy - 9))),
                        (New-Object System.Drawing.PointF([single]($cx - 6), [single]($cy + 1))),
                        (New-Object System.Drawing.PointF([single]($cx), [single]($cy + 1))),
                        (New-Object System.Drawing.PointF([single]($cx - 3), [single]($cy + 9))),
                        (New-Object System.Drawing.PointF([single]($cx + 7), [single]($cy - 2))),
                        (New-Object System.Drawing.PointF([single]($cx + 1), [single]($cy - 2))))
                    $g.FillPolygon((New-Object System.Drawing.SolidBrush($black)), $pts)
                }
                if ($s.type -eq 'boundaryEvent') {
                    $g.DrawEllipse((New-Pen $black 1.0 $false), [single]($x - 2), [single]($y - 2), ($w + 4), ($h + 4))
                }
                if ($s.name) { Draw-TextBlock $g $s.name $fSmall $bTxt $cx ($y + $h + 14) 110 'center' }
            } else {
                if ($s.name) { Draw-TextBlock $g $s.name $fGw $bTxt $cx ($y + $h + 14) 120 'center' }
            }
        }
    }
}

$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
"PNG $Out  ${imgW}x${imgH}"
