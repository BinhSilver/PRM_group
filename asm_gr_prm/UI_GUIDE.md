# UI Guide - Quản lý tài chính cá nhân

File này dùng để thống nhất giao diện cho cả nhóm khi phát triển tiếp ứng dụng.

## 1. Vai trò UI chung

Phần UI chung phụ trách:

- App shell chính.
- Bottom Navigation.
- Home Dashboard.
- Profile.
- Settings.
- Chế độ tối / chế độ sáng.
- Theme chung.
- Widget dùng chung.
- Placeholder cho các module Giao dịch, Thống kê, Ngân sách.

Các module nghiệp vụ khác chỉ cần gắn màn hình thật vào shell hiện tại, không cần viết lại khung app.

## 2. Cấu trúc file chính

```text
lib/
+-- main.dart
+-- models/
|   +-- user_model.dart
+-- providers/
|   +-- theme_provider.dart
|   +-- user_provider.dart
+-- screens/
|   +-- main_screen.dart
|   +-- home_screen.dart
|   +-- profile_screen.dart
|   +-- settings_screen.dart
|   +-- transactions_placeholder_screen.dart
|   +-- statistics_placeholder_screen.dart
|   +-- budget_placeholder_screen.dart
+-- widgets/
|   +-- app_drawer.dart
|   +-- common_card.dart
|   +-- section_title.dart
|   +-- setting_tile.dart
|   +-- profile_header.dart
|   +-- placeholder_module_card.dart
|   +-- summary_card.dart
|   +-- quick_action_card.dart
+-- utils/
    +-- app_theme.dart
    +-- app_constants.dart
    +-- profile_actions.dart
```

## 3. App Shell

File chính:

```text
lib/screens/main_screen.dart
```

`MainScreen` quản lý 5 tab:

- Trang chủ
- Giao dịch
- Thống kê
- Ngân sách
- Hồ sơ

Hiện tại 3 module nghiệp vụ đang là placeholder:

```dart
const TransactionsPlaceholderScreen(),
const StatisticsPlaceholderScreen(),
const BudgetPlaceholderScreen(),
```

Khi thành viên khác làm xong màn hình thật, chỉ cần thay trong `_screens`:

```dart
late final List<Widget> _screens = [
  HomeScreen(onTabSelected: _changeTab),
  TransactionListScreen(),
  StatisticsScreen(),
  BudgetScreen(),
  const ProfileScreen(),
];
```

Không sửa lại `BottomNavigationBar`, theme, provider hoặc `main.dart` nếu không cần thiết.

## 4. Theme chung

File theme:

```text
lib/utils/app_theme.dart
lib/utils/app_constants.dart
```

Concept giao diện:

```text
Pink Wallet Clean UI
```

Quy chuẩn màu:

- Hồng/tím hiện đại.
- Sạch, gọn, dễ trình bày.
- Không quá rực.
- Chế độ tối không dùng nền đen tuyệt đối.
- Card phải tách rõ khỏi background.

Màu chính trong `AppColors`:

```dart
primary = #D82D8B
secondary = #F062A6
accent = #8E24AA
lightBackground = #FFF5FA
darkBackground = #151018
darkSurface = #221727
```

Khi làm module mới, ưu tiên dùng:

```dart
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.onSurfaceVariant
AppColors.income
AppColors.expense
AppColors.warning
```

Không hard-code nhiều màu riêng trong từng module.

## 5. Widget dùng chung

Team nên dùng widget có sẵn để UI không bị lệch.

### CommonCard

Dùng để bọc nội dung trong card.

```dart
CommonCard(
  child: Column(
    children: [
      Text('Nội dung'),
    ],
  ),
)
```

### SectionTitle

Dùng cho tiêu đề khu vực.

```dart
const SectionTitle(title: 'Tổng quan')
```

### SettingTile

Dùng cho item dạng danh sách trong Profile, Settings hoặc module khác.

```dart
SettingTile(
  icon: Icons.category_rounded,
  title: 'Danh mục',
  subtitle: 'Quản lý danh mục thu chi',
  onTap: () {},
)
```

### SummaryCard

Dùng cho card số liệu nhanh.

```dart
const SummaryCard(
  icon: Icons.trending_up_rounded,
  title: 'Tổng thu',
  amount: '0đ',
  color: AppColors.income,
)
```

### QuickActionCard

Dùng cho tiện ích nhanh dạng icon nhỏ.

### PlaceholderModuleCard

Dùng cho màn hình giữ chỗ khi module chưa hoàn thiện.

## 6. Quy chuẩn layout

Khi làm màn hình mới, nên dùng:

```dart
SafeArea
SingleChildScrollView
Padding
Column
CommonCard
SectionTitle
SettingTile
```

Padding khuyến nghị:

```dart
padding: const EdgeInsets.fromLTRB(16, 8, 16, 24)
```

Khoảng cách giữa các section:

```dart
const SizedBox(height: 22)
```

Card nên dùng `CommonCard`, không tự tạo quá nhiều style riêng.

## 7. Quy chuẩn ngôn ngữ

Ngôn ngữ hiển thị trong app thống nhất là tiếng Việt có dấu.

Ví dụ:

```text
Trang chủ
Giao dịch
Thống kê
Ngân sách
Hồ sơ
```

Không để text bị lỗi mã hóa hoặc lẫn ký tự lạ trong giao diện.

Nếu tạo file mới, lưu file bằng UTF-8.

## 8. Chế độ tối / chế độ sáng

Chế độ tối được quản lý bởi:

```text
lib/providers/theme_provider.dart
```

Settings gọi:

```dart
themeProvider.toggleTheme(value)
```

Trạng thái được lưu bằng:

```text
SharedPreferences
key: isDarkMode
```

Module mới không cần tự xử lý theme. Chỉ cần dùng màu từ `Theme.of(context)` và widget chung.

## 9. Profile

Profile hiện có:

- Avatar/banner.
- Tên hiển thị.
- Username.
- Ngày tạo tài khoản.
- Sửa tên hiển thị inline trên màn hình.
- Đổi mật khẩu placeholder.
- Cài đặt.
- Đăng xuất có xác nhận.

Tên hiển thị được lưu bằng `SharedPreferences` trong:

```text
lib/providers/user_provider.dart
```

Không có login/register thật trong phần UI này.

## 10. Placeholder module

Placeholder hiện có:

```text
transactions_placeholder_screen.dart
statistics_placeholder_screen.dart
budget_placeholder_screen.dart
```

Khi module thật hoàn thành, thay placeholder trong `main_screen.dart`.

Nội dung placeholder nên ngắn gọn, ví dụ:

```text
Sẵn sàng kết nối với màn hình giao dịch thật.
```

Không viết giải thích quá dài trong UI.

## 11. Những phần không thuộc UI task

Không thêm vào phần UI chung:

- CRUD giao dịch thật.
- CRUD ngân sách thật.
- Biểu đồ thống kê thật.
- Login/register thật.
- Firebase.
- API online.
- Logic database nghiệp vụ.

Nếu cần dùng database, module phụ trách nghiệp vụ sẽ tự xử lý.

## 12. Cách chạy project

Từ repo root:

```cmd
cd /d D:\SUM26_FPT\PRM393\PRM_group\asm_gr_prm
flutter pub get
flutter run
```

Nếu đã đứng trong thư mục `asm_gr_prm`:

```cmd
flutter pub get
flutter run
```

## 13. Lệnh kiểm tra trước khi push

Nên chạy:

```cmd
flutter analyze
flutter test --no-pub
flutter build apk --debug
```

Kết quả mong muốn:

```text
flutter analyze: No issues found
flutter test: All tests passed
flutter build apk --debug: Built app-debug.apk
```

## 14. Checklist cho thành viên khác khi gắn module

Trước khi push module mới, kiểm tra:

- Màn hình mới được gắn đúng vào `MainScreen`.
- Không phá `BottomNavigationBar`.
- Dùng `CommonCard`, `SectionTitle`, `SettingTile` khi phù hợp.
- Màu sắc lấy từ theme chung.
- Không tạo theme riêng trong từng màn hình.
- Không làm overflow trên màn hình nhỏ.
- Chạy `flutter analyze`.
- Chạy `flutter test --no-pub`.

## 15. Tóm tắt

Phần UI chung là khung chính của app. Các module khác chỉ cần thay placeholder bằng màn hình thật và dùng lại widget/theme chung để giao diện đồng bộ.

