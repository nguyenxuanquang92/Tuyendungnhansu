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

## Tài liệu

- Kế hoạch và bảng truy vết yêu cầu: [`docs/00_KE_HOACH_PHIEN.md`](docs/00_KE_HOACH_PHIEN.md)
- 3.1 Bản đồ AI trên quy trình: `docs/chuong-3/3.1_Ban_do_AI_tren_quy_trinh.docx`
- 3.2 Thiết kế ngưỡng tin cậy: `docs/chuong-3/3.2_Thiet_ke_nguong_tin_cay.docx`

## Trạng thái

| Chương | Tiến độ |
|---|---|
| Chương 1 | Chưa bắt đầu |
| Chương 2 | Mô hình có sẵn, thiếu AND / timer / ngoại lệ |
| Chương 3 | 3.1 xong, 3.2 xong, 3.3 chưa |
| Chương 4 | Chưa bắt đầu |

## Quy ước commit

```
docs(ch1): ...     nội dung chương 1
feat(ch2): ...     mô hình BPMN
docs(ch3): ...     nội dung chương 3
feat(app): ...     mã nguồn ứng dụng
test(ch4): ...     kiểm thử, bảo mật
chore(repo): ...   cấu hình repo
```
