# Nhật ký làm việc với AI — Phiên 02 (mục 3.1 và 3.2)

> Yêu cầu 4.2 cần **≥ 10 lượt tương tác đáng chú ý**, mỗi lượt gồm: prompt, kết quả, đánh giá, điều chỉnh — và **≥ 2 lượt thất bại** có phân tích nguyên nhân.
> File này ghi các lượt của phiên 02. Nhóm bổ sung/sửa lại theo đúng prompt thực tế đã dùng.

---

## Lượt 01 — Phân rã quy trình TO-BE vào 4 nhóm tự động hóa

**Prompt (rút gọn):**
> Dựa trên quy trình TO-BE tuyển dụng nhân sự (9 bước), phân rã toàn bộ activities vào 4 nhóm: giữ thủ công, tự động theo luật, tự động có AI hỗ trợ, giao cho AI Agent. Với mỗi bước nêu lý do và mức độ rủi ro nếu hệ thống xử lý sai.

**Kết quả:** 51 hoạt động, phân bố 8 / 22 / 15 / 6. Kèm bảng tổng hợp 9 bước và 6 ranh giới đỏ.

**Đánh giá:** Đạt yêu cầu về độ phủ và có luận cứ cho từng nhóm. Điểm yếu: lần đầu AI có xu hướng gán quá nhiều hoạt động cho Agent (những việc chỉ cần luật như đăng tin, sinh quyết định).

**Điều chỉnh:** Bổ sung tiêu chí “tiêu chí thành công phải kiểm chứng được bằng máy + đảo ngược được” để loại các hoạt động không phù hợp khỏi nhóm Agent; hạ các hoạt động sinh văn bản từ mẫu xuống nhóm “tự động theo luật”.

**Bài học:** Cần đặt tiêu chí phân loại **trước** khi phân loại, nếu không AI sẽ phân loại theo cảm nhận về mức độ “hiện đại” của công nghệ.

---

## Lượt 02 — THẤT BẠI: đọc file PDF yêu cầu dự án

**Prompt:**
> Đọc file “YC báo cáo dự án MIS3047 (1).pdf” và tóm tắt các yêu cầu bắt buộc.

**Kết quả:** Công cụ trả về lỗi: mô hình không hỗ trợ đầu vào PDF. Không trích xuất được nội dung.

**Đánh giá:** **Thất bại.** Nguyên nhân thuộc nhóm *giới hạn công cụ*, không phải lỗi suy luận: định dạng đầu vào không được hỗ trợ nên toàn bộ bước đọc thất bại ngay từ đầu.

**Điều chỉnh:** Chuyển sang đọc hai file `.bpmn` (định dạng văn bản, đọc được toàn bộ) để lấy nội dung quy trình, và yêu cầu người dùng dán trực tiếp phần yêu cầu báo cáo vào chat. Kết quả: vẫn hoàn thành mục 3.1 đúng hạn.

**Bài học:** Trước khi giao việc đọc tài liệu, phải kiểm tra định dạng có đọc được không. Nếu không, xin nội dung dạng văn bản ngay thay vì cố xử lý.

---

## Lượt 03 — Thiết kế ngưỡng tin cậy cho AI sàng lọc

**Prompt (rút gọn):**
> Thiết kế bài toán ngưỡng tin cậy cho bước sàng lọc hồ sơ tự động. Nêu giả định chi phí thủ công X và thiệt hại khi sai Y. Lập bảng chi phí theo các mức tin cậy (<50%, 50–85%, >85%) và lập luận xác định ngưỡng tối ưu.

**Kết quả:** Mô hình chi phí kỳ vọng; X = 25.000 đ; Y_R = 1.200.000 đ; Y_A = 300.000 đ; ngưỡng hoà vốn 97,3% (một ngưỡng), tách thành 97,9% và 91,7% khi tính riêng hai hướng.

**Đánh giá:** Đạt. Phát hiện quan trọng: nếu dùng **một** ngưỡng chung thì không chính sách nào rẻ hơn làm thủ công; chỉ khi tách hai hướng mới có lãi.

**Điều chỉnh:** Không dùng ba dải như đề bài gợi ý mà tách dải trên thành 85–92 / 92–98 / ≥98, vì mô hình cho thấy quyết định đảo chiều ngay trong dải “> 85%”. Bổ sung bảng độ nhạy theo X và theo Y.

**Bài học:** Con số ngưỡng phải suy ra từ công thức `p* = 1 − X/Y`, không được chọn theo thói quen. Và chi phí của hai loại sai khác nhau 4 lần thì bắt buộc phải có hai ngưỡng.

---

## Các lượt cần bổ sung cho đủ 10

| # | Nội dung | Trạng thái |
|---|---|---|
| 04 | Sửa lỗi logic BPMN (nhánh “Không đạt” chạy sang Lập quyết định) | cần ghi |
| 05 | Kiểm tra mô hình as-is có đủ AND / timer chưa | cần ghi |
| 06 | Sinh mô hình dữ liệu cho 3.3 | chưa làm |
| 07 | Sinh mã nguồn khung ứng dụng | chưa làm |
| 08 | Viết bộ kiểm thử | chưa làm |
| 09 | Rà soát bảo mật | chưa làm |
| 10 | Viết kết luận | chưa làm |

**Lượt thất bại thứ hai bắt buộc:** ghi lại khi xảy ra ở các phiên sau (dự kiến ở phần sinh mã nguồn hoặc kiểm thử), kèm phân tích theo mẫu thất bại.
