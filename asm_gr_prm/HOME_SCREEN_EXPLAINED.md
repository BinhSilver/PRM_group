# Giải thích chi tiết Trang chủ (Home Screen) + FULL CODE

Tài liệu này phục vụ **thuyết trình / demo phần Trang chủ**.  
Có **full source code** để đọc trực tiếp + giải thích công dụng từng khối / từng dòng quan trọng.

---

## 1. Bản đồ file liên quan

| Vai trò | Đường dẫn | Mô tả ngắn |
|--------|-----------|------------|
| **Màn hình chính Trang chủ** | `lib/screens/home_screen.dart` | UI + logic hiển thị toàn bộ nội dung tab Trang chủ |
| **Khung app (AppBar + Bottom Nav)** | `lib/screens/main_screen.dart` | Gắn `HomeScreen` vào tab index `0`, xử lý đổi tab |
| **Widget nút tiện ích** | `lib/widgets/quick_action_card.dart` | Icon tròn + chữ bên dưới |
| **Tiêu đề section** | `lib/widgets/section_title.dart` | Chữ “Tiện ích nhanh” |
| **Thẻ bo góc dùng chung** | `lib/widgets/common_card.dart` | Card nền + viền + shadow |
| **Format tiền VNĐ** | `lib/utils/currency_formatter.dart` | `1000000` → `1.000.000 đ` |
| **Màu app** | `lib/utils/app_constants.dart` | `AppColors.primary`, `income`, `expense`, … |
| **State giao dịch** | `lib/providers/transaction_provider.dart` | `balance`, `totalIncome`, `totalExpense` |
| **State hũ chi tiêu** | `lib/providers/spending_jar_provider.dart` | `jars`, `remainingInJars`, `getRemaining()` |
| **State user** | `lib/providers/user_provider.dart` | `currentUser.displayName` |
| **Tính tổng thu/chi/số dư DB** | `lib/database/transaction_repository.dart` | `getFinancialSummary()` |

---

## 2. FULL CODE — `lib/screens/main_screen.dart`

**Công dụng file:** khung app (AppBar + body + bottom nav). Gắn `HomeScreen` ở tab `0`.

```dart
import 'package:flutter/material.dart';

import '../utils/app_constants.dart';
import 'budget_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'spending_jars_screen.dart';
import 'statistics_screen.dart';
import 'transaction_list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Index tab đang chọn. 0 = Trang chủ
  int _selectedIndex = 0;

  // Danh sách màn hình theo đúng thứ tự bottom navigation
  late final List<Widget> _screens = [
    HomeScreen(onTabSelected: _changeTab), // 0: Trang chủ — truyền callback đổi tab
    const TransactionListScreen(),         // 1: Giao dịch
    const StatisticsScreen(),              // 2: Thống kê
    BudgetScreen(onOpenSpendingJars: () => _changeTab(4)), // 3: Ngân sách
    const SpendingJarsScreen(),            // 4: Hũ chi tiêu
    const ProfileScreen(),                 // 5: Hồ sơ
  ];

  // Title AppBar theo từng tab
  final List<String> _titles = const [
    'Trang chủ',
    'Giao dịch',
    'Thống kê',
    'Ngân sách',
    'Hũ chi tiêu',
    'Hồ sơ',
  ];

  // Đổi tab khi user bấm bottom nav hoặc khi Home gọi onTabSelected
  void _changeTab(int index) {
    setState(() => _selectedIndex = index);
  }

  // Mở màn Settings bằng push route (không phải tab)
  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]), // đổi title theo tab
        actions: [
          IconButton(
            tooltip: 'Cài đặt',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      // IndexedStack giữ state các tab, chỉ hiện tab đang chọn
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _changeTab,
            selectedIconTheme: const IconThemeData(size: 28),
            unselectedIconTheme: const IconThemeData(size: 25),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Trang chủ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_rounded),
                label: 'Giao dịch',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.pie_chart_rounded),
                label: 'Thống kê',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Ngân sách',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.savings_rounded),
                label: 'Hũ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Hồ sơ',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Bảng index tab

| Index | Tên tab | Màn hình |
|------:|---------|----------|
| 0 | Trang chủ | `HomeScreen` |
| 1 | Giao dịch | `TransactionListScreen` |
| 2 | Thống kê | `StatisticsScreen` |
| 3 | Ngân sách | `BudgetScreen` |
| 4 | Hũ | `SpendingJarsScreen` |
| 5 | Hồ sơ | `ProfileScreen` |

---

## 3. FULL CODE — `lib/screens/home_screen.dart` (file chính)

File này có **5 class**:

| Class | Công dụng |
|-------|-----------|
| `HomeScreen` | Màn hình Trang chủ |
| `_JarBudgetAlertCard` | Logic chọn loại cảnh báo hũ |
| `_AlertShell` | UI khung thẻ cảnh báo |
| `_OverviewCard` | Khối Tổng quan (thu/chi/ngân sách) |
| `_OverviewMetricBox` | 1 ô metric có thể bấm |
| `_MetricIcon` | Icon tròn nhỏ trong metric |

### 3.1. Import + class `HomeScreen` (dòng 1–164)

```dart
import 'package:flutter/material.dart';              // Widget Flutter cơ bản
import 'package:provider/provider.dart';              // context.watch / state management

import '../providers/spending_jar_provider.dart';      // Data hũ chi tiêu
import '../providers/transaction_provider.dart';      // Data thu/chi/số dư
import '../providers/user_provider.dart';             // User đang đăng nhập
import '../utils/app_constants.dart';                // AppColors
import '../utils/currency_formatter.dart';           // Format tiền VNĐ
import '../widgets/common_card.dart';                // Card bo góc dùng chung
import '../widgets/quick_action_card.dart';          // Nút tiện ích nhanh
import '../widgets/section_title.dart';              // Tiêu đề section

class HomeScreen extends StatelessWidget {
  // Callback do MainScreen truyền vào để đổi tab bottom nav
  // ValueChanged<int> = void Function(int)
  final ValueChanged<int> onTabSelected;

  const HomeScreen({super.key, required this.onTabSelected});

  // Hiện SnackBar cho tính năng chưa làm (nút "Xem thêm")
  void _showComingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title sẽ được tích hợp sau')));
  }

  @override
  Widget build(BuildContext context) {
    // watch = lắng nghe Provider; data đổi → rebuild UI
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser;                    // user hiện tại (có thể null)
    final finance = context.watch<TransactionProvider>();    // balance, totalIncome, totalExpense
    final jarProvider = context.watch<SpendingJarProvider>(); // jars, remainingInJars
    final remainingBudget = jarProvider.remainingInJars;     // tổng còn lại các hũ

    return SafeArea(
      top: false, // AppBar MainScreen đã lo phần top
      child: SingleChildScrollView(
        // Cuộn dọc nếu nội dung dài; padding lề trái/phải 16
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // căn trái
          children: [
            // ========== KHỐI 1: LỜI CHÀO ==========
            Text(
              // user?.displayName: lấy tên; ?? 'bạn' nếu null
              'Xin chào, ${user?.displayName ?? 'bạn'}',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6), // khoảng cách dọc 6px
            Text(
              'Hôm nay bạn muốn theo dõi gì?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant, // màu phụ
              ),
            ),
            const SizedBox(height: 18),

            // ========== KHỐI 2: CARD SỐ DƯ ==========
            Container(
              width: double.infinity, // full chiều ngang
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24), // bo góc lớn
                gradient: LinearGradient(
                  // Nền gradient hồng (style MoMo-like)
                  colors: [
                    AppColors.primary.withValues(alpha: 0.92),
                    AppColors.secondary.withValues(alpha: 0.84),
                    const Color(0xFFFFD6EA),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    blurRadius: 22,
                    offset: const Offset(0, 10), // bóng đổ xuống dưới
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hàng icon ví + nhãn
                  const Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Số dư hiện tại',
                        style: TextStyle(color: Colors.white70), // chữ mờ hơn
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Số tiền lớn: balance = income - expense
                  Text(
                    CurrencyFormatter.format(finance.balance),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900, // rất đậm
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // ========== KHỐI 3: TỔNG QUAN ==========
            _OverviewCard(
              totalIncome: finance.totalIncome,       // tổng thu
              totalExpense: finance.totalExpense,     // tổng chi
              remainingBudget: remainingBudget,       // ngân sách hũ còn lại
              onTabSelected: onTabSelected,           // để metric bấm đổi tab
            ),
            const SizedBox(height: 22),

            // ========== KHỐI 4: TIỆN ÍCH NHANH ==========
            const SectionTitle(title: 'Tiện ích nhanh'),
            CommonCard(
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
              child: GridView.count(
                crossAxisCount: 3,              // 3 cột
                shrinkWrap: true,               // co theo nội dung (nằm trong Column)
                physics: const NeverScrollableScrollPhysics(), // không cuộn riêng
                crossAxisSpacing: 16,           // khoảng cách ngang giữa ô
                mainAxisSpacing: 24,            // khoảng cách dọc giữa ô
                childAspectRatio: 0.8,          // tỉ lệ rộng/cao mỗi ô
                children: [
                  // Nút 1 → tab Giao dịch (index 1)
                  QuickActionCard(
                    icon: Icons.add_card_rounded,
                    title: 'Thêm giao dịch',
                    color: AppColors.primary,
                    onTap: () => onTabSelected(1),
                  ),
                  // Nút 2 → tab Thống kê (index 2)
                  QuickActionCard(
                    icon: Icons.pie_chart_rounded,
                    title: 'Xem thống kê',
                    color: AppColors.accent,
                    onTap: () => onTabSelected(2),
                  ),
                  // Nút 3 → tab Hũ (index 4)  [hiện đang shortcut tới Hũ]
                  QuickActionCard(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Ngân sách',
                    color: AppColors.warning,
                    onTap: () => onTabSelected(4),
                  ),
                  // Nút 4 → tab Hũ (index 4)
                  QuickActionCard(
                    icon: Icons.savings_rounded,
                    title: 'Hũ chi tiêu',
                    color: AppColors.income,
                    onTap: () => onTabSelected(4),
                  ),
                  // Nút 5 → tính năng chưa có → SnackBar
                  QuickActionCard(
                    icon: Icons.apps_rounded,
                    title: 'Xem thêm',
                    color: Colors.grey,
                    onTap: () => _showComingSoon(context, 'Tiện ích mở rộng'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // ========== KHỐI 5: CẢNH BÁO HŨ ==========
            _JarBudgetAlertCard(
              jarProvider: jarProvider,
              onOpenSpendingJars: () => onTabSelected(4), // bấm thẻ → tab Hũ
            ),
          ],
        ),
      ),
    );
  }
}
```

### Bảng 5 nút tiện ích

| # | Title | Icon | Màu | onTap | Kết quả |
|---|-------|------|-----|-------|---------|
| 1 | Thêm giao dịch | `add_card_rounded` | primary | `onTabSelected(1)` | → Giao dịch |
| 2 | Xem thống kê | `pie_chart_rounded` | accent | `onTabSelected(2)` | → Thống kê |
| 3 | Ngân sách | `account_balance_wallet_rounded` | warning | `onTabSelected(4)` | → Hũ |
| 4 | Hũ chi tiêu | `savings_rounded` | income | `onTabSelected(4)` | → Hũ |
| 5 | Xem thêm | `apps_rounded` | grey | `_showComingSoon` | SnackBar |

---

### 3.2. `_JarBudgetAlertCard` — logic 4 trạng thái cảnh báo

**Ưu tiên:** chưa có hũ → vượt mức → sắp hết (≤20%) → an toàn.

```dart
class _JarBudgetAlertCard extends StatelessWidget {
  final SpendingJarProvider jarProvider;
  final VoidCallback onOpenSpendingJars; // bấm action → mở tab Hũ

  const _JarBudgetAlertCard({
    required this.jarProvider,
    required this.onOpenSpendingJars,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jars = jarProvider.jars; // danh sách hũ tháng hiện tại

    // ----- TRẠNG THÁI 1: chưa có hũ nào -----
    if (jars.isEmpty) {
      return _AlertShell(
        icon: Icons.savings_rounded,
        iconColor: AppColors.primary,
        title: 'Thông báo hũ chi tiêu',
        message: 'Bạn chưa có hũ nào để theo dõi ngân sách.',
        suggestion:
            'Tạo hũ cho từng loại chi tiêu để app nhắc bạn khi sắp hết tiền.',
        actionText: 'Tạo hũ',
        onTap: onOpenSpendingJars,
      );
    }

    // ----- TRẠNG THÁI 2: có hũ đã chi VƯỢT mức (remaining < 0) -----
    final overJars = jars
        .where((jar) => jarProvider.getRemaining(jar) < 0)
        .toList();
    if (overJars.isNotEmpty) {
      // Sort: remaining nhỏ nhất (âm nhiều nhất) lên đầu → ưu tiên hũ vượt nặng
      overJars.sort(
        (a, b) =>
            jarProvider.getRemaining(a).compareTo(jarProvider.getRemaining(b)),
      );
      final jar = overJars.first;
      final overAmount = jarProvider.getRemaining(jar).abs(); // đổi âm → dương
      return _AlertShell(
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.expense, // đỏ/hồng cảnh báo
        title: 'Hũ ${jar.name} đã vượt mức',
        message: 'Bạn đã dùng vượt ${CurrencyFormatter.format(overAmount)}.',
        suggestion:
            'Nên giảm chi ở nhóm này hoặc điều chỉnh lại số tiền phân bổ cho hũ.',
        actionText: 'Kiểm tra hũ',
        onTap: onOpenSpendingJars,
      );
    }

    // ----- TRẠNG THÁI 3: hũ sắp hết (còn ≤ 20% số tiền phân bổ) -----
    final lowJars =
        jars.where((jar) {
          final remaining = jarProvider.getRemaining(jar);
          // amount > 0 tránh hũ 0đ; remaining <= 20% amount
          return jar.amount > 0 && remaining <= jar.amount * 0.2;
        }).toList()..sort(
          (a, b) => jarProvider
              .getRemaining(a)
              .compareTo(jarProvider.getRemaining(b)),
        );

    if (lowJars.isNotEmpty) {
      final jar = lowJars.first;
      final remaining = jarProvider.getRemaining(jar);
      return _AlertShell(
        icon: Icons.notifications_active_rounded,
        iconColor: AppColors.warning, // cam
        title: 'Hũ ${jar.name} sắp hết',
        message: 'Hũ này còn ${CurrencyFormatter.format(remaining)}.',
        suggestion:
            'Hãy ưu tiên khoản cần thiết và hạn chế phát sinh thêm trong nhóm này.',
        actionText: 'Xem chi tiết',
        onTap: onOpenSpendingJars,
      );
    }

    // ----- TRẠNG THÁI 4: tất cả hũ đang an toàn -----
    return _AlertShell(
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.income, // xanh
      title: 'Ngân sách đang ổn',
      message: 'Các hũ chi tiêu vẫn còn trong mức an toàn.',
      suggestion:
          'Tiếp tục ghi lại giao dịch đều đặn để giữ thói quen chi tiêu hợp lý.',
      actionText: 'Xem hũ',
      onTap: onOpenSpendingJars,
      titleStyle: theme.textTheme.titleMedium,
    );
  }
}
```

| Trạng thái | Điều kiện code | Icon / màu | Action |
|------------|----------------|------------|--------|
| 1. Chưa có hũ | `jars.isEmpty` | savings / primary | Tạo hũ |
| 2. Vượt mức | `getRemaining(jar) < 0` | warning_amber / expense | Kiểm tra hũ |
| 3. Sắp hết | `remaining <= amount * 0.2` | notifications / warning | Xem chi tiết |
| 4. An toàn | còn lại | check_circle / income | Xem hũ |

---

### 3.3. `_AlertShell` — UI khung thẻ cảnh báo

```dart
class _AlertShell extends StatelessWidget {
  final IconData icon;           // icon trạng thái
  final Color iconColor;         // màu icon + suggestion
  final String title;            // tiêu đề đậm
  final String message;          // mô tả tình trạng
  final String suggestion;       // gợi ý hành động
  final String actionText;       // chữ nút bên phải
  final VoidCallback onTap;      // bấm cả thẻ
  final TextStyle? titleStyle;   // style title tùy chọn

  const _AlertShell({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.suggestion,
    required this.actionText,
    required this.onTap,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap, // cả thẻ bấm được
      borderRadius: BorderRadius.circular(18),
      child: CommonCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon trong vòng tròn nền mờ
            CircleAvatar(
              backgroundColor: iconColor.withValues(alpha: 0.12),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            // Cột chữ giữa (title + message + suggestion)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        titleStyle?.copyWith(fontWeight: FontWeight.w800) ??
                        const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4, // giãn dòng
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    suggestion,
                    style: TextStyle(
                      color: iconColor, // màu theo trạng thái
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Cột action bên phải: text + chevron
            Column(
              children: [
                Text(
                  actionText,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

**Layout:**

```
┌─────────────────────────────────────────────────────┐
│ [Icon]  Title                                        │
│         Message                                      │  ActionText ›
│         Suggestion (màu theo trạng thái)             │
└─────────────────────────────────────────────────────┘
```

---

### 3.4. `_OverviewCard` — khối Tổng quan

```dart
class _OverviewCard extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final double remainingBudget;
  final ValueChanged<int> onTabSelected;

  const _OverviewCard({
    required this.totalIncome,
    required this.totalExpense,
    required this.remainingBudget,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark; // phân biệt dark/light

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.darkSurface,
                  AppColors.darkSurface.withValues(alpha: 0.88),
                ]
              : [Colors.white, const Color(0xFFFFF0F7)], // light: trắng → hồng nhạt
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : AppColors.primary.withValues(alpha: 0.08),
        ),
        boxShadow: isDark
            ? [] // dark: không shadow
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header "Tổng quan" — bấm → tab Thống kê (2)
          InkWell(
            onTap: () => onTabSelected(2),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Tổng quan',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Hàng 1: Tổng thu | Tổng chi
          Row(
            children: [
              Expanded(
                child: _OverviewMetricBox(
                  icon: Icons.trending_up_rounded,
                  title: 'Tổng thu',
                  amount: CurrencyFormatter.format(totalIncome),
                  amountColor: AppColors.income, // xanh
                  onTap: () => onTabSelected(1), // → Giao dịch
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OverviewMetricBox(
                  icon: Icons.trending_down_rounded,
                  title: 'Tổng chi',
                  amount: CurrencyFormatter.format(totalExpense),
                  amountColor: AppColors.expense, // hồng
                  onTap: () => onTabSelected(1), // → Giao dịch
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Hàng 2: Ngân sách còn lại (layout compact 1 hàng)
          _OverviewMetricBox(
            icon: Icons.savings_rounded,
            title: 'Ngân sách còn lại',
            amount: CurrencyFormatter.format(remainingBudget),
            amountColor: AppColors.warning, // cam
            compact: true,
            onTap: () => onTabSelected(4), // → Hũ
          ),
        ],
      ),
    );
  }
}
```

| Metric | Màu | onTap |
|--------|-----|-------|
| Tổng thu | `AppColors.income` | tab 1 Giao dịch |
| Tổng chi | `AppColors.expense` | tab 1 Giao dịch |
| Ngân sách còn lại | `AppColors.warning` | tab 4 Hũ |
| Header “Tổng quan” | — | tab 2 Thống kê |

---

### 3.5. `_OverviewMetricBox` + `_MetricIcon`

```dart
class _OverviewMetricBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String amount;          // đã format sẵn bằng CurrencyFormatter
  final Color amountColor;
  final bool compact;           // true = 1 hàng ngang (ngân sách)
  final VoidCallback? onTap;

  const _OverviewMetricBox({
    required this.icon,
    required this.title,
    required this.amount,
    required this.amountColor,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Nền ô theo màu metric, alpha nhạt
    final tileColor = isDark
        ? amountColor.withValues(alpha: 0.12)
        : amountColor.withValues(alpha: 0.07);
    final borderColor = amountColor.withValues(alpha: isDark ? 0.24 : 0.14);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: BoxConstraints(minHeight: compact ? 54 : 62),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          // compact=true: icon + title + amount cùng 1 Row
          // compact=false: title trên, amount dưới
          children: compact
              ? [
                  Row(
                    children: [
                      _MetricIcon(
                        icon: icon,
                        color: amountColor,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis, // cắt "..." nếu dài
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          // số tiền dài → thu nhỏ thay vì tràn
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            amount,
                            maxLines: 1,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: amountColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primary.withValues(alpha: 0.65),
                        size: 20,
                      ),
                    ],
                  ),
                ]
              : [
                  // Layout thường: icon + title
                  Row(
                    children: [
                      _MetricIcon(
                        icon: icon,
                        color: amountColor,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Hàng amount + chevron
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            amount,
                            maxLines: 1,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: amountColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primary.withValues(alpha: 0.65),
                        size: 20,
                      ),
                    ],
                  ),
                ],
        ),
      ),
    );
  }
}

// Icon tròn nhỏ bên cạnh title metric
class _MetricIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isDark;

  const _MetricIcon({
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 23,
      height: 23,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 14),
    );
  }
}
```

**2 layout metric:**

```
compact == false (Tổng thu / Tổng chi):
  [icon] Title
  Số tiền  ›

compact == true (Ngân sách còn lại):
  [icon] Title     Số tiền  ›
```

---

## 4. FULL CODE — Widget phụ

### 4.1. `lib/widgets/quick_action_card.dart`

```dart
import 'package:flutter/material.dart';

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;          // màu icon + viền; null → primary theme
  final VoidCallback onTap;    // hành vi khi bấm

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final actionColor = color ?? Theme.of(context).colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap, // bắt sự kiện chạm
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ô icon 60x60 bo góc + shadow
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: actionColor.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: actionColor.withValues(alpha: 0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Icon(icon, color: actionColor, size: 30),
          ),
          const SizedBox(height: 9),
          // Chữ dưới icon, tối đa 2 dòng
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1.18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 4.2. `lib/widgets/section_title.dart`

```dart
import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle; // optional

  const SectionTitle({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          // Chỉ hiện subtitle khi có truyền vào
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

### 4.3. `lib/widgets/common_card.dart`

```dart
import 'package:flutter/material.dart';

import '../utils/app_constants.dart';

class CommonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;

  const CommonCard({
    super.key,
    required this.child,
    this.margin,
    this.padding = const EdgeInsets.all(16), // mặc định padding 16
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: child,
    );
  }
}
```

---

## 5. FULL CODE — Utils

### 5.1. `lib/utils/currency_formatter.dart`

```dart
import 'package:intl/intl.dart';

class CurrencyFormatter {
  // 1500000 → "1.500.000 đ"
  static String format(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0, // không hiện phần thập phân
    );
    return formatter.format(amount);
  }

  // DateTime → "20/07/2026"
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'vi_VN').format(date);
  }

  // DateTime → "07/2026"
  static String formatMonth(DateTime date) {
    return DateFormat('MM/yyyy', 'vi_VN').format(date);
  }
}
```

### 5.2. `lib/utils/app_constants.dart` (phần màu dùng ở Home)

```dart
import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFFE91E8F);   // hồng chủ đạo
  static const secondary = Color(0xFFFF6FB5); // gradient số dư
  static const accent = Color(0xFFC21884);    // nút thống kê

  static const lightBackground = Color(0xFFFFF3F8);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightTextMain = Color(0xFF1F2937);
  static const lightTextSub = Color(0xFF6B7280);
  static const lightBorder = Color(0xFFF0E4EC);
  static const momoTint = Color(0xFFFFEAF4);

  static const income = Color(0xFF16A34A);    // tổng thu / an toàn
  static const expense = Color(0xFFE91E8F);   // tổng chi / vượt hũ
  static const warning = Color(0xFFFF9F1C);   // ngân sách / sắp hết
  static const teal = Color(0xFF14B8A6);

  static const darkBackground = Color(0xFF151018);
  static const darkSurface = Color(0xFF221727);
  static const darkPrimary = Color(0xFFF062A6);
  static const darkAccent = Color(0xFFCE6AFF);
  static const darkTextMain = Color(0xFFF9FAFB);
  static const darkTextSub = Color(0xFFB8A8BE);
  static const darkBorder = Color(0xFF3A263F);
}

class AppConstants {
  static const appName = 'Quản lý tài chính cá nhân';
  static const appVersion = '1.0.0';
  static const themeKey = 'isDarkMode';
}
```

---

## 6. FULL CODE — Provider / Repository (data trang chủ)

### 6.1. `TransactionProvider` — số dư / thu / chi

**File:** `lib/providers/transaction_provider.dart` (đoạn Home dùng)

```dart
class TransactionProvider with ChangeNotifier {
  final TransactionRepository _repository = TransactionRepository();

  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;

  // Home đọc 3 getter này
  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get balance => _balance;

  Future<void> fetchTransactions(int userId) async {
    _isLoading = true;
    notifyListeners();

    _calculateDateRange();

    try {
      _transactions = await _repository.getTransactions(
        userId,
        search: _searchQuery,
        type: _selectedType,
        categoryId: _selectedCategoryId,
        startDate: _startDate,
        endDate: _endDate,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      // Lấy summary từ SQLite → gán vào state
      final summary = await _repository.getFinancialSummary(
        userId,
        startDate: _startDate,
        endDate: _endDate,
      );
      _totalIncome = summary['income'] ?? 0;
      _totalExpense = summary['expense'] ?? 0;
      _balance = summary['balance'] ?? 0;
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // → Home rebuild nhờ context.watch
    }
  }
  // ... còn filter/search/sort ...
}
```

### 6.2. `getFinancialSummary` — tính trong DB

**File:** `lib/database/transaction_repository.dart`

```dart
Future<Map<String, double>> getFinancialSummary(
  int userId, {
  String? month,
  DateTime? startDate,
  DateTime? endDate,
}) async {
  final db = await _dbHelper.database;

  String whereClause = 'userId = ?';
  List<dynamic> whereArgs = [userId];

  if (month != null) {
    whereClause += " AND strftime('%Y-%m', date) = ?";
    whereArgs.add(month);
  }

  if (startDate != null) {
    whereClause += ' AND date >= ?';
    whereArgs.add(startDate.toIso8601String());
  }

  if (endDate != null) {
    whereClause += ' AND date <= ?';
    whereArgs.add(endDate.toIso8601String());
  }

  // SUM toàn bộ giao dịch income
  final List<Map<String, dynamic>> incomeResult = await db.rawQuery(
    'SELECT SUM(amount) as total FROM transactions WHERE $whereClause AND type = ?',
    [...whereArgs, 'income'],
  );

  // SUM toàn bộ giao dịch expense
  final List<Map<String, dynamic>> expenseResult = await db.rawQuery(
    'SELECT SUM(amount) as total FROM transactions WHERE $whereClause AND type = ?',
    [...whereArgs, 'expense'],
  );

  double totalIncome = incomeResult.first['total'] ?? 0.0;
  double totalExpense = expenseResult.first['total'] ?? 0.0;
  double balance = totalIncome - totalExpense; // CÔNG THỨC SỐ DƯ

  return {
    'income': totalIncome,
    'expense': totalExpense,
    'balance': balance,
  };
}
```

### 6.3. `SpendingJarProvider` — ngân sách hũ

**File:** `lib/providers/spending_jar_provider.dart` (đoạn Home dùng)

```dart
class SpendingJarProvider extends ChangeNotifier {
  List<SpendingJarModel> _jars = [];
  final Map<int, double> _spentByJar = {}; // jarId → số đã chi

  List<SpendingJarModel> get jars => _jars;

  // Tổng tiền đã phân bổ vào tất cả hũ
  double get allocatedBudget {
    return _jars.fold<double>(0, (sum, jar) => sum + jar.amount);
  }

  // Tổng đã chi trên mọi hũ
  double get totalSpentInJars {
    return _spentByJar.values.fold<double>(0, (sum, spent) => sum + spent);
  }

  // Home dùng: "Ngân sách còn lại"
  double get remainingInJars => allocatedBudget - totalSpentInJars;

  // Đã chi của 1 hũ
  double getSpent(SpendingJarModel jar) {
    final id = jar.id;
    if (id == null) return 0;
    return _spentByJar[id] ?? 0;
  }

  // Còn lại của 1 hũ (dùng cho logic cảnh báo)
  // remaining < 0  → vượt mức
  // remaining <= amount * 0.2 → sắp hết
  double getRemaining(SpendingJarModel jar) {
    return jar.amount - getSpent(jar);
  }
}
```

### 6.4. `UserProvider` — tên chào

**File:** `lib/providers/user_provider.dart` (đoạn Home dùng)

```dart
class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;

  // Home: user?.displayName ?? 'bạn'
  UserModel? get currentUser => _currentUser;
  // ...
}
```

---

## 7. Luồng dữ liệu (tóm tắt)

```
SQLite (transactions, spending_jars)
        │
        ▼
Repository (TransactionRepository / SpendingJarRepository)
        │
        ▼
Provider (TransactionProvider / SpendingJarProvider / UserProvider)
        │  context.watch<>()  →  UI rebuild khi data đổi
        ▼
HomeScreen
  ├── Xin chào: user.displayName
  ├── Số dư: finance.balance = income - expense
  ├── Tổng thu / Tổng chi: finance.totalIncome / totalExpense
  ├── Ngân sách còn lại: jarProvider.remainingInJars
  └── Cảnh báo hũ: jarProvider.jars + getRemaining(jar)
```

| Hiển thị UI | Công thức |
|-------------|-----------|
| **Số dư hiện tại** | `balance = totalIncome - totalExpense` |
| **Tổng thu** | `SUM(amount)` type = `income` |
| **Tổng chi** | `SUM(amount)` type = `expense` |
| **Ngân sách còn lại** | `allocatedBudget - totalSpentInJars` |
| **getRemaining(jar)** | `jar.amount - đã chi hũ đó` |

---

## 8. Bố cục UI tổng thể

```
┌──────────────────────────────────────┐
│ AppBar: "Trang chủ"          [⚙️]   │  ← MainScreen
├──────────────────────────────────────┤
│ Xin chào, <tên>                      │  ← Lời chào
│ Hôm nay bạn muốn theo dõi gì?        │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ 👛 Số dư hiện tại                │ │  ← Card gradient
│ │ 1.234.567 đ                      │ │
│ └──────────────────────────────────┘ │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ Tổng quan                     ›  │ │  ← _OverviewCard
│ │ [↑ Tổng thu]  [↓ Tổng chi]       │ │
│ │ [💰 Ngân sách còn lại]        ›  │ │
│ └──────────────────────────────────┘ │
│                                      │
│ Tiện ích nhanh                       │  ← SectionTitle
│ ┌──────────────────────────────────┐ │
│ │ [+]    [📊]    [👛]              │ │  ← Grid 3 cột
│ │ Thêm   Thống   Ngân              │ │
│ │ [🏦]   [⋮]                       │ │
│ │ Hũ     Xem thêm                  │ │
│ └──────────────────────────────────┘ │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ ⚠ Cảnh báo hũ…                › │ │  ← _JarBudgetAlertCard
│ └──────────────────────────────────┘ │
├──────────────────────────────────────┤
│ 🏠  🧾  📊  👛  🏦  👤               │  ← BottomNavigationBar
└──────────────────────────────────────┘
```

---

## 9. Bảng “Bấm vào đâu → đi đâu”

| Vùng bấm | Code | Đến |
|----------|------|-----|
| Header “Tổng quan” › | `onTabSelected(2)` | Thống kê |
| Ô Tổng thu | `onTabSelected(1)` | Giao dịch |
| Ô Tổng chi | `onTabSelected(1)` | Giao dịch |
| Ô Ngân sách còn lại | `onTabSelected(4)` | Hũ chi tiêu |
| Tiện ích: Thêm giao dịch | `onTabSelected(1)` | Giao dịch |
| Tiện ích: Xem thống kê | `onTabSelected(2)` | Thống kê |
| Tiện ích: Ngân sách | `onTabSelected(4)` | Hũ chi tiêu |
| Tiện ích: Hũ chi tiêu | `onTabSelected(4)` | Hũ chi tiêu |
| Tiện ích: Xem thêm | `_showComingSoon` | SnackBar |
| Thẻ cảnh báo hũ | `onTabSelected(4)` | Hũ chi tiêu |
| Icon ⚙️ AppBar | `_openSettings` | SettingsScreen |

---

## 10. Gợi ý kịch bản thuyết trình (1–2 phút)

1. **Trang chủ = dashboard** — tổng hợp số liệu + shortcut.
2. **Lời chào** — `UserProvider.currentUser.displayName`.
3. **Số dư** — `income - expense` từ SQLite qua `TransactionProvider`.
4. **Tổng quan** — 3 metric; bấm để nhảy tab (`onTabSelected`).
5. **Tiện ích nhanh** — Grid + `QuickActionCard`.
6. **Cảnh báo hũ** — 4 mức ưu tiên (empty / over / low ≤20% / ok).
7. **State** — `context.watch` + Provider → UI tự cập nhật.

> “Trang chủ là `StatelessWidget`, không tự giữ state. Mọi số liệu đến từ 3 Provider.  
> Điều hướng nội bộ dùng callback `onTabSelected` từ `MainScreen`.  
> Cảnh báo ngân sách tính real-time từ `getRemaining` từng hũ.”

---

## 11. Checklist file cần mở khi chấm / demo

- [ ] `lib/screens/home_screen.dart` — UI + logic cảnh báo (**full code ở mục 3**)
- [ ] `lib/screens/main_screen.dart` — tab + callback (**full code ở mục 2**)
- [ ] `lib/providers/transaction_provider.dart` — balance/income/expense
- [ ] `lib/providers/spending_jar_provider.dart` — remainingInJars / getRemaining
- [ ] `lib/database/transaction_repository.dart` — getFinancialSummary
- [ ] `lib/widgets/quick_action_card.dart`
- [ ] `lib/widgets/common_card.dart`
- [ ] `lib/widgets/section_title.dart`
- [ ] `lib/utils/currency_formatter.dart`
- [ ] `lib/utils/app_constants.dart`

---

*File đã nhúng full source code chính + comment công dụng để đọc trực tiếp khi ôn thuyết trình.*
