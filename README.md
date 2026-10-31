# TP3.2 — Tự động hóa quy trình tuyển dụng nhân sự

**Môn:** MIS3047 — Nhóm 8

Ứng dụng web hỗ trợ quy trình tuyển dụng từ lập yêu cầu đến tiếp nhận nhân sự, có phân quyền theo vai trò, luồng phê duyệt qua cổng XOR và tích hợp AI hỗ trợ sàng lọc hồ sơ.

## Cấu trúc

| Thư mục | Nội dung |
|---|---|
| `docs/` | Báo cáo theo chương, kế hoạch phiên, đề bài gốc |
| `bpmn/as-is/` | Mô hình hiện trạng (.bpmn + .png) |
| `bpmn/to-be/` | Mô hình cải tiến (.bpmn + .png) |
| `bimp/` | Cấu hình và kết quả mô phỏng BIMP |
| `app/` | Mã nguồn ứng dụng web |
| `screenshots/` | Ảnh chụp minh chứng theo phiên |

## Chạy ứng dụng

Không cần cài Node.js, Python hay .NET — chỉ cần Windows và PowerShell 5.1 có sẵn.

```powershell
# cách 1: nhấp đúp
app\run.cmd

# cách 2: chạy trực tiếp
powershell -NoProfile -ExecutionPolicy Bypass -File app\server.ps1 -Port 8090
```

Sau đó mở <http://localhost:8090/>. Tài khoản demo (mật khẩu `Demo@123`):

| Tài khoản | Vai trò | Việc được làm |
|---|---|---|
| `truongphong` | Trưởng phòng ban | Tạo yêu cầu, bổ sung hồ sơ |
| `nhansu` | Chuyên viên Nhân sự | Kiểm tra, soạn JD, sàng lọc, trình duyệt |
| `giamdoc` | Giám đốc | Duyệt JD, phê duyệt kết quả |

Kiểm thử tự động (tự bật máy chủ riêng ở cổng 8091 với dữ liệu sạch, không ảnh hưởng dữ liệu demo):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\Test-App.ps1
```

Dữ liệu chạy nằm ở `app/data/db.json`, được tạo lại từ dữ liệu mẫu nếu xoá tệp này.

## Tài liệu

- Kế hoạch và bảng truy vết yêu cầu: [`docs/00_KE_HOACH_PHIEN.md`](docs/00_KE_HOACH_PHIEN.md)
- 3.1 Bản đồ AI trên quy trình: `docs/chuong-3/3.1_Ban_do_AI_tren_quy_trinh.docx`
- 3.2 Thiết kế ngưỡng tin cậy: `docs/chuong-3/3.2_Thiet_ke_nguong_tin_cay.docx`

## Trạng thái

| Chương | Tiến độ |
|---|---|
| Chương 1 | Chưa bắt đầu |
| Chương 2 | AS-IS mới (2 pool, 3 lane, 4 XOR, 2 AND, 3 ngoại lệ) + BIMP; TO-BE còn lỗi mô hình cần sửa |
| Chương 3 | 3.1 xong, 3.2 xong, 3.3 chưa |
| Chương 4 | Ứng dụng chạy được: 3 vai trò, 3 luồng XOR, lưu trữ JSON, API sàng lọc, 27 test tự động PASS; còn thiếu ảnh chụp minh chứng và nhật ký AI đủ 10 mục |

## Quy ước commit

```
docs(ch1): ...     nội dung chương 1
feat(ch2): ...     mô hình BPMN
docs(ch3): ...     nội dung chương 3
feat(app): ...     mã nguồn ứng dụng
test(ch4): ...     kiểm thử, bảo mật
chore(repo): ...   cấu hình repo
```
