$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'BpmnLib.ps1')
. (Join-Path $PSScriptRoot 'models\AsIs.ps1')

$model = Get-ModelAsIs
$out = Join-Path $root 'bpmn\as-is\as-is.bpmn'
$len = Write-BpmnXml $model $out
"WROTE $out ($len chars)"

[xml]$x = Get-Content -Raw -Encoding UTF8 $out
$ns = New-Object System.Xml.XmlNamespaceManager($x.NameTable)
$ns.AddNamespace('b', 'http://www.omg.org/spec/BPMN/20100524/MODEL')
foreach ($t in @('lane', 'exclusiveGateway', 'parallelGateway', 'eventBasedGateway', 'dataObjectReference', 'dataStoreReference', 'boundaryEvent', 'subProcess', 'intermediateCatchEvent', 'timerEventDefinition', 'errorEventDefinition', 'userTask', 'manualTask', 'serviceTask', 'sendTask', 'sequenceFlow', 'messageFlow')) {
    $n = $x.SelectNodes("//b:$t", $ns).Count
    "{0,-26} {1}" -f $t, $n
}
