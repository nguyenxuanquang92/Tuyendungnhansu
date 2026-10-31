# Nhật ký làm việc với AI — Phiên 03 (ứng dụng web và tài liệu Chương 2)

> Tiếp nối `phien-02.md`. Phiên này dựng phần mềm cho Chương 4 và sinh bản `.docx` cho mục 2.1–2.3.
> Đánh dấu **[THẤT BẠI]** cho các lượt không đạt yêu cầu ngay lần đầu.

---

## Lượt 04 — Dựng khung ứng dụng web ba vai trò

**Prompt (rút gọn):**
> Viết ứng dụng web cho quy trình tuyển dụng đã thiết kế: ba vai trò (trưởng phòng, nhân sự, giám đốc), ba luồng phê duyệt XOR, lưu dữ liệu bền vững, có tích hợp gọi dịch vụ sàng lọc. Máy chỉ có PowerShell, không cài được Node/Python/.NET.

**Kết quả:** `app/server.ps1` (HttpListener, token phiên, SHA-256, ghi JSON sau mỗi thao tác, audit trail), `app/public/` gồm `index.html`, `styles.css`, `app.js`. Toàn bộ kiểm tra quyền nằm ở máy chủ, giao diện chỉ ẩn nút.

**Đánh giá:** Đạt. Ràng buộc “không có runtime” được xử lý bằng HttpListener của .NET có sẵn trong Windows — đúng hướng, không phải cài thêm gì.

**Điều chỉnh:** Bổ sung endpoint `POST /api/requests/:id/candidates` để hồ sơ đã sàng lọc được lưu lại, thay vì chỉ trả kết quả rồi mất.

**Bài học:** Khi môi trường bị giới hạn, nên tìm năng lực có sẵn trong hệ điều hành trước khi tìm cách cài đặt thêm.

---

## Lượt 05 — [THẤT BẠI] Công thức sàng lọc làm vùng cấm không thể xảy ra

**Prompt:**
> Viết hàm tính độ tin cậy p cho hồ sơ ứng viên theo số năm kinh nghiệm, trình độ, kỹ năng; áp ba ngưỡng 92% / 98% / 50% đã thiết kế ở mục 3.2.

**Kết quả:** Hàm chạy được và trả về đúng nhãn, nhưng bộ kiểm thử báo lỗi ở kịch bản “hồ sơ yếu rơi vào vùng cấm”: p đo được là **0,55**, không bao giờ nhỏ hơn 0,5.

**Đánh giá:** **Thất bại.** Nguyên nhân: công thức đặt hằng số nền 0,55 rồi chỉ cộng thêm, nên miền giá trị của p là [0,55; 0,99]. Quy tắc “p < 50% thì bắt buộc HR xem” trở thành **code chết** — nhìn qua thì đúng, chạy thật thì không bao giờ kích hoạt. Đây là lỗi loại *đặc tả không được kiểm chứng bằng dữ liệu biên*, nguy hiểm vì hệ thống vẫn “chạy đúng” ở các ca thông thường.

**Điều chỉnh:** Đổi sang `p = 0,35 + 0,04 × số năm + điểm trình độ + điểm kỹ năng`, giới hạn trên 0,99. Kiểm chứng lại bốn điểm: 0 năm, trình độ khác → 0,35 (vùng cấm); 2 năm, cao đẳng → 0,51 (HR xem); 7 năm, đại học → 0,91 (HR xem); 9 năm, đại học, có kỹ năng → 0,99 (tự động duyệt).

**Bài học:** Mỗi ngưỡng trong đặc tả phải có **ít nhất một ca kiểm thử chứng minh ngưỡng đó chạm tới được**. Ngưỡng không chạm tới được thì không phải là ngưỡng.

---

## Lượt 06 — [THẤT BẠI] Chuyển HTML sang DOCX bằng Word tự động hoá bị treo

**Prompt:**
> Dùng Microsoft Word (COM) mở tệp HTML của mục 2.1–2.3, đặt khổ A4, lề theo quy định và lưu thành .docx.

**Kết quả:** Tiến trình treo quá 10 phút, không sinh được tệp; phải kill tiến trình `WINWORD` treo. Thử lại lần hai với tham số chặt hơn (ReadOnly, tắt hộp thoại, tắt cập nhật liên kết) vẫn treo.

**Đánh giá:** **Thất bại.** Nguyên nhân: phụ thuộc vào một tiến trình COM có giao diện, không có cơ chế timeout, và không quan sát được nó đang chờ gì. Bản thân Word vẫn mở được các tệp .docx khác, nên lỗi nằm ở đường dẫn chuyển đổi HTML → Word, không phải ở Word.

**Điều chỉnh:** Bỏ hẳn Word khỏi quy trình sinh tài liệu. Viết `tools/HtmlToDocx.ps1` tự dựng gói OOXML (Content Types, relationships, document.xml, styles.xml) bằng `System.IO.Compression` — thư viện có sẵn, chạy trong 2 giây, không phụ thuộc phần mềm ngoài.

**Bài học:** Công cụ tự động hoá có giao diện (COM, GUI automation) là điểm treo tiềm ẩn trong quy trình lặp lại. Nếu định dạng đầu ra là chuẩn mở thì nên sinh trực tiếp theo chuẩn.

---

## Lượt 07 — [THẤT BẠI] Tệp DOCX sinh ra bị Word báo hỏng

**Prompt:**
> Kiểm tra tệp .docx vừa sinh bằng cách mở lại trong Word và đếm số trang.

**Kết quả:** Word báo “The file appears to be corrupted” / “Word experienced an error trying to open the file”. Gói OOXML có đủ 7 phần, XML đều parse hợp lệ, nhưng Word từ chối.

**Đánh giá:** **Thất bại.** Đây là lỗi khó vì thông báo của Word không nêu vị trí sai. Cách xử lý: thu hẹp phạm vi bằng thực nghiệm — dựng gói tối giản 3 phần (Content Types, .rels, document.xml) với một đoạn văn “Hello” thì **mở được**; thay dần từng phần của bản sinh tự động vào thì lỗi quay lại; cuối cùng cô lập được đúng một thuộc tính: `<w:jc w:val="justify"/>`.

**Nguyên nhân gốc:** `justify` là giá trị của CSS, **không** thuộc danh sách giá trị hợp lệ của `w:jc` trong OOXML (Word dùng `both` cho căn đều hai bên). Word không báo “giá trị không hợp lệ” mà báo hỏng cả tệp.

**Điều chỉnh:** Ánh xạ `justify → both` khi sinh XML. Kết quả: tệp mở được trong Word, 3 trang, 1.338 từ, 7 bảng; đồng thời xuất PDF để đối chiếu bố cục.

**Bài học:** Với định dạng đặc tả chặt, phải tra bảng giá trị hợp lệ chứ không suy ra từ tên gọi quen thuộc. Và khi công cụ báo lỗi mơ hồ, phương pháp hiệu quả là **chia đôi phạm vi** cho tới khi còn một biến duy nhất.

---

## Lượt 08 — Sửa lỗi hiển thị thẻ kết quả sàng lọc

**Prompt:**
> Thẻ kết quả sàng lọc hiện đúng số phần trăm nhưng dòng quyết định và lý do bị trống khi bấm “Sàng lọc & lưu hồ sơ”.

**Kết quả:** Nguyên nhân: endpoint lưu hồ sơ trả về trường `status`/`note`, còn hàm hiển thị đọc `decision`/`reason` (hai trường này chỉ có ở endpoint xem trước). Giao diện nhận `undefined` nên in chuỗi rỗng.

**Đánh giá:** Đạt sau khi sửa, nhưng lỗi đáng lẽ bị bắt sớm hơn: hai endpoint cùng một nghiệp vụ mà trả hai hình dạng dữ liệu khác nhau.

**Điều chỉnh:** Chuẩn hoá ở phía giao diện (`r.decision || r.status`), đồng thời ghi nhận việc cần thống nhất schema ở lần tái cấu trúc sau.

**Bài học:** Hai endpoint mô tả cùng một quyết định phải trả cùng một schema; nếu không, lỗi sẽ nằm ở lớp hiển thị và rất khó thấy khi chỉ đọc mã.

---

## Lượt 09 — Viết bộ kiểm thử tự động

**Prompt (rút gọn):**
> Viết script kiểm thử tự chạy: khởi động máy chủ riêng với dữ liệu sạch, kiểm tra xác thực, phân quyền, ba luồng XOR, các ngưỡng tin cậy và lưu trữ bền vững.

**Kết quả:** `tools/Test-App.ps1` — 27 kiểm thử, chạy trên cổng 8091 với thư mục dữ liệu riêng, tự dọn dẹp sau khi xong. Kết quả 27/27 đạt.

**Đánh giá:** Đạt. Bộ kiểm thử phát hiện đúng hai lỗi thật (lượt 05 và lượt 08) mà đọc mã không thấy.

**Điều chỉnh:** Thêm các ca biên: thao tác sai vai trò (mong đợi 403), thao tác sai trạng thái (409), lưu JD thiếu nội dung (400), và kiểm tra mật khẩu không lưu dạng văn bản thuần.

**Bài học:** Kiểm thử có giá trị nhất khi nó chạm được **biên** của miền giá trị, không phải khi nó lặp lại ca thành công.

---

## Tổng hợp phiên 03

| Lượt | Nội dung | Kết quả |
|---|---|---|
| 04 | Dựng ứng dụng web ba vai trò | Đạt |
| 05 | Công thức sàng lọc | **Thất bại** → sửa công thức |
| 06 | HTML → DOCX bằng Word COM | **Thất bại** → bỏ Word |
| 07 | DOCX bị Word báo hỏng | **Thất bại** → sửa `w:jc` |
| 08 | Thẻ kết quả trống nhãn | Đạt sau khi sửa |
| 09 | Bộ kiểm thử tự động | Đạt |

Lũy kế đến hết phiên 03: **9 lượt**, trong đó **4 lượt thất bại có phân tích** (vượt mức tối thiểu 2). Còn thiếu 1 lượt để đủ 10 — dự kiến ghi ở phiên hoàn thiện báo cáo.
