/* app.js — Giao diện Hệ thống Tuyển dụng Nhân sự (MIS3047 - Nhóm 8) */
'use strict';

const state = {
  token: localStorage.getItem('token') || null,
  user: null,
  view: 'dashboard',
  reqId: null,
  requests: []
};

/* ---------------- tiện ích ---------------- */

const $ = (sel, root) => (root || document).querySelector(sel);

function esc(s) {
  return String(s == null ? '' : s)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

function money(n) {
  return (Number(n) || 0).toLocaleString('vi-VN') + ' đ';
}

function time(s) {
  if (!s) return '—';
  const d = new Date(s);
  if (isNaN(d.getTime())) return s;
  return d.toLocaleString('vi-VN', { hour12: false });
}

let toastTimer = null;
function toast(msg, isErr) {
  const el = $('#toast');
  el.textContent = msg;
  el.className = 'toast on' + (isErr ? ' err' : '');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { el.className = 'toast'; }, 2600);
}

async function api(path, opts) {
  opts = opts || {};
  const headers = { 'Content-Type': 'application/json' };
  if (state.token) headers.Authorization = 'Bearer ' + state.token;
  const res = await fetch('/api' + path, {
    method: opts.method || 'GET',
    headers: headers,
    body: opts.body ? JSON.stringify(opts.body) : undefined
  });
  let data = null;
  try { data = await res.json(); } catch (e) { data = null; }
  if (res.status === 401 && path !== '/login') {
    logout(true);
    throw new Error('Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.');
  }
  if (!res.ok) throw new Error((data && data.error) || 'Lỗi máy chủ (' + res.status + ')');
  return data;
}

/* ---------------- nhãn trạng thái ---------------- */

const STATUS = {
  MOI:              { label: 'Mới tạo',            cls: 'b-grey'  },
  CHO_KIEM_TRA:     { label: 'Chờ kiểm tra',       cls: 'b-blue'  },
  CHO_BO_SUNG:      { label: 'Chờ bổ sung',        cls: 'b-amber' },
  CHO_SOAN_JD:      { label: 'Chờ soạn JD',        cls: 'b-blue'  },
  CHO_DUYET_JD:     { label: 'Chờ duyệt JD',       cls: 'b-amber' },
  DANG_TUYEN:       { label: 'Đang tuyển',         cls: 'b-blue'  },
  CHO_PHE_DUYET_NS: { label: 'Chờ duyệt nhân sự',  cls: 'b-amber' },
  HOAN_TAT:         { label: 'Hoàn tất',           cls: 'b-green' },
  TU_CHOI:          { label: 'Từ chối',            cls: 'b-red'   }
};

const CAND = {
  TU_DONG_DUYET: { label: 'Tự động duyệt', cls: 'b-green' },
  TU_DONG_LOAI:  { label: 'Tự động loại',  cls: 'b-red'   },
  CHO_HR:        { label: 'HR xem xét',    cls: 'b-amber' }
};

const ROLE = {
  truongphong: 'Trưởng phòng ban',
  nhansu: 'Chuyên viên Nhân sự',
  giamdoc: 'Giám đốc'
};

const DEGREE = { daihoc: 'Đại học', caodang: 'Cao đẳng', trungcap: 'Trung cấp', khac: 'Khác' };

const ACT = {
  tao_yeu_cau: 'Tạo yêu cầu',
  kiem_tra_dat: 'Kiểm tra đạt',
  kiem_tra_thieu: 'Yêu cầu bổ sung',
  bo_sung_lai: 'Bổ sung hồ sơ',
  luu_jd: 'Lưu & trình JD',
  duyet_jd: 'Duyệt JD',
  tu_choi_jd: 'Từ chối JD',
  trinh_phe_duyet: 'Trình duyệt nhân sự',
  duyet_ns: 'Phê duyệt nhân sự',
  tu_choi_ns: 'Từ chối nhân sự',
  sang_loc_ho_so: 'Sàng lọc hồ sơ'
};

function badge(st) {
  const m = STATUS[st] || { label: st, cls: 'b-grey' };
  return '<span class="badge ' + m.cls + '">' + esc(m.label) + '</span>';
}

/* ---------------- khởi động ---------------- */

document.addEventListener('DOMContentLoaded', () => {
  $('#login-form').addEventListener('submit', onLogin);
  $('#logout').addEventListener('click', () => logout(false));
  $('#nav').addEventListener('click', e => {
    const b = e.target.closest('button[data-view]');
    if (b) go(b.dataset.view);
  });
  if (state.token) resume(); else showLogin();
});

async function onLogin(e) {
  e.preventDefault();
  const err = $('#login-error');
  err.textContent = '';
  try {
    const r = await api('/login', {
      method: 'POST',
      body: { username: $('#username').value.trim(), password: $('#password').value }
    });
    state.token = r.token;
    state.user = r.user;
    localStorage.setItem('token', r.token);
    enter();
  } catch (ex) {
    err.textContent = ex.message;
  }
}

async function resume() {
  try {
    state.user = await api('/me');
    enter();
  } catch (ex) {
    showLogin();
  }
}

function showLogin() {
  state.token = null; state.user = null;
  localStorage.removeItem('token');
  $('#app').className = '';
  $('#login').style.display = '';
}

function logout(silent) {
  if (!silent && state.token) api('/logout', { method: 'POST' }).catch(() => {});
  showLogin();
  if (silent) toast('Phiên đăng nhập đã hết hạn', true);
}

function enter() {
  $('#login').style.display = 'none';
  $('#app').className = 'on';
  $('#who-name').textContent = state.user.name;
  $('#who-role').textContent = ROLE[state.user.role] + ' · ' + state.user.dept;
  go('dashboard');
}

function go(view) {
  state.view = view;
  state.reqId = null;
  document.querySelectorAll('#nav button').forEach(b => {
    b.classList.toggle('active', b.dataset.view === view);
  });
  render();
}

async function render() {
  const main = $('#main');
  try {
    if (state.view === 'dashboard') { await loadRequests(); main.innerHTML = viewDashboard(); }
    else if (state.view === 'requests') { await loadRequests(); main.innerHTML = viewRequests(); }
    else if (state.view === 'detail') { main.innerHTML = await viewDetail(state.reqId); }
    else if (state.view === 'screening') { await loadRequests(); main.innerHTML = viewScreening(); }
    else if (state.view === 'about') { main.innerHTML = viewAbout(); }
  } catch (ex) {
    main.innerHTML = '<div class="panel"><h3>Không tải được dữ liệu</h3><p>' + esc(ex.message) + '</p></div>';
  }
}

async function loadRequests() {
  const r = await api('/requests');
  state.requests = r.items || [];
}

/* ---------------- tổng quan ---------------- */

function viewDashboard() {
  const u = state.user;
  const list = state.requests;
  const active = list.filter(r => r.status !== 'HOAN_TAT' && r.status !== 'TU_CHOI' && r.status !== 'MOI');
  const mine = list.filter(r => canAct(r, u.role));
  const done = list.filter(r => r.status === 'HOAN_TAT');
  const cands = list.reduce((s, r) => s + (r.candidateCount || 0), 0);

  let rows = mine.slice(0, 6).map(r => `
    <tr onclick="openReq('${r.id}')">
      <td class="id">${esc(r.id)}</td>
      <td>${esc(r.title)}</td>
      <td>${esc(r.dept)}</td>
      <td>${badge(r.status)}</td>
      <td>${esc(r.priority)}</td>
    </tr>`).join('');

  if (!rows) {
    rows = '<tr><td colspan="5"><div class="empty">Không có yêu cầu nào đang chờ bạn xử lý.</div></td></tr>';
  }

  return `
  <div class="page-head">
    <div>
      <h2>Tổng quan</h2>
      <p>Xin chào ${esc(u.name)} — ${esc(ROLE[u.role])} · ${esc(u.dept)}</p>
    </div>
    <button class="btn ghost" onclick="go('requests')">Xem tất cả yêu cầu</button>
  </div>

  <div class="cards">
    <div class="card"><div class="num">${list.length}</div><div class="lbl">Yêu cầu tuyển dụng</div></div>
    <div class="card"><div class="num">${active.length}</div><div class="lbl">Đang trong quy trình</div></div>
    <div class="card ${mine.length ? 'alert' : ''}"><div class="num">${mine.length}</div><div class="lbl">Chờ bạn xử lý</div></div>
    <div class="card"><div class="num">${cands}</div><div class="lbl">Hồ sơ ứng viên đã sàng lọc</div></div>
  </div>

  <div class="panel">
    <h3>Cần bạn xử lý theo vai trò</h3>
    <table>
      <thead><tr><th>Mã</th><th>Vị trí</th><th>Phòng ban</th><th>Trạng thái</th><th>Ưu tiên</th></tr></thead>
      <tbody>${rows}</tbody>
    </table>
  </div>

  <div class="panel">
    <h3>Quy trình TO-BE — 3 chốt kiểm soát của con người</h3>
    <table class="rule-table">
      <thead><tr><th>Chốt</th><th>Ai quyết định</th><th>Kiểu XOR</th><th>Điều kiện vào</th></tr></thead>
      <tbody>
        <tr><td>Kiểm tra tính đầy đủ</td><td>Chuyên viên Nhân sự</td><td>Đạt / Thiếu</td><td>Yêu cầu mới tạo từ Trưởng phòng</td></tr>
        <tr><td>Phê duyệt JD</td><td>Giám đốc</td><td>Duyệt / Từ chối</td><td>Nhân sự đã soạn JD</td></tr>
        <tr><td>Phê duyệt nhân sự</td><td>Giám đốc</td><td>Duyệt / Từ chối</td><td>Nhân sự trình kết quả tuyển</td></tr>
      </tbody>
    </table>
  </div>`;
}

/* ---------------- danh sách ---------------- */

function viewRequests() {
  const u = state.user;
  const rows = state.requests.map(r => `
    <tr onclick="openReq('${r.id}')">
      <td class="id">${esc(r.id)}</td>
      <td>${esc(r.title)}</td>
      <td>${esc(r.dept)}</td>
      <td>${r.headcount}</td>
      <td>${money(r.salaryMin)} – ${money(r.salaryMax)}</td>
      <td>${badge(r.status)}</td>
      <td>${r.candidateCount || 0}</td>
    </tr>`).join('') || '<tr><td colspan="7"><div class="empty">Chưa có yêu cầu nào.</div></td></tr>';

  const canCreate = u.role === 'truongphong';

  return `
  <div class="page-head">
    <div>
      <h2>Yêu cầu tuyển dụng</h2>
      <p>Toàn bộ yêu cầu kèm trạng thái hiện tại trong quy trình TO-BE</p>
    </div>
    ${canCreate ? '<button class="btn" onclick="showCreate()">+ Tạo yêu cầu</button>' : ''}
  </div>
  <div class="panel" id="create-panel" style="display:none">
    <h3>Tạo yêu cầu tuyển dụng mới</h3>
    <form id="create-form">
      <div class="grid2">
        <div>
          <div class="field"><label>Vị trí cần tuyển</label><input name="title" required placeholder="VD: Nhân viên Kinh doanh"></div>
          <div class="field"><label>Lý do tuyển dụng</label><textarea name="reason" required placeholder="Mô tả căn cứ phát sinh nhu cầu"></textarea></div>
          <div class="field"><label>Mức lương tối thiểu (đ)</label><input name="salaryMin" type="number" min="0" step="100000" value="9000000" required></div>
          <div class="field"><label>Mức lương tối đa (đ)</label><input name="salaryMax" type="number" min="0" step="100000" value="12000000" required></div>
        </div>
        <div>
          <div class="field"><label>Số lượng</label><input name="headcount" type="number" min="1" value="1" required></div>
          <div class="field"><label>Mức ưu tiên</label>
            <select name="priority"><option>Cao</option><option selected>Trung bình</option><option>Thấp</option></select>
          </div>
          <div class="action-box" style="margin-top:18px">
            <div style="font-size:12.5px;color:#43506a;line-height:1.6">
              Sau khi tạo, yêu cầu chuyển sang <b>Chờ kiểm tra</b>. Chỉ Chuyên viên Nhân sự
              được xác nhận đầy đủ hay yêu cầu bổ sung — đây là chốt XOR đầu tiên.
            </div>
          </div>
          <div class="actions">
            <button class="btn" type="submit">Gửi yêu cầu</button>
            <button class="btn ghost" type="button" onclick="hideCreate()">Hủy</button>
          </div>
        </div>
      </div>
    </form>
  </div>
  <div class="panel">
    <table>
      <thead><tr><th>Mã</th><th>Vị trí</th><th>Phòng ban</th><th>SL</th><th>Khung lương</th><th>Trạng thái</th><th>UV</th></tr></thead>
      <tbody>${rows}</tbody>
    </table>
  </div>`;
}

function showCreate() {
  $('#create-panel').style.display = '';
  const f = $('#create-form');
  f.addEventListener('submit', async e => {
    e.preventDefault();
    const d = new FormData(f);
    const body = {
      title: d.get('title'), reason: d.get('reason'),
      salaryMin: Number(d.get('salaryMin')), salaryMax: Number(d.get('salaryMax')),
      headcount: Number(d.get('headcount')), priority: d.get('priority')
    };
    try {
      const r = await api('/requests', { method: 'POST', body: body });
      toast('Đã tạo ' + r.id);
      go('requests');
    } catch (ex) { toast(ex.message, true); }
  });
}

function hideCreate() { $('#create-panel').style.display = 'none'; }

/* ---------------- chi tiết ---------------- */

function openReq(id) {
  state.reqId = id;
  state.view = 'detail';
  document.querySelectorAll('#nav button').forEach(b => b.classList.remove('active'));
  render();
}

function canAct(r, role) {
  if (role === 'nhansu' && r.status === 'CHO_KIEM_TRA') return true;
  if (role === 'truongphong' && r.status === 'CHO_BO_SUNG') return true;
  if (role === 'nhansu' && r.status === 'CHO_SOAN_JD') return true;
  if (role === 'nhansu' && r.status === 'DANG_TUYEN') return true;
  if (role === 'giamdoc' && r.status === 'CHO_DUYET_JD') return true;
  if (role === 'giamdoc' && r.status === 'CHO_PHE_DUYET_NS') return true;
  return false;
}

async function viewDetail(id) {
  const r = await api('/requests/' + encodeURIComponent(id));
  const status = STATUS[r.status] || { label: r.status, cls: 'b-grey' };

  const candRows = (r.candidates || []).map(c => {
    const m = CAND[c.status] || { label: c.status, cls: 'b-grey' };
    return `<tr>
      <td class="id">${esc(c.id)}</td>
      <td>${esc(c.name)}</td>
      <td>${(c.p * 100).toFixed(0)}%</td>
      <td>${esc(c.label)}</td>
      <td><span class="badge ${m.cls}">${esc(m.label)}</span></td>
      <td style="color:#6b7688;font-size:12.5px">${esc(c.note)}</td>
    </tr>`;
  }).join('') || '<tr><td colspan="6"><div class="empty">Chưa có hồ sơ nào được sàng lọc.</div></td></tr>';

  const hist = (r.history || []).map(h => `
    <li>
      <div class="t-act">${esc(ACT[h.action] || h.action)}</div>
      <div class="t-meta">${esc(h.actor)} · ${esc(time(h.at))}</div>
      ${h.note ? '<div class="t-note">' + esc(h.note) + '</div>' : ''}
    </li>`).join('');

  return `
  <div class="page-head">
    <div>
      <h2>${esc(r.id)} · ${esc(r.title)}</h2>
      <p>${esc(r.dept)} · ${esc(r.priority)} · tạo lúc ${esc(time(r.createdAt))}</p>
    </div>
    <div class="actions" style="margin:0">
      ${badge(r.status)}
      <button class="btn ghost" onclick="go('requests')">← Danh sách</button>
    </div>
  </div>

  <div class="grid2">
    <div>
      <div class="panel">
        <h3>Thông tin yêu cầu</h3>
        <dl class="kv">
          <dt>Số lượng cần tuyển</dt><dd>${r.headcount} người</dd>
          <dt>Khung lương</dt><dd>${money(r.salaryMin)} – ${money(r.salaryMax)}</dd>
          <dt>Lý do</dt><dd>${esc(r.reason)}</dd>
          <dt>Người tạo</dt><dd>${esc(r.createdBy)}</dd>
          <dt>Trạng thái</dt><dd>${esc(status.label)}</dd>
        </dl>
      </div>

      <div class="panel">
        <h3>Mô tả công việc (JD)</h3>
        <div class="jd-block"><h4>Mô tả</h4><p>${esc(r.jd && r.jd.moTa) || '<i>chưa soạn</i>'}</p></div>
        <div class="jd-block"><h4>Yêu cầu ứng viên</h4><p>${esc(r.jd && r.jd.yeuCau) || '<i>chưa soạn</i>'}</p></div>
        <div class="jd-block"><h4>Quyền lợi</h4><p>${esc(r.jd && r.jd.quyenLoi) || '<i>chưa soạn</i>'}</p></div>
      </div>

      <div class="panel">
        <h3>Hồ sơ ứng viên</h3>
        <table>
          <thead><tr><th>Mã</th><th>Ứng viên</th><th>p</th><th>Nhãn</th><th>Quyết định</th><th>Căn cứ</th></tr></thead>
          <tbody>${candRows}</tbody>
        </table>
      </div>
    </div>

    <div>
      <div class="panel">
        <h3>Thao tác của bạn</h3>
        ${actionBox(r)}
      </div>
      <div class="panel">
        <h3>Lịch sử xử lý</h3>
        <ul class="timeline">${hist || '<li>Chưa có ghi nhận</li>'}</ul>
      </div>
    </div>
  </div>`;
}

function actionBox(r) {
  const role = state.user.role;

  if (!canAct(r, role)) {
    return `<div style="font-size:13px;color:#6b7688;line-height:1.65">
      Không có thao tác nào dành cho vai trò <b>${esc(ROLE[role])}</b> ở trạng thái
      <b>${esc((STATUS[r.status] || {}).label || r.status)}</b>.
      ${r.status === 'HOAN_TAT' || r.status === 'TU_CHOI' ? 'Quy trình đã kết thúc.' : 'Yêu cầu đang chờ bước khác xử lý.'}
    </div>`;
  }

  if (role === 'nhansu' && r.status === 'CHO_KIEM_TRA') {
    return `<div class="action-box">
      <div class="field"><label>Ghi chú kiểm tra</label>
        <textarea id="act-note" placeholder="Ví dụ: Đã đủ thông tin vị trí, số lượng và khung lương"></textarea></div>
      <div class="actions">
        <button class="btn ok" onclick="doAction('${r.id}','kiem_tra_dat')">Xác nhận đầy đủ</button>
        <button class="btn danger" onclick="doAction('${r.id}','kiem_tra_thieu')">Yêu cầu bổ sung</button>
      </div>
    </div>`;
  }

  if (role === 'truongphong' && r.status === 'CHO_BO_SUNG') {
    return `<div class="action-box">
      <div class="field"><label>Nội dung đã bổ sung</label>
        <textarea id="act-note" placeholder="Bổ sung thông tin còn thiếu theo yêu cầu của Nhân sự"></textarea></div>
      <div class="actions"><button class="btn" onclick="doAction('${r.id}','bo_sung_lai')">Gửi lại Nhân sự</button></div>
    </div>`;
  }

  if (role === 'nhansu' && r.status === 'CHO_SOAN_JD') {
    return `<div class="action-box">
      <div class="field"><label>Mô tả công việc</label>
        <textarea id="jd-mota" placeholder="Trách nhiệm chính">${esc(r.jd && r.jd.moTa)}</textarea></div>
      <div class="field"><label>Yêu cầu ứng viên</label>
        <textarea id="jd-yeucau" placeholder="Học vấn, kinh nghiệm, kỹ năng">${esc(r.jd && r.jd.yeuCau)}</textarea></div>
      <div class="field"><label>Quyền lợi</label>
        <textarea id="jd-quyenloi" placeholder="Lương, bảo hiểm, phụ cấp">${esc(r.jd && r.jd.quyenLoi)}</textarea></div>
      <div class="actions"><button class="btn" onclick="doAction('${r.id}','luu_jd')">Lưu JD &amp; trình Giám đốc</button></div>
    </div>`;
  }

  if (role === 'giamdoc' && r.status === 'CHO_DUYET_JD') {
    return `<div class="action-box">
      <div class="field"><label>Ý kiến phê duyệt</label>
        <textarea id="act-note" placeholder="Đồng ý / lý do từ chối"></textarea></div>
      <div class="actions">
        <button class="btn ok" onclick="doAction('${r.id}','duyet_jd')">Duyệt JD</button>
        <button class="btn danger" onclick="doAction('${r.id}','tu_choi_jd')">Từ chối JD</button>
      </div>
    </div>`;
  }

  if (role === 'nhansu' && r.status === 'DANG_TUYEN') {
    return `<div class="action-box">
      <div style="font-size:13px;color:#43506a;line-height:1.6;margin-bottom:10px">
        Đã sàng lọc ${(r.candidates || []).length} hồ sơ. Khi đủ ứng viên đạt, trình Giám đốc phê duyệt kết quả.
      </div>
      <div class="field"><label>Ghi chú trình duyệt</label>
        <textarea id="act-note" placeholder="Tóm tắt kết quả tuyển dụng"></textarea></div>
      <div class="actions">
        <button class="btn" onclick="doAction('${r.id}','trinh_phe_duyet')">Trình Giám đốc phê duyệt</button>
        <button class="btn ghost" onclick="go('screening')">Sàng lọc hồ sơ</button>
      </div>
    </div>`;
  }

  if (role === 'giamdoc' && r.status === 'CHO_PHE_DUYET_NS') {
    return `<div class="action-box">
      <div class="field"><label>Quyết định</label>
        <textarea id="act-note" placeholder="Đồng ý tuyển / lý do từ chối"></textarea></div>
      <div class="actions">
        <button class="btn ok" onclick="doAction('${r.id}','duyet_ns')">Phê duyệt tuyển dụng</button>
        <button class="btn danger" onclick="doAction('${r.id}','tu_choi_ns')">Từ chối</button>
      </div>
    </div>`;
  }

  return '';
}

async function doAction(id, action) {
  const noteEl = $('#act-note');
  const body = { action: action, note: noteEl ? noteEl.value : '' };
  if (action === 'luu_jd') {
    body.moTa = $('#jd-mota').value.trim();
    body.yeuCau = $('#jd-yeucau').value.trim();
    body.quyenLoi = $('#jd-quyenloi').value.trim();
    if (!body.moTa || !body.yeuCau) { toast('Phải nhập mô tả và yêu cầu ứng viên', true); return; }
  }
  try {
    await api('/requests/' + encodeURIComponent(id) + '/action', { method: 'POST', body: body });
    toast('Đã cập nhật: ' + (ACT[action] || action));
    state.reqId = id;
    state.view = 'detail';
    render();
  } catch (ex) { toast(ex.message, true); }
}

/* ---------------- sàng lọc ---------------- */

function viewScreening() {
  const open = state.requests.filter(r => r.status === 'DANG_TUYEN');
  const opts = open.map(r => `<option value="${esc(r.id)}">${esc(r.id)} — ${esc(r.title)} (${money(r.salaryMax)})</option>`).join('');
  const canScreen = state.user.role === 'nhansu';

  return `
  <div class="page-head">
    <div>
      <h2>Sàng lọc hồ sơ ứng viên</h2>
      <p>Áp dụng ngưỡng tin cậy 92% / 98% và vùng cấm 50% theo thiết kế mục 3.2</p>
    </div>
  </div>

  <div class="grid2">
    <div class="panel">
      <h3>Nhập hồ sơ</h3>
      ${!canScreen ? '<div class="hint" style="margin:0 0 14px">Chỉ Chuyên viên Nhân sự được chạy sàng lọc. Bạn vẫn xem được bảng quy tắc bên cạnh.</div>' : ''}
      ${open.length === 0 ? '<div class="empty">Chưa có yêu cầu nào ở trạng thái <b>Đang tuyển</b>. Hãy duyệt JD trước.</div>' : `
      <form id="screen-form" ${canScreen ? '' : 'style="display:none"'}>
        <div class="field"><label>Yêu cầu tuyển dụng</label>
          <select name="reqId">${opts}</select></div>
        <div class="grid2" style="gap:12px">
          <div class="field"><label>Họ tên ứng viên</label><input name="name" required placeholder="Nguyễn Văn A"></div>
          <div class="field"><label>Email</label><input name="email" type="email" placeholder="a@example.com"></div>
        </div>
        <div class="grid2" style="gap:12px">
          <div class="field"><label>Số năm kinh nghiệm</label><input name="years" type="number" min="0" max="30" step="0.5" value="3"></div>
          <div class="field"><label>Trình độ</label>
            <select name="degree">${Object.keys(DEGREE).map(k => `<option value="${k}">${DEGREE[k]}</option>`).join('')}</select></div>
        </div>
        <div class="grid2" style="gap:12px">
          <div class="field"><label>Lương kỳ vọng (đ)</label><input name="expected" type="number" min="0" step="100000" value="11000000"></div>
          <div class="field"><label>Có kỹ năng chuyên môn phù hợp</label>
            <select name="skill"><option value="1">Có</option><option value="">Không</option></select></div>
        </div>
        <div class="actions">
          <button class="btn" type="submit">Sàng lọc &amp; lưu hồ sơ</button>
          <button class="btn ghost" type="button" onclick="previewScreen()">Chỉ xem kết quả</button>
        </div>
      </form>`}
      <div id="screen-result"></div>
    </div>

    <div class="panel">
      <h3>Bảng quy tắc quyết định</h3>
      <table class="rule-table">
        <thead><tr><th>Vùng</th><th>Điều kiện</th><th>Hệ thống làm gì</th></tr></thead>
        <tbody>
          <tr><td><span class="badge b-green">Tự động duyệt</span></td><td>Nhãn Đạt và p ≥ 92%</td><td>Chuyển thẳng sang bước tiếp theo</td></tr>
          <tr><td><span class="badge b-red">Tự động loại</span></td><td>Nhãn Không đạt và p ≥ 98%</td><td>Loại hồ sơ, lưu vết</td></tr>
          <tr><td><span class="badge b-amber">HR xem xét</span></td><td>50% ≤ p &lt; 92%, hoặc p ≥ 92% nhưng nhãn Không đạt</td><td>Đẩy sang hàng đợi của Nhân sự</td></tr>
          <tr><td><span class="badge b-red">Vùng cấm</span></td><td>p &lt; 50%</td><td>Không cho tự động hóa, bắt buộc HR đọc hồ sơ</td></tr>
        </tbody>
      </table>
      <div class="hint" style="margin-top:16px">
        Chi phí tham chiếu: X = 25.000 đ/lần xử lý thủ công, Y<sub>R</sub> = 1.200.000 đ khi loại nhầm người giỏi,
        Y<sub>A</sub> = 300.000 đ khi nhận nhầm người không đạt. Ngưỡng 92% và 98% được chọn từ
        bảng chi phí/rủi ro trong tài liệu 3.2.
      </div>
    </div>
  </div>`;
}

function screenFormData() {
  const f = $('#screen-form');
  if (!f) return null;
  const d = new FormData(f);
  return {
    reqId: d.get('reqId'),
    name: String(d.get('name') || '').trim(),
    email: String(d.get('email') || '').trim(),
    years: Number(d.get('years') || 0),
    degree: d.get('degree'),
    expected: Number(d.get('expected') || 0),
    skill: d.get('skill') === '1'
  };
}

async function previewScreen() {
  const d = screenFormData();
  if (!d || !d.name) { toast('Nhập tên ứng viên trước', true); return; }
  try {
    const r = await api('/requests/' + encodeURIComponent(d.reqId) + '/screen', { method: 'POST', body: d });
    showResult(r, null);
  } catch (ex) { toast(ex.message, true); }
}

document.addEventListener('submit', async e => {
  if (!e.target || e.target.id !== 'screen-form') return;
  e.preventDefault();
  const d = screenFormData();
  if (!d.name) { toast('Nhập tên ứng viên', true); return; }
  try {
    const r = await api('/requests/' + encodeURIComponent(d.reqId) + '/candidates', { method: 'POST', body: d });
    showResult(r, d.name);
    await loadRequests();
  } catch (ex) { toast(ex.message, true); }
});

function showResult(r, savedName) {
  const box = $('#screen-result');
  const decision = r.decision || r.status;
  const reason = r.reason || r.note;
  let cls = 'hr';
  if (decision === 'TU_DONG_DUYET') cls = 'auto';
  if (decision === 'TU_DONG_LOAI') cls = 'ban';
  const decLabel = { TU_DONG_DUYET: 'TỰ ĐỘNG DUYỆT', TU_DONG_LOAI: 'TỰ ĐỘNG LOẠI', CHO_HR: 'CHUYỂN HR XEM XÉT' }[decision] || decision;

  box.innerHTML = `
    <div class="result ${cls}">
      <div class="big">${(r.p * 100).toFixed(0)}%</div>
      <div class="dec">${esc(decLabel)}</div>
      <div class="why">${esc(reason)}</div>
      <div style="margin-top:10px;font-size:12.5px;color:#43506a">
        Nhãn mô hình: <b>${esc(r.label)}</b>${savedName ? ' · Đã lưu hồ sơ cho <b>' + esc(savedName) + '</b>' : ''}
      </div>
    </div>`;
}

/* ---------------- kiến trúc ---------------- */

function viewAbout() {
  const rows = Object.keys(STATUS).map(k =>
    `<tr><td><code>${k}</code></td><td>${badge(k)}</td><td>${
      {
        MOI: 'Vừa khởi tạo', CHO_KIEM_TRA: 'Chờ Nhân sự kiểm tra tính đầy đủ',
        CHO_BO_SUNG: 'Chờ Trưởng phòng bổ sung', CHO_SOAN_JD: 'Chờ Nhân sự soạn JD',
        CHO_DUYET_JD: 'Chờ Giám đốc duyệt JD', DANG_TUYEN: 'Đang đăng tin và sàng lọc',
        CHO_PHE_DUYET_NS: 'Chờ Giám đốc phê duyệt kết quả', HOAN_TAT: 'Đã tuyển xong',
        TU_CHOI: 'Bị từ chối, kết thúc'
      }[k]
    }</td></tr>`).join('');

  return `
  <div class="page-head">
    <div>
      <h2>Kiến trúc &amp; quy tắc</h2>
      <p>Phần triển khai tương ứng yêu cầu 4.1 – 4.5 của bài tập</p>
    </div>
  </div>

  <div class="grid2">
    <div>
      <div class="panel">
        <h3>Ba vai trò và quyền hạn</h3>
        <table>
          <thead><tr><th>Vai trò</th><th>Tài khoản</th><th>Được làm</th></tr></thead>
          <tbody>
            <tr><td><b>Trưởng phòng ban</b></td><td><code>truongphong</code></td><td>Tạo yêu cầu, bổ sung hồ sơ khi bị trả về</td></tr>
            <tr><td><b>Chuyên viên Nhân sự</b></td><td><code>nhansu</code></td><td>Kiểm tra đầy đủ, soạn JD, sàng lọc hồ sơ, trình phê duyệt</td></tr>
            <tr><td><b>Giám đốc</b></td><td><code>giamdoc</code></td><td>Duyệt/từ chối JD, phê duyệt/từ chối kết quả tuyển dụng</td></tr>
          </tbody>
        </table>
        <div class="hint" style="margin-top:14px">
          Mọi endpoint đều kiểm tra token phiên và vai trò ở phía máy chủ; giao diện chỉ ẩn nút,
          không phải nơi thực thi quyền.
        </div>
      </div>

      <div class="panel">
        <h3>Luồng XOR bắt buộc</h3>
        <table class="rule-table">
          <thead><tr><th>Chốt</th><th>Nhánh thuận</th><th>Nhánh nghịch</th><th>Quay lại</th></tr></thead>
          <tbody>
            <tr><td>Kiểm tra yêu cầu</td><td><code>kiem_tra_dat</code> → Chờ soạn JD</td><td><code>kiem_tra_thieu</code> → Chờ bổ sung</td><td>Trưởng phòng <code>bo_sung_lai</code></td></tr>
            <tr><td>Duyệt JD</td><td><code>duyet_jd</code> → Đang tuyển</td><td><code>tu_choi_jd</code> → Chờ soạn JD</td><td>Nhân sự soạn lại</td></tr>
            <tr><td>Phê duyệt nhân sự</td><td><code>duyet_ns</code> → Hoàn tất</td><td><code>tu_choi_ns</code> → Từ chối</td><td>Kết thúc quy trình</td></tr>
          </tbody>
        </table>
      </div>
    </div>

    <div>
      <div class="panel">
        <h3>Trạng thái và ý nghĩa</h3>
        <table class="rule-table">
          <thead><tr><th>Mã</th><th>Hiển thị</th><th>Ý nghĩa</th></tr></thead>
          <tbody>${rows}</tbody>
        </table>
      </div>

      <div class="panel">
        <h3>Lưu trữ &amp; tích hợp</h3>
        <ul style="margin:0;padding-left:18px;line-height:1.8;font-size:13.5px">
          <li>Dữ liệu lưu bền trong <code>app/data/db.json</code>, ghi lại sau mỗi thao tác.</li>
          <li>Mật khẩu băm SHA-256, không lưu văn bản thuần.</li>
          <li>Mỗi bước đều ghi <i>audit trail</i>: ai làm, lúc nào, ghi chú gì.</li>
          <li>Điểm sàng lọc do dịch vụ tính toán bên ngoài giao diện, gọi qua API <code>POST /api/requests/:id/screen</code>.</li>
          <li>Máy chủ: PowerShell HttpListener, không cần cài runtime bổ sung.</li>
        </ul>
      </div>
    </div>
  </div>`;
}

/* mở chi tiết từ bảng bằng onclick inline */
window.openReq = openReq;
window.go = go;
window.doAction = doAction;
window.showCreate = showCreate;
window.hideCreate = hideCreate;
window.previewScreen = previewScreen;
