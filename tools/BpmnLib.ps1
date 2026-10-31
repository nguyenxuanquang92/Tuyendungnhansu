# BpmnLib.ps1 - Sinh BPMN 2.0 XML co DI tu mo hinh khai bao
# Khong phu thuoc thu vien ngoai. Chay tren Windows PowerShell 5.1.

function Get-NodeBounds($n) {
    return @{ cx = [double]$n.x + [double]$n.w / 2; cy = [double]$n.y + [double]$n.h / 2 }
}

function Get-Route($s, $t) {
    $sb = Get-NodeBounds $s; $tb = Get-NodeBounds $t
    $sx = $sb.cx; $sy = $sb.cy; $tx = $tb.cx; $ty = $tb.cy
    $dx = $tx - $sx; $dy = $ty - $sy
    $pts = New-Object System.Collections.ArrayList

    if ([math]::Abs($dy) -lt 12) {
        if ($dx -ge 0) { [void]$pts.Add(@(($s.x + $s.w), $sy)); [void]$pts.Add(@($t.x, $ty)) }
        else { [void]$pts.Add(@($s.x, $sy)); [void]$pts.Add(@(($t.x + $t.w), $ty)) }
        return $pts
    }
    if ([math]::Abs($dx) -lt 70) {
        if ($dy -ge 0) {
            [void]$pts.Add(@($sx, ($s.y + $s.h))); [void]$pts.Add(@($tx, $t.y))
        } else {
            [void]$pts.Add(@($sx, $s.y)); [void]$pts.Add(@($tx, ($t.y + $t.h)))
        }
        return $pts
    }
    if ([math]::Abs($dx) -ge [math]::Abs($dy)) {
        if ($dx -ge 0) { $ex = $s.x + $s.w; $nx = $t.x } else { $ex = $s.x; $nx = $t.x + $t.w }
        $mid = [math]::Round(($ex + $nx) / 2)
        [void]$pts.Add(@($ex, $sy)); [void]$pts.Add(@($mid, $sy)); [void]$pts.Add(@($mid, $ty)); [void]$pts.Add(@($nx, $ty))
        return $pts
    }
    if ($dy -ge 0) { $ey = $s.y + $s.h; $ny = $t.y } else { $ey = $s.y; $ny = $t.y + $t.h }
    $mid = [math]::Round(($ey + $ny) / 2)
    [void]$pts.Add(@($sx, $ey)); [void]$pts.Add(@($sx, $mid)); [void]$pts.Add(@($tx, $mid)); [void]$pts.Add(@($tx, $ny))
    return $pts
}

function Esc([string]$s) {
    if ($null -eq $s) { return '' }
    return $s.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;')
}

function Write-BpmnXml($model, [string]$path) {
    $sb = New-Object System.Text.StringBuilder
    $w = { param($s) [void]$sb.AppendLine($s) }

    $nodes = @{}
    foreach ($n in $model.nodes) { $nodes[$n.id] = $n }

    $incoming = @{}; $outgoing = @{}
    foreach ($f in $model.flows) {
        if (-not $outgoing.ContainsKey($f.from)) { $outgoing[$f.from] = New-Object System.Collections.ArrayList }
        if (-not $incoming.ContainsKey($f.to)) { $incoming[$f.to] = New-Object System.Collections.ArrayList }
        [void]$outgoing[$f.from].Add($f.id)
        [void]$incoming[$f.to].Add($f.id)
    }

    & $w '<?xml version="1.0" encoding="UTF-8"?>'
    & $w '<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI" xmlns:dc="http://www.omg.org/spec/DD/20100524/DC" xmlns:di="http://www.omg.org/spec/DD/20100524/DI" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" id="Definitions_ASIS_TuyenDung" targetNamespace="http://bpmn.io/schema/bpmn" exporter="Nhom8 MIS3047" exporterVersion="1.0">'

    foreach ($e in $model.errors) {
        & $w ('  <bpmn:error id="{0}" name="{1}" errorCode="{2}" />' -f $e.id, (Esc $e.name), $e.code)
    }
    foreach ($m in $model.messages) {
        & $w ('  <bpmn:message id="{0}" name="{1}" />' -f $m.id, (Esc $m.name))
    }

    & $w ('  <bpmn:collaboration id="{0}">' -f $model.collaboration)
    foreach ($p in $model.pools) {
        & $w ('    <bpmn:participant id="{0}" name="{1}" processRef="{2}" />' -f $p.id, (Esc $p.name), $p.process)
    }
    foreach ($mf in $model.messageFlows) {
        if ($mf.name) {
            & $w ('    <bpmn:messageFlow id="{0}" name="{1}" sourceRef="{2}" targetRef="{3}" />' -f $mf.id, (Esc $mf.name), $mf.from, $mf.to)
        } else {
            & $w ('    <bpmn:messageFlow id="{0}" sourceRef="{1}" targetRef="{2}" />' -f $mf.id, $mf.from, $mf.to)
        }
    }
    & $w '  </bpmn:collaboration>'

    foreach ($proc in $model.processes) {
        & $w ('  <bpmn:process id="{0}" name="{1}" isExecutable="false">' -f $proc.id, (Esc $proc.name))
        if ($proc.lanes -and $proc.lanes.Count -gt 0) {
            & $w ('    <bpmn:laneSet id="{0}">' -f $proc.laneSet)
            foreach ($ln in $proc.lanes) {
                & $w ('      <bpmn:lane id="{0}" name="{1}">' -f $ln.id, (Esc $ln.name))
                foreach ($n in ($model.nodes | Where-Object { $_.process -eq $proc.id -and $_.lane -eq $ln.id -and -not $_.nested })) {
                    & $w ('        <bpmn:flowNodeRef>{0}</bpmn:flowNodeRef>' -f $n.id)
                }
                & $w '      </bpmn:lane>'
            }
            & $w '    </bpmn:laneSet>'
        }

        foreach ($n in ($model.nodes | Where-Object { $_.process -eq $proc.id -and -not $_.parent })) {
            $in = ''; $out = ''; $emitted = $false
            if ($incoming.ContainsKey($n.id)) { foreach ($x in $incoming[$n.id]) { $in += ('      <bpmn:incoming>{0}</bpmn:incoming>' -f $x) + "`r`n" } }
            if ($outgoing.ContainsKey($n.id)) { foreach ($x in $outgoing[$n.id]) { $out += ('      <bpmn:outgoing>{0}</bpmn:outgoing>' -f $x) + "`r`n" } }
            $nm = Esc $n.name
            switch ($n.kind) {
                'startEvent' { & $w ('    <bpmn:startEvent id="{0}" name="{1}">' -f $n.id, $nm) }
                'endEvent'   { & $w ('    <bpmn:endEvent id="{0}" name="{1}">' -f $n.id, $nm) }
                'userTask'   { & $w ('    <bpmn:userTask id="{0}" name="{1}">' -f $n.id, $nm) }
                'manualTask' { & $w ('    <bpmn:manualTask id="{0}" name="{1}">' -f $n.id, $nm) }
                'serviceTask'{ & $w ('    <bpmn:serviceTask id="{0}" name="{1}">' -f $n.id, $nm) }
                'sendTask'   { & $w ('    <bpmn:sendTask id="{0}" name="{1}">' -f $n.id, $nm) }
                'exclusiveGateway' { & $w ('    <bpmn:exclusiveGateway id="{0}" name="{1}">' -f $n.id, $nm) }
                'parallelGateway'  { & $w ('    <bpmn:parallelGateway id="{0}" name="{1}">' -f $n.id, $nm) }
                'eventBasedGateway'{ & $w ('    <bpmn:eventBasedGateway id="{0}" name="{1}">' -f $n.id, $nm) }
                'dataObjectRef' {
                    & $w ('    <bpmn:dataObject id="DO_{0}" />' -f $n.id)
                    & $w ('    <bpmn:dataObjectReference id="{0}" name="{1}" dataObjectRef="DO_{0}" />' -f $n.id, $nm)
                    $emitted = $true
                }
                'dataStoreRef'  { & $w ('    <bpmn:dataStoreReference id="{0}" name="{1}" />' -f $n.id, $nm); $emitted = $true }
                'subProcess' { & $w ('    <bpmn:subProcess id="{0}" name="{1}" triggeredByEvent="true">' -f $n.id, $nm) }
                'boundaryTimerNI' {
                    & $w ('    <bpmn:boundaryEvent id="{0}" name="{1}" attachedToRef="{2}" cancelActivity="false">' -f $n.id, $nm, $n.attach)
                    & $w ($in.TrimEnd())
                    & $w ($out.TrimEnd())
                    & $w ('      <bpmn:timerEventDefinition id="TED_{0}"><bpmn:timeDuration>{1}</bpmn:timeDuration></bpmn:timerEventDefinition>' -f $n.id, $n.duration)
                    & $w '    </bpmn:boundaryEvent>'
                    $emitted = $true
                }
                'boundaryError' {
                    & $w ('    <bpmn:boundaryEvent id="{0}" name="{1}" attachedToRef="{2}">' -f $n.id, $nm, $n.attach)
                    & $w ($in.TrimEnd())
                    & $w ($out.TrimEnd())
                    & $w ('      <bpmn:errorEventDefinition id="EED_{0}" errorRef="{1}" />' -f $n.id, $n.error)
                    & $w '    </bpmn:boundaryEvent>'
                    $emitted = $true
                }
                default { & $w ('    <bpmn:intermediateCatchEvent id="{0}" name="{1}">' -f $n.id, $nm) }
            }
            if ($emitted) { continue }
            if ($in.Trim().Length -gt 0) { & $w ($in.TrimEnd()) }
            if ($out.Trim().Length -gt 0) { & $w ($out.TrimEnd()) }
            if ($n.kind -eq 'intermediateCatchTimer') {
                & $w ('      <bpmn:timerEventDefinition id="TED_{0}"><bpmn:timeDuration>{1}</bpmn:timeDuration></bpmn:timerEventDefinition>' -f $n.id, $n.duration)
            }
            if ($n.kind -eq 'intermediateCatchMessage') {
                & $w ('      <bpmn:messageEventDefinition id="MED_{0}" messageRef="{1}" />' -f $n.id, $n.message)
            }
            if ($n.kind -eq 'startMessage') {
                & $w ('      <bpmn:messageEventDefinition id="MED_{0}" messageRef="{1}" />' -f $n.id, $n.message)
            }
            if ($n.kind -eq 'subProcess') {
                foreach ($c in ($model.nodes | Where-Object { $_.parent -eq $n.id })) {
                    $ci = ''; $co = ''
                    if ($incoming.ContainsKey($c.id)) { foreach ($x in $incoming[$c.id]) { $ci += ('        <bpmn:incoming>{0}</bpmn:incoming>' -f $x) + "`r`n" } }
                    if ($outgoing.ContainsKey($c.id)) { foreach ($x in $outgoing[$c.id]) { $co += ('        <bpmn:outgoing>{0}</bpmn:outgoing>' -f $x) + "`r`n" } }
                    $ct = @{ 'startMessage' = 'startEvent'; 'sendTask' = 'sendTask'; 'endEvent' = 'endEvent'; 'userTask' = 'userTask'; 'manualTask' = 'manualTask' }[$c.kind]
                    $attr = ''
                    if ($c.kind -eq 'startMessage') { $attr = ' isInterrupting="true"' }
                    & $w ('      <bpmn:{0} id="{1}" name="{2}"{3}>' -f $ct, $c.id, (Esc $c.name), $attr)
                    if ($ci.Trim().Length -gt 0) { & $w ($ci.TrimEnd()) }
                    if ($co.Trim().Length -gt 0) { & $w ($co.TrimEnd()) }
                    if ($c.kind -eq 'startMessage') {
                        & $w ('        <bpmn:messageEventDefinition id="MED_{0}" messageRef="{1}" />' -f $c.id, $c.message)
                    }
                    & $w ('      </bpmn:{0}>' -f $ct)
                }
                foreach ($cf in ($model.flows | Where-Object { $_.parent -eq $n.id })) {
                    if ($cf.name) {
                        & $w ('      <bpmn:sequenceFlow id="{0}" name="{1}" sourceRef="{2}" targetRef="{3}" />' -f $cf.id, (Esc $cf.name), $cf.from, $cf.to)
                    } else {
                        & $w ('      <bpmn:sequenceFlow id="{0}" sourceRef="{1}" targetRef="{2}" />' -f $cf.id, $cf.from, $cf.to)
                    }
                }
            }
            $tag = @{
                'startEvent' = 'startEvent'; 'startMessage' = 'startEvent'; 'endEvent' = 'endEvent'
                'userTask' = 'userTask'; 'manualTask' = 'manualTask'; 'serviceTask' = 'serviceTask'; 'sendTask' = 'sendTask'
                'exclusiveGateway' = 'exclusiveGateway'; 'parallelGateway' = 'parallelGateway'; 'eventBasedGateway' = 'eventBasedGateway'
                'intermediateCatchTimer' = 'intermediateCatchEvent'; 'intermediateCatchMessage' = 'intermediateCatchEvent'
                'subProcess' = 'subProcess'
            }[$n.kind]
            & $w ('    </bpmn:{0}>' -f $tag)
        }

        foreach ($f in ($model.flows | Where-Object { $_.process -eq $proc.id -and -not $_.parent })) {
            if ($f.name) {
                & $w ('    <bpmn:sequenceFlow id="{0}" name="{1}" sourceRef="{2}" targetRef="{3}" />' -f $f.id, (Esc $f.name), $f.from, $f.to)
            } else {
                & $w ('    <bpmn:sequenceFlow id="{0}" sourceRef="{1}" targetRef="{2}" />' -f $f.id, $f.from, $f.to)
            }
        }
        & $w '  </bpmn:process>'
    }

    # ---- DI ----
    & $w '  <bpmndi:BPMNDiagram id="BPMNDiagram_1">'
    & $w ('    <bpmndi:BPMNPlane id="BPMNPlane_1" bpmnElement="{0}">' -f $model.collaboration)
    foreach ($p in $model.pools) {
        & $w ('      <bpmndi:BPMNShape id="{0}_di" bpmnElement="{0}" isHorizontal="true">' -f $p.id)
        & $w ('        <dc:Bounds x="{0}" y="{1}" width="{2}" height="{3}" />' -f $p.x, $p.y, $p.w, $p.h)
        & $w '      </bpmndi:BPMNShape>'
        foreach ($ln in $p.lanes) {
            & $w ('      <bpmndi:BPMNShape id="{0}_di" bpmnElement="{0}">' -f $ln.id)
            & $w ('        <dc:Bounds x="{0}" y="{1}" width="{2}" height="{3}" />' -f $ln.x, $ln.y, $ln.w, $ln.h)
            & $w '      </bpmndi:BPMNShape>'
        }
    }
    foreach ($n in $model.nodes) {
        & $w ('      <bpmndi:BPMNShape id="{0}_di" bpmnElement="{0}">' -f $n.id)
        & $w ('        <dc:Bounds x="{0}" y="{1}" width="{2}" height="{3}" />' -f $n.x, $n.y, $n.w, $n.h)
        & $w '      </bpmndi:BPMNShape>'
    }
    foreach ($f in $model.flows) {
        $s = $nodes[$f.from]; $t = $nodes[$f.to]
        if ($f.points) { $pts = $f.points } else { $pts = Get-Route $s $t }
        & $w ('      <bpmndi:BPMNEdge id="{0}_di" bpmnElement="{0}">' -f $f.id)
        foreach ($pt in $pts) { & $w ('        <di:waypoint x="{0}" y="{1}" />' -f $pt[0], $pt[1]) }
        & $w '      </bpmndi:BPMNEdge>'
    }
    foreach ($mf in $model.messageFlows) {
        $s = $nodes[$mf.from]; $t = $nodes[$mf.to]
        if ($mf.points) { $pts = $mf.points } else { $pts = Get-Route $s $t }
        & $w ('      <bpmndi:BPMNEdge id="{0}_di" bpmnElement="{0}">' -f $mf.id)
        foreach ($pt in $pts) { & $w ('        <di:waypoint x="{0}" y="{1}" />' -f $pt[0], $pt[1]) }
        & $w '      </bpmndi:BPMNEdge>'
    }
    & $w '    </bpmndi:BPMNPlane>'
    & $w '  </bpmndi:BPMNDiagram>'
    & $w '</bpmn:definitions>'

    $text = $sb.ToString()
    [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
    return $text.Length
}
