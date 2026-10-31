# server.ps1 - Web server cho ung dung tuyen dung (khong can cai dat runtime)
# Chay: powershell -ExecutionPolicy Bypass -File app\server.ps1
param(
    [int]$Port = 8090,
    [string]$DataDir = ''
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$public = Join-Path $PSScriptRoot 'public'
if (-not $DataDir) { $DataDir = Join-Path $PSScriptRoot 'data' }
if (-not (Test-Path $DataDir)) { New-Item -ItemType Directory -Force -Path $DataDir | Out-Null }
$dbFile = Join-Path $DataDir 'db.json'

# ---------------- du lieu ----------------
function New-Seed {
    $now = (Get-Date).ToString('s')
    return [ordered]@{
        meta     = [ordered]@{ version = 1; created = $now; seq = 3 }
        users    = @(
            [ordered]@{ username = 'truongphong'; name = 'Trần Văn Hùng'; role = 'truongphong'; dept = 'Phòng Kinh doanh'; pwd = (Get-Hash 'Demo@123') },
            [ordered]@{ username = 'nhansu';      name = 'Lê Thị Mai';    role = 'nhansu';      dept = 'Phòng Nhân sự';   pwd = (Get-Hash 'Demo@123') },
            [ordered]@{ username = 'giamdoc';     name = 'Nguyễn Quốc Bảo'; role = 'giamdoc';   dept = 'Ban Giám đốc';    pwd = (Get-Hash 'Demo@123') }
        )
        requests = @(
            [ordered]@{
                id = 'YC-001'; title = 'Nhân viên Kinh doanh'; dept = 'Phòng Kinh doanh'
                headcount = 3; salaryMin = 9000000; salaryMax = 12000000; priority = 'Cao'
                reason = 'Mở rộng thị trường khu vực miền Nam, hai nhân sự hiện tại đã quá tải.'
                status = 'CHO_DUYET_JD'; createdBy = 'truongphong'; createdAt = $now
                jd = [ordered]@{ moTa = 'Tư vấn và bán hàng trực tiếp, chăm sóc khách hàng doanh nghiệp.'; yeuCau = 'Tốt nghiệp Cao đẳng trở lên; 1 năm kinh nghiệm bán hàng B2B; giao tiếp tốt.'; quyenLoi = 'Lương 9-12 triệu + hoa hồng; BHXH đầy đủ.' }
                candidates = @()
                history = @(
                    [ordered]@{ at = $now; by = 'truongphong'; actor = 'Trần Văn Hùng'; action = 'tao_yeu_cau'; note = 'Khởi tạo yêu cầu tuyển dụng' },
                    [ordered]@{ at = $now; by = 'nhansu'; actor = 'Lê Thị Mai'; action = 'kiem_tra_dat'; note = 'Yêu cầu đầy đủ thông tin' },
                    [ordered]@{ at = $now; by = 'nhansu'; actor = 'Lê Thị Mai'; action = 'gui_duyet_jd'; note = 'Trình Giám đốc phê duyệt JD' }
                )
            },
            [ordered]@{
                id = 'YC-002'; title = 'Chuyên viên Marketing'; dept = 'Phòng Marketing'
                headcount = 1; salaryMin = 12000000; salaryMax = 16000000; priority = 'Trung bình'
                reason = 'Thay thế nhân sự nghỉ việc từ đầu quý.'
                status = 'CHO_BO_SUNG'; createdBy = 'truongphong'; createdAt = $now
                jd = [ordered]@{ moTa = 'Triển khai chiến dịch truyền thông đa kênh.'; yeuCau = ''; quyenLoi = '' }
                candidates = @()
                history = @(
                    [ordered]@{ at = $now; by = 'truongphong'; actor = 'Trần Văn Hùng'; action = 'tao_yeu_cau'; note = 'Khởi tạo yêu cầu tuyển dụng' },
                    [ordered]@{ at = $now; by = 'nhansu'; actor = 'Lê Thị Mai'; action = 'kiem_tra_thieu'; note = 'Thiếu mô tả yêu cầu công việc và quyền lợi' }
                )
            },
            [ordered]@{
                id = 'YC-003'; title = 'Kế toán tổng hợp'; dept = 'Phòng Nhân sự'
                headcount = 1; salaryMin = 10000000; salaryMax = 14000000; priority = 'Cao'
                reason = 'Bổ sung vị trí kế toán sau khi tách bộ phận.'
                status = 'DANG_TUYEN'; createdBy = 'truongphong'; createdAt = $now
                jd = [ordered]@{ moTa = 'Theo dõi sổ sách, lập báo cáo tài chính nội bộ.'; yeuCau = 'Tốt nghiệp Kế toán; 2 năm kinh nghiệm; thành thạo Excel.'; quyenLoi = 'Lương 10-14 triệu; BHXH đầy đủ.' }
                candidates = @(
                    [ordered]@{ id = 'UV-001'; name = 'Phạm Anh Tuấn'; email = 'tuan.pa@example.com'; p = 0.96; label = 'Đạt'; status = 'TU_DONG_DUYET'; note = 'Đúng tiêu chí JD' },
                    [ordered]@{ id = 'UV-002'; name = 'Đỗ Thu Hà'; email = 'ha.dt@example.com'; p = 0.72; label = 'Đạt'; status = 'CHO_HR'; note = 'Thiếu chứng chỉ hành nghề' },
                    [ordered]@{ id = 'UV-003'; name = 'Vũ Minh Khoa'; email = 'khoa.vm@example.com'; p = 0.41; label = 'Không đạt'; status = 'CHO_HR'; note = 'Kinh nghiệm chưa phù hợp' }
                )
                history = @(
                    [ordered]@{ at = $now; by = 'truongphong'; actor = 'Trần Văn Hùng'; action = 'tao_yeu_cau'; note = 'Khởi tạo yêu cầu tuyển dụng' },
                    [ordered]@{ at = $now; by = 'nhansu'; actor = 'Lê Thị Mai'; action = 'kiem_tra_dat'; note = 'Yêu cầu đầy đủ thông tin' },
                    [ordered]@{ at = $now; by = 'nhansu'; actor = 'Lê Thị Mai'; action = 'gui_duyet_jd'; note = 'Trình Giám đốc phê duyệt JD' },
                    [ordered]@{ at = $now; by = 'giamdoc'; actor = 'Nguyễn Quốc Bảo'; action = 'duyet_jd'; note = 'Đồng ý với nội dung JD' },
                    [ordered]@{ at = $now; by = 'nhansu'; actor = 'Lê Thị Mai'; action = 'dang_tuyen'; note = 'Đăng tin đa kênh' }
                )
            }
        )
    }
}

function Get-Hash([string]$s) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $b = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($s))
    return ([BitConverter]::ToString($b) -replace '-', '').ToLower()
}

function Load-Db {
    if (-not (Test-Path $dbFile)) {
        $seed = New-Seed
        Save-Db $seed
        return $seed
    }
    return Get-Content -Raw -Encoding UTF8 $dbFile | ConvertFrom-Json
}

function Save-Db($db) {
    $json = $db | ConvertTo-Json -Depth 12
    [System.IO.File]::WriteAllText($dbFile, $json, (New-Object System.Text.UTF8Encoding($false)))
}

# ---------------- phien dang nhap ----------------
$script:sessions = @{}

# ---------------- tien ich HTTP ----------------
function Write-Response($ctx, [int]$code, [string]$body, [string]$type) {
    $res = $ctx.Response
    $res.StatusCode = $code
    $res.ContentType = $type
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
    $res.ContentLength64 = $bytes.Length
    $res.OutputStream.Write($bytes, 0, $bytes.Length)
    $res.OutputStream.Close()
}

function Write-Json($ctx, $obj, [int]$code = 200) {
    Write-Response $ctx $code ($obj | ConvertTo-Json -Depth 12) 'application/json; charset=utf-8'
}

function Fail($ctx, [int]$code, [string]$msg) {
    Write-Json $ctx ([ordered]@{ error = $msg }) $code
}

function Read-Body($ctx) {
    $reader = New-Object System.IO.StreamReader($ctx.Request.InputStream, [System.Text.Encoding]::UTF8)
    $txt = $reader.ReadToEnd()
    $reader.Close()
    if ([string]::IsNullOrWhiteSpace($txt)) { return $null }
    return $txt | ConvertFrom-Json
}

function Get-CurrentUser($ctx) {
    $h = $ctx.Request.Headers['Authorization']
    if (-not $h) { return $null }
    $token = $h -replace '^Bearer\s+', ''
    if (-not $script:sessions.ContainsKey($token)) { return $null }
    $s = $script:sessions[$token]
    if ($s.expires -lt (Get-Date)) { $script:sessions.Remove($token); return $null }
    return $s
}

function Add-History($req, $user, [string]$action, [string]$note) {
    $item = [ordered]@{ at = (Get-Date).ToString('s'); by = $user.username; actor = $user.name; action = $action; note = $note }
    $req.history = @($req.history) + $item
}

function Find-Request($db, [string]$id) {
    foreach ($r in $db.requests) { if ($r.id -eq $id) { return $r } }
    return $null
}

# ---------------- xu ly API ----------------
function Get-Screening($req, $b) {
    if ($req.salaryMax -and [double]$b.expected -gt [double]$req.salaryMax * 1.15) {
        return [ordered]@{ p = 0.35; label = 'Không đạt'; decision = 'TU_DONG_LOAI'; reason = 'Mức lương kỳ vọng vượt quá khung đã duyệt quá 15%' }
    }
    $score = 0.35 + ([double]$b.years * 0.04)
    if ($b.degree -eq 'daihoc') { $score += 0.18 } elseif ($b.degree -eq 'caodang') { $score += 0.08 }
    if ($b.skill) { $score += 0.10 }
    if ($score -gt 0.99) { $score = 0.99 }
    $score = [math]::Round($score, 2)
    $label = if ($score -ge 0.5) { 'Đạt' } else { 'Không đạt' }
    $decision = 'CHO_HR'; $reason = 'Độ tin cậy nằm trong vùng HR phải xem xét'
    if ($label -eq 'Đạt' -and $score -ge 0.92) { $decision = 'TU_DONG_DUYET'; $reason = 'Đạt ngưỡng tự động duyệt (p >= 92%)' }
    if ($label -eq 'Không đạt' -and $score -ge 0.98) { $decision = 'TU_DONG_LOAI'; $reason = 'Đạt ngưỡng tự động loại (p >= 98%)' }
    if ($score -lt 0.5) { $decision = 'CHO_HR'; $reason = 'Vùng cấm (p < 50%) - bắt buộc HR xem xét' }
    return [ordered]@{ p = $score; label = $label; decision = $decision; reason = $reason }
}

function Invoke-Api($ctx, $db) {
    $path = $ctx.Request.Url.AbsolutePath
    $method = $ctx.Request.HttpMethod

    if ($path -eq '/api/login' -and $method -eq 'POST') {
        $body = Read-Body $ctx
        if (-not $body) { return Fail $ctx 400 'Thiếu dữ liệu đăng nhập' }
        $u = $null
        foreach ($x in $db.users) { if ($x.username -eq $body.username) { $u = $x } }
        if (-not $u -or $u.pwd -ne (Get-Hash $body.password)) { return Fail $ctx 401 'Sai tài khoản hoặc mật khẩu' }
        $token = [guid]::NewGuid().ToString('N')
        $script:sessions[$token] = [ordered]@{ username = $u.username; name = $u.name; role = $u.role; dept = $u.dept; expires = (Get-Date).AddHours(8) }
        return Write-Json $ctx ([ordered]@{ token = $token; user = [ordered]@{ username = $u.username; name = $u.name; role = $u.role; dept = $u.dept } })
    }

    $user = Get-CurrentUser $ctx
    if (-not $user) { return Fail $ctx 401 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn' }

    if ($path -eq '/api/me' -and $method -eq 'GET') {
        return Write-Json $ctx ([ordered]@{ username = $user.username; name = $user.name; role = $user.role; dept = $user.dept })
    }

    if ($path -eq '/api/logout' -and $method -eq 'POST') {
        $h = $ctx.Request.Headers['Authorization']
        if ($h) { $script:sessions.Remove(($h -replace '^Bearer\s+', '')) }
        return Write-Json $ctx ([ordered]@{ ok = $true })
    }

    if ($path -eq '/api/requests' -and $method -eq 'GET') {
        $list = @()
        foreach ($r in $db.requests) {
            $list += [ordered]@{
                id = $r.id; title = $r.title; dept = $r.dept; headcount = $r.headcount
                salaryMin = $r.salaryMin; salaryMax = $r.salaryMax; priority = $r.priority
                status = $r.status; createdAt = $r.createdAt; candidateCount = @($r.candidates).Count
            }
        }
        return Write-Json $ctx ([ordered]@{ items = $list })
    }

    if ($path -eq '/api/requests' -and $method -eq 'POST') {
        if ($user.role -ne 'truongphong') { return Fail $ctx 403 'Chỉ trưởng phòng ban được tạo yêu cầu' }
        $b = Read-Body $ctx
        if (-not $b.title -or -not $b.reason) { return Fail $ctx 400 'Thiếu tiêu đề hoặc lý do tuyển dụng' }
        $db.meta.seq = [int]$db.meta.seq + 1
        $id = 'YC-' + ('{0:D3}' -f ([int]$db.meta.seq))
        $req = [ordered]@{
            id = $id; title = $b.title; dept = $user.dept
            headcount = [int]$b.headcount; salaryMin = [int]$b.salaryMin; salaryMax = [int]$b.salaryMax
            priority = $b.priority; reason = $b.reason; status = 'MOI'; createdBy = $user.username
            createdAt = (Get-Date).ToString('s')
            jd = [ordered]@{ moTa = ''; yeuCau = ''; quyenLoi = '' }
            candidates = @(); history = @()
        }
        Add-History $req $user 'tao_yeu_cau' 'Khởi tạo yêu cầu tuyển dụng'
        $req.status = 'CHO_KIEM_TRA'
        $db.requests = @($db.requests) + $req
        Save-Db $db
        return Write-Json $ctx $req 201
    }

    if ($path -match '^/api/requests/([^/]+)$' -and $method -eq 'GET') {
        $r = Find-Request $db $Matches[1]
        if (-not $r) { return Fail $ctx 404 'Không tìm thấy yêu cầu' }
        return Write-Json $ctx $r
    }

    if ($path -match '^/api/requests/([^/]+)/action$' -and $method -eq 'POST') {
        $r = Find-Request $db $Matches[1]
        if (-not $r) { return Fail $ctx 404 'Không tìm thấy yêu cầu' }
        $b = Read-Body $ctx
        $act = $b.action
        $note = if ($b.note) { $b.note } else { '' }

        $rules = @{
            'kiem_tra_dat'  = @{ role = 'nhansu'; from = @('CHO_KIEM_TRA'); to = 'CHO_SOAN_JD' }
            'kiem_tra_thieu'= @{ role = 'nhansu'; from = @('CHO_KIEM_TRA'); to = 'CHO_BO_SUNG' }
            'bo_sung_lai'   = @{ role = 'truongphong'; from = @('CHO_BO_SUNG'); to = 'CHO_KIEM_TRA' }
            'luu_jd'        = @{ role = 'nhansu'; from = @('CHO_SOAN_JD'); to = 'CHO_DUYET_JD' }
            'duyet_jd'      = @{ role = 'giamdoc'; from = @('CHO_DUYET_JD'); to = 'DANG_TUYEN' }
            'tu_choi_jd'    = @{ role = 'giamdoc'; from = @('CHO_DUYET_JD'); to = 'CHO_SOAN_JD' }
            'trinh_phe_duyet' = @{ role = 'nhansu'; from = @('DANG_TUYEN'); to = 'CHO_PHE_DUYET_NS' }
            'duyet_ns'      = @{ role = 'giamdoc'; from = @('CHO_PHE_DUYET_NS'); to = 'HOAN_TAT' }
            'tu_choi_ns'    = @{ role = 'giamdoc'; from = @('CHO_PHE_DUYET_NS'); to = 'TU_CHOI' }
        }
        if (-not $rules.ContainsKey($act)) { return Fail $ctx 400 'Hành động không hợp lệ' }
        $rule = $rules[$act]
        if ($user.role -ne $rule.role) { return Fail $ctx 403 'Vai trò của bạn không được thực hiện hành động này' }
        if ($rule.from -notcontains $r.status) { return Fail $ctx 409 "Trạng thái hiện tại ($($r.status)) không cho phép hành động này" }

        if ($act -eq 'luu_jd') {
            if (-not $b.moTa -or -not $b.yeuCau) { return Fail $ctx 400 'Phải nhập mô tả công việc và yêu cầu ứng viên' }
            $r.jd = [ordered]@{ moTa = $b.moTa; yeuCau = $b.yeuCau; quyenLoi = $b.quyenLoi }
        }
        $r.status = $rule.to
        Add-History $r $user $act $note
        Save-Db $db
        return Write-Json $ctx $r
    }

    if ($path -match '^/api/requests/([^/]+)/screen$' -and $method -eq 'POST') {
        $r = Find-Request $db $Matches[1]
        if (-not $r) { return Fail $ctx 404 'Không tìm thấy yêu cầu' }
        if ($user.role -ne 'nhansu') { return Fail $ctx 403 'Chỉ Nhân sự được chạy sàng lọc' }
        $b = Read-Body $ctx
        return Write-Json $ctx (Get-Screening $r $b)
    }

    if ($path -match '^/api/requests/([^/]+)/candidates$' -and $method -eq 'POST') {
        $rid = $Matches[1]
        $r = Find-Request $db $rid
        if (-not $r) { return Fail $ctx 404 'Không tìm thấy yêu cầu' }
        if ($user.role -ne 'nhansu') { return Fail $ctx 403 'Chỉ Nhân sự được thêm và sàng lọc hồ sơ' }
        $b = Read-Body $ctx
        if (-not $b.name) { return Fail $ctx 400 'Thiếu tên ứng viên' }
        $res = Get-Screening $r $b
        $list = @($r.candidates)
        $cid = 'UV-' + ('{0:D3}' -f ($list.Count + 1))
        $cand = [ordered]@{
            id = $cid; name = $b.name; email = $b.email
            p = $res.p; label = $res.label; status = $res.decision; note = $res.reason
            years = [double]$b.years; degree = $b.degree; expected = [double]$b.expected
            at = (Get-Date).ToString('s')
        }
        $r.candidates = $list + $cand
        Add-History $r $user 'sang_loc_ho_so' ("Sàng lọc " + $b.name + " - p=" + $res.p + " - " + $res.decision)
        Save-Db $db
        return Write-Json $ctx $cand 201
    }

    return Fail $ctx 404 'Không tìm thấy tài nguyên'
}

# ---------------- phuc vu tep tinh ----------------
function Send-Static($ctx, [string]$rel) {
    if ($rel -eq '/' -or $rel -eq '') { $rel = '/index.html' }
    $full = Join-Path $public ($rel.TrimStart('/') -replace '/', '\')
    if (-not (Test-Path $full)) { return Write-Response $ctx 404 'Không tìm thấy tệp' 'text/plain; charset=utf-8' }
    $ext = [System.IO.Path]::GetExtension($full).ToLower()
    $type = switch ($ext) {
        '.html' { 'text/html; charset=utf-8' }
        '.css'  { 'text/css; charset=utf-8' }
        '.js'   { 'application/javascript; charset=utf-8' }
        '.png'  { 'image/png' }
        '.svg'  { 'image/svg+xml' }
        default { 'application/octet-stream' }
    }
    $bytes = [System.IO.File]::ReadAllBytes($full)
    $res = $ctx.Response
    $res.StatusCode = 200
    $res.ContentType = $type
    $res.ContentLength64 = $bytes.Length
    $res.OutputStream.Write($bytes, 0, $bytes.Length)
    $res.OutputStream.Close()
}

# ---------------- vong lap chinh ----------------
$listener = New-Object System.Net.HttpListener
$prefix = "http://localhost:$Port/"
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Host "=== Ung dung tuyen dung - Nhom 8 MIS3047 ==="
Write-Host "Dang chay tai: $prefix"
Write-Host "Du lieu: $dbFile"
Write-Host "Nhan Ctrl+C de dung."
Write-Host ""

try {
    while ($listener.IsListening) {
        $ctx = $listener.GetContext()
        try {
            $path = $ctx.Request.Url.AbsolutePath
            if ($path -like '/api/*') {
                $db = Load-Db
                Invoke-Api $ctx $db
            } else {
                Send-Static $ctx $path
            }
        } catch {
            try { Fail $ctx 500 ($_.Exception.Message) } catch {}
        }
    }
} finally {
    $listener.Stop()
    $listener.Close()
}
