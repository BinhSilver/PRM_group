# 💰 Ứng Dụng Quản Lý Thu Chi Cá Nhân (Personal Finance Manager)

Một ứng dụng hỗ trợ quản lý tài chính cá nhân toàn diện, giúp người dùng theo dõi chi tiết dòng tiền (thu/chi), thiết lập ngân sách và thống kê qua các biểu đồ trực quan.

## 🚀 Tính Năng (Features)

### 📌 Chức năng cốt lõi (Core Features)
* **Xác thực người dùng:** Đăng ký, Đăng nhập, Đăng xuất bảo mật.
* **Quản lý giao dịch:** * Thêm, Sửa, Xóa các khoản thu/chi nhanh chóng.
  * Xem danh sách chi tiết các giao dịch.
* **Tổng quan tài chính:** Tự động tính toán tổng thu, tổng chi và số dư hiện tại.

### 🌟 Chức năng mở rộng (Advanced Features)
* **Phân loại giao dịch (Categories):**
  * 📈 *Thu:* Lương, Thưởng, Bán hàng,...
  * 📉 *Chi:* Ăn uống, Đi lại, Học tập, Giải trí,...
* **Tìm kiếm & Lọc (Search & Filter):**
  * Tìm kiếm giao dịch theo tên hoặc ghi chú.
  * Lọc theo Loại (Thu/Chi), theo Danh mục, hoặc theo khoảng thời gian (hôm nay, tuần này, tháng này).
* **Sắp xếp linh hoạt (Sorting):**
  * Theo thời gian: Mới nhất / Cũ nhất.
  * Theo số tiền: Tăng dần / Giảm dần.
* **Thống kê & Biểu đồ (Statistics & Charts):**
  * Báo cáo tổng thu, tổng chi, số dư, và tổng số giao dịch trong tháng.
  * 🍩 *Biểu đồ tròn (Pie Chart):* Thể hiện cơ cấu danh mục chi tiêu.
  * 📊 *Biểu đồ cột (Bar Chart):* So sánh thu - chi theo tháng.
* **Quản lý Ngân sách (Budgeting):**
  * Thiết lập ngân sách chi tiêu hàng tháng.
  * Hiển thị số tiền đã chi và số tiền còn lại.
  * ⚠️ *Cảnh báo (Alert):* Thông báo in-app (hiển thị trong ứng dụng) khi chi tiêu vượt mốc ngân sách.
* **Quản lý Hồ sơ (Profile Management):**
  * Cập nhật tên hiển thị.
  * Đổi mật khẩu.
* **Giao diện (UI/UX):**
  * Hỗ trợ hai chế độ sáng/tối (☀️ Light Mode / 🌙 Dark Mode).

## 🛠 Công nghệ sử dụng (Tech Stack)
* **Framework:** [Flutter](https://flutter.dev/) (Dart)
* **State Management:** Provider / Riverpod / BLoC *(bạn có thể xóa bớt nếu dùng 1 cái)*
* **Lưu trữ (Local Storage/Database):** SQLite / SharedPreferences / Firebase *(bạn tự điều chỉnh theo app của mình nhé)*
* **Biểu đồ:** `fl_chart` hoặc `syncfusion_flutter_charts` *(tên package bạn dùng)*

## 📸 Ảnh chụp màn hình (Screenshots)
*(Thêm link ảnh màn hình ứng dụng của bạn vào đây)*
| Trang Chủ | Thống Kê | Thêm Giao Dịch | Chế Độ Tối |
| :---: | :---: | :---: | :---: |
| ![Home](link-anh-1) | ![Stats](link-anh-2) | ![Add](link-anh-3) | ![Dark](link-anh-4) |

## ⚙️ Cài đặt & Chạy ứng dụng (Getting Started)

Làm theo các bước sau để chạy dự án trên máy tính của bạn:

1. **Clone repository này về máy:**
   ```bash
   git clone [https://github.com/your-username/ten-repo-cua-ban.git](https://github.com/your-username/ten-repo-cua-ban.git)
