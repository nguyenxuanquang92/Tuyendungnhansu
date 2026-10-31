$ErrorActionPreference = 'Stop'
# Kiem thu tu dong cho ung dung tuyen dung (MIS3047 - Nhom 8)
# Chay: powershell -ExecutionPolicy Bypass -File tools\Test-App.ps1
# Script tu khoi dong mot may chu rieng voi du lieu sach, chay cac kich ban, roi tat.

$root = Split-Path -Parent $PSScriptRoot
$dataDir = Join-Path $root 'app\data-test'
if (Test-Path $dataDir) { Remove-Item $dataDir -Recurse -Force }
$port = 8091
$base = "http://localhost:$port"

$srv = Start-Process -FilePath 'powershell.exe' -PassThru -WindowStyle Hidden -ArgumentList @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass',
    '-File', (Join-Path $root 'app\server.ps1'),
    '-Port', $port, '-DataDir', $dataDir
)

$script:pass = 0
$script:fail = 0

function Check([string]$name, [scriptblock]$body) {
    try {
        & $body
        $script:pass++
        Write-Host ("  [PASS] " + $name) -ForegroundColor Green
    } catch {
        $script:fail++
        Write-Host ("  [FAIL] " + $name + " -> " + $_.Exception.Message) -ForegroundColor Red
    }
}

function Assert-Equal($actual, $expected, [string]$what) {
    if ("$actual" -ne "$expected") { throw "${what}: mong doi '$expected', nhan '$actual'" }
}

function Assert-True($cond, [string]$what) {
    if (-not $cond) { throw $what }
}

function Login([string]$u) {
    $r = Invoke-RestMethod -Uri "$base/api/login" -Method Post -ContentType 'application/json' `
        -Body (@{ username = $u; password = 'Demo@123' } | ConvertTo-Json)
    return $r.token
}

function Api([string]$token, [string]$method, [string]$path, $body) {
    $h = @{ Authorization = "Bearer $token" }
    if ($null -ne $body) {
        return Invoke-RestMethod -Uri "$base/api$path" -Method $method -Headers $h -ContentType 'application/json' `
            -Body ($body | ConvertTo-Json -Depth 6)
    }
    return Invoke-RestMethod -Uri "$base/api$path" -Method $method -Headers $h
}

function Expect-Status([string]$token, [string]$method, [string]$path, $body, [int]$status) {
    $h = @{ }
    if ($token) { $h.Authorization = "Bearer $token" }
    try {
        if ($null -ne $body) {
            Invoke-RestMethod -Uri "$base/api$path" -Method $method -Headers $h -ContentType 'application/json' `
                -Body ($body | ConvertTo-Json -Depth 6) | Out-Null
        } else {
            Invoke-RestMethod -Uri "$base/api$path" -Method $method -Headers $h | Out-Null
        }
        throw "Khong nhan duoc loi HTTP $status"
    } catch {
        $code = $null
        if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
        if ($code -ne $status) { throw "Mong doi HTTP $status, nhan $code ($($_.Exception.Message))" }
    }
}

# ---- cho may chu san sang ----
$ready = $false
for ($i = 0; $i -lt 40; $i++) {
    try { Invoke-WebRequest -Uri "$base/" -UseBasicParsing -TimeoutSec 2 | Out-Null; $ready = $true; break } catch { Start-Sleep -Milliseconds 500 }
}
if (-not $ready) { if (-not $srv.HasExited) { $srv.Kill() }; throw 'May chu kiem thu khong khoi dong duoc' }

try {
    Write-Host ''
    Write-Host '=== 1. Xac thuc va phan quyen ===' -ForegroundColor Cyan
    Check 'Dang nhap sai mat khau bi tu choi (401)' {
        Expect-Status $null 'POST' '/login' @{ username = 'nhansu'; password = 'sai' } 401
    }
    Check 'Goi API khong co token bi tu choi (401)' {
        Expect-Status $null 'GET' '/requests' $null 401
    }
    Check 'Dang nhap dung tra ve token va ho so nguoi dung' {
        $r = Invoke-RestMethod -Uri "$base/api/login" -Method Post -ContentType 'application/json' `
            -Body (@{ username = 'nhansu'; password = 'Demo@123' } | ConvertTo-Json)
        Assert-True ($r.token.Length -ge 20) 'Token qua ngan'
        Assert-Equal $r.user.role 'nhansu' 'Vai tro'
        Assert-Equal $r.user.name 'Lê Thị Mai' 'Ho ten'
    }

    $tp = Login 'truongphong'
    $ns = Login 'nhansu'
    $gd = Login 'giamdoc'

    Check 'Truong phong khong duoc duyet JD (403)' {
        Expect-Status $tp 'POST' '/requests/YC-001/action' @{ action = 'duyet_jd' } 403
    }
    Check 'Nhan su khong duoc tao yeu cau (403)' {
        Expect-Status $ns 'POST' '/requests' @{ title = 'x'; reason = 'y'; headcount = 1; salaryMin = 1; salaryMax = 2 } 403
    }
    Check 'Giam doc khong duoc sang loc ho so (403)' {
        Expect-Status $gd 'POST' '/requests/YC-003/screen' @{ years = 3; degree = 'daihoc'; expected = 1; skill = $true } 403
    }

    Write-Host ''
    Write-Host '=== 2. Luong XOR 1: kiem tra yeu cau ===' -ForegroundColor Cyan
    Check 'YC-002 dang cho bo sung: truong phong gui lai' {
        $r = Api $tp 'POST' '/requests/YC-002/action' @{ action = 'bo_sung_lai'; note = 'Da bo sung' }
        Assert-Equal $r.status 'CHO_KIEM_TRA' 'Trang thai'
    }
    Check 'Nhan su phat hien van thieu, yeu cau bo sung lai' {
        $r = Api $ns 'POST' '/requests/YC-002/action' @{ action = 'kiem_tra_thieu'; note = 'Thieu JD' }
        Assert-Equal $r.status 'CHO_BO_SUNG' 'Trang thai'
    }
    Check 'Truong phong bo sung lan hai' {
        $r = Api $tp 'POST' '/requests/YC-002/action' @{ action = 'bo_sung_lai'; note = 'Da bo sung day du' }
        Assert-Equal $r.status 'CHO_KIEM_TRA' 'Trang thai'
    }
    Check 'Nhan su xac nhan day du' {
        $r = Api $ns 'POST' '/requests/YC-002/action' @{ action = 'kiem_tra_dat'; note = 'Day du' }
        Assert-Equal $r.status 'CHO_SOAN_JD' 'Trang thai'
    }
    Check 'Khong the kiem tra lai khi da qua buoc (409)' {
        Expect-Status $ns 'POST' '/requests/YC-002/action' @{ action = 'kiem_tra_dat' } 409
    }

    Write-Host ''
    Write-Host '=== 3. Luong XOR 2: duyet JD ===' -ForegroundColor Cyan
    Check 'Luu JD khi thieu noi dung bi tu choi (400)' {
        Expect-Status $ns 'POST' '/requests/YC-002/action' @{ action = 'luu_jd'; moTa = ''; yeuCau = '' } 400
    }
    Check 'Nhan su luu JD va trinh duyet' {
        $r = Api $ns 'POST' '/requests/YC-002/action' @{
            action = 'luu_jd'; moTa = 'Trien khai chien dich'; yeuCau = 'Dai hoc, 2 nam'; quyenLoi = '14 trieu'
        }
        Assert-Equal $r.status 'CHO_DUYET_JD' 'Trang thai'
        Assert-Equal $r.jd.moTa 'Trien khai chien dich' 'JD da luu'
    }
    Check 'Giam doc tu choi JD quay ve buoc soan' {
        $r = Api $gd 'POST' '/requests/YC-002/action' @{ action = 'tu_choi_jd'; note = 'Can bo sung KPI' }
        Assert-Equal $r.status 'CHO_SOAN_JD' 'Trang thai'
    }
    Check 'Nhan su soan lai va trinh lai' {
        $r = Api $ns 'POST' '/requests/YC-002/action' @{ action = 'luu_jd'; moTa = 'Trien khai da kenh'; yeuCau = 'Dai hoc'; quyenLoi = '14 trieu' }
        Assert-Equal $r.status 'CHO_DUYET_JD' 'Trang thai'
    }
    Check 'Giam doc duyet JD chuyen sang dang tuyen' {
        $r = Api $gd 'POST' '/requests/YC-002/action' @{ action = 'duyet_jd'; note = 'Dong y' }
        Assert-Equal $r.status 'DANG_TUYEN' 'Trang thai'
    }

    Write-Host ''
    Write-Host '=== 4. Sang loc theo nguong tin cay (muc 3.2) ===' -ForegroundColor Cyan
    Check 'Ho so rat phu hop duoc tu dong duyet (p >= 92%)' {
        $r = Api $ns 'POST' '/requests/YC-002/screen' @{ years = 8; degree = 'daihoc'; expected = 14000000; skill = $true }
        Assert-True ($r.p -ge 0.92) "p = $($r.p)"
        Assert-Equal $r.decision 'TU_DONG_DUYET' 'Quyet dinh'
    }
    Check 'Ho so trung binh chuyen HR xem xet' {
        $r = Api $ns 'POST' '/requests/YC-002/screen' @{ years = 2; degree = 'caodang'; expected = 14000000; skill = $false }
        Assert-True ($r.p -ge 0.5 -and $r.p -lt 0.92) "p = $($r.p)"
        Assert-Equal $r.decision 'CHO_HR' 'Quyet dinh'
    }
    Check 'Ho so yeu roi vao vung cam, bat buoc HR' {
        $r = Api $ns 'POST' '/requests/YC-002/screen' @{ years = 0; degree = 'khac'; expected = 14000000; skill = $false }
        Assert-True ($r.p -lt 0.5) "p = $($r.p)"
        Assert-Equal $r.decision 'CHO_HR' 'Quyet dinh'
    }
    Check 'Luong ky vong vuot khung 15% bi tu dong loai' {
        $r = Api $ns 'POST' '/requests/YC-002/screen' @{ years = 9; degree = 'daihoc'; expected = 30000000; skill = $true }
        Assert-Equal $r.decision 'TU_DONG_LOAI' 'Quyet dinh'
    }
    Check 'Luu ho so ung vien vao yeu cau (luu tru ben vung)' {
        $c = Api $ns 'POST' '/requests/YC-002/candidates' @{
            name = 'Nguyen Van Test'; email = 'test@example.com'; years = 8; degree = 'daihoc'; expected = 14000000; skill = $true
        }
        Assert-Equal $c.status 'TU_DONG_DUYET' 'Quyet dinh luu'
        $r = Api $ns 'GET' '/requests/YC-002' $null
        Assert-Equal @($r.candidates).Count 1 'So ho so'
        $hist = @($r.history)[-1]
        Assert-Equal $hist.action 'sang_loc_ho_so' 'Nhat ky'
    }

    Write-Host ''
    Write-Host '=== 5. Luong XOR 3: phe duyet nhan su ===' -ForegroundColor Cyan
    Check 'Nhan su trinh phe duyet ket qua' {
        $r = Api $ns 'POST' '/requests/YC-002/action' @{ action = 'trinh_phe_duyet'; note = 'Da co 1 UV dat' }
        Assert-Equal $r.status 'CHO_PHE_DUYET_NS' 'Trang thai'
    }
    Check 'Giam doc phe duyet, quy trinh hoan tat' {
        $r = Api $gd 'POST' '/requests/YC-002/action' @{ action = 'duyet_ns'; note = 'Dong y tuyen' }
        Assert-Equal $r.status 'HOAN_TAT' 'Trang thai'
    }
    Check 'Khong the thao tac tiep tren ho so da dong (409)' {
        Expect-Status $gd 'POST' '/requests/YC-002/action' @{ action = 'tu_choi_ns' } 409
    }
    Check 'Tao moi yeu cau tu truong phong' {
        $r = Api $tp 'POST' '/requests' @{
            title = 'Nhan vien Thu kho'; reason = 'Mo rong kho'; headcount = 2
            salaryMin = 8000000; salaryMax = 10000; priority = 'Thap'
        }
        Assert-Equal $r.status 'CHO_KIEM_TRA' 'Trang thai ban dau'
        Assert-True ($r.id -like 'YC-*') 'Ma yeu cau'
    }

    Write-Host ''
    Write-Host '=== 6. Luu tru ben vung va nhat ky ===' -ForegroundColor Cyan
    Check 'Du lieu duoc ghi ra tep db.json' {
        $f = Join-Path $dataDir 'db.json'
        Assert-True (Test-Path $f) 'Khong thay db.json'
        $db = Get-Content -Raw -Encoding UTF8 $f | ConvertFrom-Json
        Assert-True (@($db.requests).Count -ge 4) 'So yeu cau trong tep'
        $r2 = $db.requests | Where-Object { $_.id -eq 'YC-002' }
        Assert-Equal $r2.status 'HOAN_TAT' 'Trang thai trong tep'
        Assert-True (@($r2.history).Count -ge 8) 'So buoc nhat ky'
    }
    Check 'Mat khau khong luu dang van ban thuan' {
        $db = Get-Content -Raw -Encoding UTF8 (Join-Path $dataDir 'db.json') | ConvertFrom-Json
        foreach ($u in $db.users) { Assert-True ($u.pwd -ne 'Demo@123') "Tai khoan $($u.username) luu mat khau thuong" }
    }
} finally {
    if (-not $srv.HasExited) { $srv.Kill(); $srv.WaitForExit(3000) }
    if (Test-Path $dataDir) { Remove-Item $dataDir -Recurse -Force -ErrorAction SilentlyContinue }
}

Write-Host ''
Write-Host ("=== KET QUA: " + $script:pass + " PASS / " + $script:fail + " FAIL ===") -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Red' })
if ($script:fail -gt 0) { exit 1 }
