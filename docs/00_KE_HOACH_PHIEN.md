# Kế hoạch triển khai — TP3.2 (MIS3047)

**Đề tài:** Tự động hóa quy trình tuyển dụng nhân sự
**Nhóm:** 8
**Tài liệu gốc:** `docs/00_YC_bao_cao_MIS3047.pdf`

---

## 1. Cấu trúc thư mục

```
Tuyendungnhansu/
├── README.md
├── .gitignore
├── docs/
│   ├── 00_YC_bao_cao_MIS3047.pdf      # đề bài gốc
│   ├── 00_KE_HOACH_PHIEN.md           # file này
│   ├── chuong-1/                       # Giới thiệu bài toán nghiệp vụ
│   ├── chuong-2/                       # Mô hình hóa quy trình
│   ├── chuong-3/                       # Thiết kế tự động hóa & phần mềm
│   └── chuong-4/                       # Xây dựng, kiểm thử, đánh giá
├── bpmn/
│   ├── as-is/                          # .bpmn + .png
│   └── to-be/                          # .bpmn + .png
├── bimp/                               # cấu hình + kết quả mô phỏng BIMP
├── app/                                # mã nguồn ứng dụng web
└── screenshots/                        # ảnh chụp minh chứng theo phiên
```

---

## 2. Bảng truy vết yêu cầu → phiên làm việc

| # | Yêu cầu của đề | Phiên | Trạng thái |
|---|---|---|---|
| 1.1 | Tên quy trình + lý do chọn (có thật, đã trải nghiệm/khảo sát) | 01 | Chưa |
| 1.2 | Bối cảnh: tổ chức, ≥ 3 vai trò, vấn đề | 01 | Chưa |
| 1.3 | Điểm nghẽn cụ thể kèm số liệu ước lượng | 01 | Chưa |
| 1.4 | Mục tiêu & phạm vi (làm gì / không làm gì) | 01 | Chưa |
| 1.5 | Tóm tắt sản phẩm: BPMN to-be, web app, video | 01 | Chưa |
| 2.1 | As-is: ≥ 2 lane, 1 XOR, 1 AND, 1 data object, 1 timer + .bpmn + .png | 02 | **Thiếu AND, thiếu timer** |
| 2.2 | BIMP: thời gian xử lý/chờ, tần suất nhánh, vai trò, thời gian chu trình, số bàn giao, 3 nút cổ chai, bảng | 03 | Chưa |
| 2.3 | ≥ 3 ngoại lệ: boundary timer không ngắt, boundary error, event sub-process | 02 | **Thiếu timer không ngắt, thiếu event sub-process** |
| 2.4 | To-be: ≥ 3 XOR, 3 vai trò, ~20 activities, giải thích can thiệp | 03 | Đạt khung, cần rà |
| 3.1 | Bản đồ AI 4 nhóm + lý do + rủi ro | 04 | **Xong** |
| 3.2 | Ngưỡng tin cậy: X, Y, bảng tính, lập luận | 05 | **Xong** |
| 3.3 | Thiết kế phần mềm (IDEA): dữ liệu, màn hình, ánh xạ BPMN, stack, quyết định kiến trúc | 06 | Chưa |
| 4.1 | Web app: ≥ 3 vai trò, ≥ 3 luồng XOR, lưu trữ, ≥ 1 tích hợp, test tự động, ≥ 15 commit | 07, 08 | Chưa |
| 4.2 | Nhật ký AI ≥ 10 lượt, ≥ 2 lượt thất bại có phân tích | 04→10 | Đang tích lũy |
| 4.3 | Kiểm thử + bảo mật, 6 nhóm tiêu chí, checklist đã ký | 09 | Chưa |
| 4.4 | So sánh as-is/to-be bằng số liệu, hạn chế, đề xuất | 10 | Chưa |
| 4.5 | Kết luận + bài học | 10 | Chưa |

---

## 3. Chi tiết các phiên

### Phiên 01 — Chương 1: Giới thiệu bài toán nghiệp vụ  `[chưa làm]`
- **Đầu ra:** `docs/chuong-1/chuong-1.docx`
- **Nội dung:** 5 mục 1.1 → 1.5; bảng 3 vai trò; bảng điểm nghẽn kèm số liệu (số hồ sơ/tháng, thời gian sàng lọc, tỷ lệ bỏ sót phản hồi, thời gian chờ duyệt).
- **Điều kiện hoàn thành:** mỗi khẳng định về điểm nghẽn có ít nhất một con số hoặc một câu dẫn nguồn khảo sát.
- **Ảnh cần chụp:** trang bảng điểm nghẽn, sơ đồ 3 vai trò.

### Phiên 02 — Chương 2.1 + 2.3: Mô hình as-is và ngoại lệ  `[đang mở]`
- **Đầu ra:** `bpmn/as-is/as-is.bpmn` + `.png`
- **Việc phải làm** (xem mục 4 — phân tích thiếu hụt):
  1. Bổ sung 1 cổng AND (song song) — gợi ý: sau khi YC được duyệt, song song “Lập kế hoạch” và “Chuẩn bị kênh đăng tin”.
  2. Bổ sung 1 sự kiện hẹn giờ (intermediate timer) — gợi ý: “Chờ phản hồi ứng viên 2 ngày”.
  3. Bổ sung boundary timer **không ngắt** trên task duyệt — “Nhắc quá hạn 3 ngày” (vẫn cho duyệt tiếp).
  4. Bổ sung event sub-process — “Huỷ yêu cầu tuyển dụng” (người đề nghị rút YC ở bất kỳ thời điểm nào).
  5. Giữ boundary error đã có; xuất PNG.
- **Commit:** `feat(ch2): hoan thien as-is voi AND, timer, 3 ngoai le`

### Phiên 03 — Chương 2.2 + 2.4: BIMP và mô hình to-be  `[chưa làm]`
- **Đầu ra:** `bimp/ket_qua_mo_phong.xlsx`, `docs/chuong-2/chuong-2.docx`
- **Việc phải làm:**
  1. Gắn cho mọi task: thời gian xử lý (phút), thời gian chờ, xác suất nhánh, vai trò.
  2. Chạy BIMP ≥ 1.000 instance; xuất thời gian chu trình trung bình, số bàn giao.
  3. Xác định 3 nút cổ chai (dự kiến: Sàng lọc hồ sơ, Chờ duyệt JD, Chờ ứng viên xác nhận).
  4. Chốt to-be: 3 XOR, 3 vai trò, ~20 activities; bảng can thiệp “trước → sau → lý do”.
- **Commit:** `feat(ch2): ket qua BIMP va mo hinh to-be`

### Phiên 04 — 3.1 Bản đồ AI  `[xong]`
- **Đầu ra:** `docs/chuong-3/3.1_Ban_do_AI_tren_quy_trinh.docx` (11 trang, 51 hoạt động)
- **Commit:** `docs(ch3): ban do AI 4 nhom cho 51 hoat dong`

### Phiên 05 — 3.2 Thiết kế ngưỡng  `[xong]`
- **Đầu ra:** `docs/chuong-3/3.2_Thiet_ke_nguong_tin_cay.docx` (7 trang)
- **Kết quả chính:** X = 25.000 đ; Y_R = 1.200.000 đ; Y_A = 300.000 đ; ngưỡng 97,9% (loại) / 91,7% (duyệt).
- **Commit:** `docs(ch3): thiet ke nguong tin cay cho AI sang loc`

### Phiên 06 — 3.3 Thiết kế phần mềm  `[chưa làm]`
- **Đầu ra:** `docs/chuong-3/3.3_Thiet_ke_phan_mem.docx` + `app/db/schema.sql`
- **Việc phải làm:** 5 mục theo khung IDEA — mô hình dữ liệu (bảng/trường/khóa/quan hệ), danh sách màn hình × vai trò, bảng ánh xạ BPMN → tính năng, ngăn xếp công nghệ kèm lý do, 4 quyết định kiến trúc (dữ liệu ở đâu, phân quyền, chạy ở đâu, quản lý khóa bí mật).
- **Commit:** `feat(ch3): thiet ke du lieu va kien truc ung dung`

### Phiên 07 — 4.1 Ứng dụng web (phần 1)  `[chưa làm]`
- Khung dự án, xác thực 3 vai trò, cơ sở dữ liệu, màn hình YC + JD.
- **Commit:** `feat(app): xac thuc 3 vai tro va luong tao yeu cau`

### Phiên 08 — 4.1 Ứng dụng web (phần 2)  `[chưa làm]`
- 3 luồng phê duyệt qua cổng XOR, tích hợp bên ngoài (email/calendar), bộ test tự động, đủ ≥ 15 commit.
- **Commit:** `feat(app): ba luong phe duyet va tich hop ngoai`

### Phiên 09 — 4.3 Kiểm thử và bảo mật  `[chưa làm]`
- Kịch bản chính + ngoại lệ, báo cáo 6 nhóm tiêu chí, checklist bảo mật đã ký.
- **Commit:** `test(ch4): bo kiem thu va bao cao bao mat`

### Phiên 10 — 4.2 + 4.4 + 4.5 và đóng gói  `[chưa làm]`
- Nhật ký AI đủ 10 lượt, bảng so sánh as-is/to-be, kết luận, video.
- **Commit:** `docs(ch4): nhat ky AI, danh gia hieu qua va ket luan`

---

## 4. Phân tích thiếu hụt so với yêu cầu (cập nhật 31/10/2026)

| Yêu cầu | Mô hình hiện có | Kết luận |
|---|---|---|
| As-is ≥ 2 lane | 3 lane nội bộ + 1 pool ứng viên | Đạt |
| As-is có XOR | 2 cổng XOR | Đạt |
| As-is có AND | **Không có** | **Thiếu** |
| As-is có data object | 3 data object + 3 data store | Đạt |
| As-is có sự kiện hẹn giờ | **Không có** | **Thiếu** |
| To-be ≥ 3 XOR | 6 cổng XOR | Đạt |
| To-be 3 vai trò | Phòng ban / Nhân sự / Giám đốc | Đạt |
| To-be ~20 activities | 19 task + 3 sub-process | Đạt |
| Boundary timer không ngắt | **Không có** | **Thiếu** |
| Boundary error | 2 (CV bị loại, huỷ lịch) | Đạt |
| Event sub-process | **Không có** | **Thiếu** |
| BIMP | **Chưa chạy** | **Thiếu** |

**Kết luận:** Chương 2 phải làm lại một phần trước khi sang Chương 4, vì 3.3 (ánh xạ BPMN → tính năng) và 4.4 (so sánh số liệu) đều lấy đầu vào từ mô hình.

---

## 5. Quy ước Git

- Nhánh: `main`; mỗi phiên một nhánh `phien-XX` nếu cần.
- Commit theo mẫu: `loai(pham_vi): noi_dung ngan`
  - `docs(ch1)`, `feat(ch2)`, `docs(ch3)`, `feat(app)`, `test(ch4)`, `chore(repo)`
- Mỗi phiên **tối thiểu 2 commit**: một cho nội dung, một cho ảnh minh chứng.
- Không commit: `node_modules/`, `.env`, file build, dữ liệu cá nhân thật.

---

## 6. Nhật ký phiên

| Phiên | Ngày | Nội dung | Commit | Ghi chú |
|---|---|---|---|---|
| 04 | 31/10/2026 | 3.1 Bản đồ AI | — | 51 hoạt động, 4 nhóm |
| 05 | 31/10/2026 | 3.2 Ngưỡng tin cậy | — | 7 trang, 5 bảng |
