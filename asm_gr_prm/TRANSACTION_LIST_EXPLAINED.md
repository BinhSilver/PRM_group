# Giải thích chi tiết Màn Giao dịch (Transaction List) + FULL CODE

Tài liệu phục vụ **thuyết trình / demo** phần:

- Hiển thị danh sách giao dịch (nhóm theo tháng)
- Tìm kiếm theo tên / ghi chú
- Lọc theo thời gian + Thu/Chi (FilterBottomSheet)
- Sắp xếp (mới/cũ, số tiền tăng/giảm)
- Thêm / Sửa / Xóa giao dịch

Có **full source code** + giải thích công dụng từng khối.

---

## 1. Bản đồ file liên quan

| Vai trò | Đường dẫn | Mô tả ngắn |
|--------|-----------|------------|
| **Màn hình Giao dịch** | `lib/screens/transaction_list_screen.dart` | UI chính: summary, search, filter, sort, list theo tháng |
| **State + logic filter** | `lib/providers/transaction_provider.dart` | search / type / time / sort; gọi repository |
| **Query SQLite** | `lib/database/transaction_repository.dart` | `getTransactions`, `getFinancialSummary` |
| **Bottom sheet lọc** | `lib/widgets/filter_bottom_sheet.dart` | Lọc thời gian + Thu/Chi, nút Áp dụng |
| **Dropdown sắp xếp** | `lib/widgets/sort_dropdown_widget.dart` | 4 option sort |
| **Card 1 giao dịch** | `lib/widgets/transaction_card.dart` | Tap sửa, long-press xóa |
| **Enum thời gian** | `lib/widgets/time_filter_widget.dart` | `TimeFilterType` |
| **Skeleton / Empty** | `lib/widgets/skeleton_loading.dart`, `empty_state_widget.dart` | Loading / không có data |
| **Thêm/Sửa form** | `lib/screens/add_transaction_screen.dart` | Màn form giao dịch |
| **Tab gắn màn hình** | `lib/screens/main_screen.dart` | Tab index `1` = `TransactionListScreen` |

---

## 2. Màn hình nằm ở đâu trong app?

**File:** `lib/screens/main_screen.dart`

```dart
late final List<Widget> _screens = [
  HomeScreen(...),                 // 0 Trang chủ
  const TransactionListScreen(),   // 1 Giao dịch  ← đây
  const StatisticsScreen(),        // 2 Thống kê
  BudgetScreen(...),               // 3 Ngân sách
  const SpendingJarsScreen(),      // 4 Hũ
  const ProfileScreen(),           // 5 Hồ sơ
];
```

---

## 3. Luồng dữ liệu (Data flow)

```
UI (TransactionListScreen)
   │  gõ search / mở filter / đổi sort / pull-to-refresh
   ▼
TransactionProvider
   │  setSearchQuery / setFilters / setSort / fetchTransactions
   │  _calculateDateRange()  →  _startDate, _endDate
   ▼
TransactionRepository
   │  getTransactions(... WHERE + ORDER BY)
   │  getFinancialSummary(userId)  ← tổng KHÔNG theo filter
   ▼
SQLite (bảng transactions)
   │
   ▼
notifyListeners()  →  Consumer rebuild UI
```

### Điểm quan trọng khi thuyết trình

| Vùng UI | Data có filter không? |
|---------|------------------------|
| **Danh sách** | Có: search + type + time + sort |
| **Tổng quan (số dư / thu / chi)** | **Không** — luôn là tổng toàn bộ user (giống bản test) |

---

## 4. Bố cục UI (top → bottom)

```
┌──────────────────────────────────────────┐
│ AppBar: "Giao dịch"                      │  ← MainScreen
├──────────────────────────────────────────┤
│ ┌──────────────────────────────────────┐ │
│ │ Tổng quan giao dịch                  │ │
│ │ 1.234.567 đ   (Số dư hiện tại)       │ │  ← Summary
│ │ [↑ Tổng thu]     [↓ Tổng chi]        │ │
│ └──────────────────────────────────────┘ │
│                                          │
│ Danh sách giao dịch                      │
│ [🔍 Tìm kiếm...]  [⚙]  [+]               │  ← Search + Filter + Add
│ ⇅ Mới nhất ▼                             │  ← Sort
│                                          │
│ Tháng 7/2026                             │  ← Group by month
│ ┌──────────────────────────────────────┐ │
│ │ 🧾 Ăn trưa     12:30 · 15/07  -50k  │ │  ← TransactionCard
│ │ 🧾 Lương       09:00 · 01/07  +10tr │ │
│ └──────────────────────────────────────┘ │
│                                          │
│ (kéo xuống = RefreshIndicator)           │
└──────────────────────────────────────────┘
```

### Tương tác user

| Hành động | Kết quả |
|-----------|---------|
| Gõ ô tìm kiếm | Debounce 300ms → filter `title` / `note` |
| Bấm icon ⚙ | Mở `FilterBottomSheet` (thời gian + Thu/Chi) |
| Bấm icon + | Mở `AddTransactionScreen` (thêm mới) |
| Đổi dropdown sort | `setSort` → query lại |
| Tap 1 item | Mở form **sửa** giao dịch |
| **Long-press** 1 item | Dialog xác nhận → **xóa** |
| Kéo xuống | Refresh list + load lại hũ |

---

## 5. FULL CODE — `transaction_list_screen.dart`

### 5.1. Import + class + helper

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../providers/budget_provider.dart';
import '../providers/spending_jar_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_constants.dart';
import '../utils/currency_formatter.dart';
import '../widgets/common_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/section_title.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/sort_dropdown_widget.dart';
import '../widgets/transaction_card.dart';
import 'add_transaction_screen.dart';

/// Màn danh sách giao dịch — logic/UI bám theo bản mẫu test/.
class TransactionListScreen extends StatelessWidget {
  const TransactionListScreen({super.key});

  // Lấy userId đang đăng nhập; 0 = chưa login / lỗi
  int _resolveUserId(BuildContext context) {
    return context.read<UserProvider>().currentUser?.id ?? 0;
  }
```

| Thành phần | Công dụng |
|------------|-----------|
| `StatelessWidget` | UI rebuild qua `Consumer` / Provider, không giữ `setState` local |
| `_resolveUserId` | Mọi API filter/fetch đều cần `userId` |

---

### 5.2. Mở form thêm / sửa

```dart
  Future<void> _openAddTransaction(
    BuildContext context, {
    TransactionModel? transaction, // null = thêm mới; có object = sửa
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(transaction: transaction),
      ),
    );
  }
```

| Tham số | Ý nghĩa |
|---------|---------|
| `transaction == null` | Thêm mới (nút +) |
| `transaction != null` | Sửa (tap vào card) |

---

### 5.3. Pull-to-refresh

```dart
  Future<void> _refresh(BuildContext context, int userId) async {
    if (userId == 0) return;
    await context.read<TransactionProvider>().fetchTransactions(userId);
    if (!context.mounted) return; // tránh dùng context sau async
    await context.read<SpendingJarProvider>().loadJars(userId);
  }
```

---

### 5.4. Xóa giao dịch (long-press)

```dart
  Future<void> _confirmAndDelete(
    BuildContext context,
    TransactionModel transaction,
  ) async {
    final userId = _resolveUserId(context);
    final id = transaction.id;
    if (userId == 0 || id == null) return;

    // 1) Hiện dialog xác nhận
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa giao dịch này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('HỦY')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('XÓA'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      // 2) Xóa DB + refresh list
      await context.read<TransactionProvider>().deleteTransaction(id, userId);
      if (!context.mounted) return;
      // 3) Đồng bộ ngân sách + hũ (chi tiêu có thể gắn hũ)
      await context.read<BudgetProvider>().loadBudgets(userId);
      if (!context.mounted) return;
      await context.read<SpendingJarProvider>().loadJars(userId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã xóa giao dịch')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e')));
    }
  }
```

---

### 5.5. `build()` — khung chính

```dart
  @override
  Widget build(BuildContext context) {
    final userId = _resolveUserId(context);

    return SafeArea(
      top: false, // AppBar MainScreen đã lo phần top
      child: Consumer<TransactionProvider>(
        // Consumer = lắng nghe Provider, rebuild khi notifyListeners()
        builder: (context, provider, child) {
          // Gom list theo tháng để hiện header "Tháng M/yyyy"
          final grouped = _groupTransactionsByMonth(provider.transactions);
          final monthKeys = grouped.keys.toList();

          return RefreshIndicator(
            onRefresh: () => _refresh(context, userId),
            child: CustomScrollView(
              // AlwaysScrollable: pull-to-refresh vẫn chạy khi list ngắn
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ----- HEADER: summary + search + sort -----
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummarySection(context, provider),
                        const SizedBox(height: 22),
                        const SectionTitle(title: 'Danh sách giao dịch'),
                        const SizedBox(height: 8),
                        _buildSearchAndActions(context, userId),
                        SortDropdownWidget(
                          currentSortBy: provider.sortBy,
                          currentSortOrder: provider.sortOrder,
                          onSortChanged: (sortBy, sortOrder) {
                            provider.setSort(userId, sortBy, sortOrder);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // ----- BODY: loading / empty / list -----
                if (provider.isLoading)
                  const SliverToBoxAdapter(child: SkeletonLoading())
                else if (provider.transactions.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: EmptyStateWidget(
                        message:
                            'Chưa có giao dịch nào.\nHãy thêm giao dịch đầu tiên.',
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final month = monthKeys[index];
                      final transactions = grouped[month]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMonthHeader(context, month),
                          CommonCard(
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: transactions.map((t) {
                                return TransactionCard(
                                  transaction: t,
                                  onTap: () => _openAddTransaction(
                                    context,
                                    transaction: t, // sửa
                                  ),
                                  onLongPress: () =>
                                      _confirmAndDelete(context, t), // xóa
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      );
                    }, childCount: monthKeys.length),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }
```

| Widget | Công dụng |
|--------|-----------|
| `Consumer<TransactionProvider>` | Rebuild khi data/filter đổi |
| `CustomScrollView` + **slivers** | Header cố định cấu trúc + list dài hiệu quả |
| `SliverToBoxAdapter` | Nhét widget thường vào scroll sliver |
| `SliverList` | List các **nhóm tháng** |
| `SliverFillRemaining` | Empty state căn giữa khi không có data |
| `SkeletonLoading` | Placeholder shimmer khi `isLoading` |

---

### 5.6. Khối Tổng quan

```dart
  Widget _buildSummarySection(
    BuildContext context,
    TransactionProvider provider,
  ) {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tổng quan giao dịch', ...),
          // Số dư lớn (income - expense) — TỔNG, không theo filter list
          Text(CurrencyFormatter.format(provider.balance), ...),
          Text('Số dư hiện tại', ...),
          Row(
            children: [
              Expanded(child: _SummaryTile(
                title: 'Tổng thu',
                amount: provider.totalIncome,
                color: AppColors.income,
                icon: Icons.trending_up_rounded,
              )),
              Expanded(child: _SummaryTile(
                title: 'Tổng chi',
                amount: provider.totalExpense,
                color: AppColors.expense,
                icon: Icons.trending_down_rounded,
              )),
            ],
          ),
        ],
      ),
    );
  }
```

`_SummaryTile` = ô nhỏ có icon + title + số tiền (màu xanh thu / hồng chi).

---

### 5.7. Search + nút Filter + nút Add

```dart
  Widget _buildSearchAndActions(BuildContext context, int userId) {
    return Row(
      children: [
        // Ô tìm kiếm
        Expanded(
          child: Container(
            height: 44,
            // ... decoration bo góc
            child: Row(
              children: [
                Icon(Icons.search_rounded, ...),
                Expanded(
                  child: TextField(
                    onChanged: (query) => context
                        .read<TransactionProvider>()
                        .setSearchQuery(userId, query), // debounce trong provider
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm giao dịch',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Nút mở FilterBottomSheet
        _buildCircleAction(
          icon: Icons.tune_rounded,
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => FilterBottomSheet(userId: userId),
            );
          },
        ),
        // Nút thêm giao dịch
        _buildCircleAction(
          icon: Icons.add_rounded,
          onTap: () => _openAddTransaction(context),
          filled: true, // nền primary hồng
        ),
      ],
    );
  }
```

| Nút | Icon | Hành vi |
|-----|------|---------|
| Lọc | `tune_rounded` | Bottom sheet: thời gian + Thu/Chi |
| Thêm | `add_rounded` (filled) | Push `AddTransactionScreen` |

`_buildCircleAction` = nút tròn 40×40, `filled: true` thì nền primary + icon trắng.

---

### 5.8. Gom theo tháng

```dart
  Map<String, List<TransactionModel>> _groupTransactionsByMonth(
    List<TransactionModel> transactions,
  ) {
    final grouped = <String, List<TransactionModel>>{};
    for (final t in transactions) {
      final month = DateFormat('M/yyyy').format(t.date); // ví dụ "7/2026"
      grouped.putIfAbsent(month, () => []).add(t);
    }
    return grouped;
  }
```

| Bước | Ý nghĩa |
|------|---------|
| `DateFormat('M/yyyy')` | Key nhóm theo tháng/năm |
| `putIfAbsent` | Tạo list rỗng nếu tháng chưa có, rồi `add` |
| Header UI | `Tháng $month` → `Tháng 7/2026` |

> Thứ tự tháng trên UI = thứ tự xuất hiện trong list đã sort từ DB (thường DESC theo date → tháng mới hiện trước).

---

## 6. FULL CODE — `TransactionProvider`

**File:** `lib/providers/transaction_provider.dart`

### 6.1. State

```dart
class TransactionProvider with ChangeNotifier {
  final TransactionRepository _repository = TransactionRepository();

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _searchQuery;           // từ khóa search
  String? _selectedType;          // null | 'income' | 'expense'
  int? _selectedCategoryId;
  DateTime? _startDate;           // sinh từ time filter
  DateTime? _endDate;
  String _sortBy = 'date';         // 'date' | 'amount'
  String _sortOrder = 'DESC';      // 'ASC' | 'DESC'
  TimeFilterType _timeFilterType = TimeFilterType.all;

  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;

  // Getters public cho UI
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get balance => _balance;
  String? get selectedType => _selectedType;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;
  TimeFilterType get timeFilterType => _timeFilterType;
  String? get searchQuery => _searchQuery;

  Timer? _searchDebounce; // debounce gõ phím
```

---

### 6.2. `fetchTransactions` — hàm trung tâm

```dart
  Future<void> fetchTransactions(int userId) async {
    _isLoading = true;
    notifyListeners(); // → hiện SkeletonLoading

    _calculateDateRange(); // time filter → _startDate/_endDate

    try {
      // LIST: có filter
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

      // SUMMARY: không filter (tổng toàn bộ)
      final summary = await _repository.getFinancialSummary(userId);
      _totalIncome = summary['income'] ?? 0;
      _totalExpense = summary['expense'] ?? 0;
      _balance = summary['balance'] ?? 0;
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // → rebuild list
    }
  }
```

---

### 6.3. `_calculateDateRange` — map enum → khoảng ngày

| `TimeFilterType` | startDate | endDate |
|------------------|-----------|---------|
| `all` | null | null |
| `today` | 00:00 hôm nay | 23:59 hôm nay |
| `week` | Thứ 2 tuần này | CN tuần này |
| `month` | Ngày 1 tháng này | Cuối tháng |
| `year` | 01/01 năm nay | 31/12 năm nay |
| `yesterday` / `lastMonth` / `custom` | (hỗ trợ thêm, UI sheet chính dùng 5 loại trên) |

```dart
  void _calculateDateRange() {
    final now = DateTime.now();
    switch (_timeFilterType) {
      case TimeFilterType.all:
        _startDate = null;
        _endDate = null;
        break;
      case TimeFilterType.today:
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      // ... week, month, year, yesterday, lastMonth, custom
    }
  }
```

---

### 6.4. Các API filter / sort / CRUD

```dart
  // Áp dụng cả type + time (từ FilterBottomSheet)
  void setFilters({
    required int userId,
    String? type,
    required TimeFilterType timeType,
  }) {
    _selectedType = type;
    _timeFilterType = timeType;
    fetchTransactions(userId);
  }

  // Chỉ đổi time (giữ type)
  void setTimeFilter(int userId, TimeFilterType timeType) {
    _timeFilterType = timeType;
    fetchTransactions(userId);
  }

  // Search có debounce 300ms — tránh query DB mỗi phím
  void setSearchQuery(int userId, String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      final trimmed = query.trim();
      _searchQuery = trimmed.isEmpty ? null : trimmed;
      fetchTransactions(userId);
    });
  }

  void setSort(int userId, String sortBy, String sortOrder) {
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    fetchTransactions(userId);
  }

  Future<void> addTransaction(TransactionModel t) async {
    await _repository.insertTransaction(t);
    await fetchTransactions(t.userId);
  }

  Future<void> updateTransaction(TransactionModel t) async {
    await _repository.updateTransaction(t);
    await fetchTransactions(t.userId);
  }

  Future<void> deleteTransaction(int id, int userId) async {
    await _repository.deleteTransaction(id);
    await fetchTransactions(userId);
  }
```

| Method | Dùng khi |
|--------|----------|
| `setFilters` | Bấm **Áp dụng** trong bottom sheet |
| `setSearchQuery` | Gõ ô tìm kiếm |
| `setSort` | Đổi dropdown sort |
| `add/update/delete` | CRUD form / long-press xóa |

---

## 7. FULL CODE — Repository (query DB)

**File:** `lib/database/transaction_repository.dart`

### 7.1. `getTransactions` — WHERE động + ORDER BY

```dart
  Future<List<TransactionModel>> getTransactions(
    int userId, {
    String? search,
    String? type,
    int? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy = 'date',
    String? sortOrder = 'DESC',
  }) async {
    final db = await _dbHelper.database;

    String whereClause = 'userId = ?';
    List<dynamic> whereArgs = [userId];

    // Tìm theo title HOẶC note
    if (search != null && search.isNotEmpty) {
      whereClause += ' AND (title LIKE ? OR note LIKE ?)';
      whereArgs.add('%$search%');
      whereArgs.add('%$search%');
    }

    // Lọc Thu / Chi
    if (type != null) {
      whereClause += ' AND type = ?';
      whereArgs.add(type);
    }

    if (categoryId != null) {
      whereClause += ' AND categoryId = ?';
      whereArgs.add(categoryId);
    }

    // Lọc thời gian
    if (startDate != null) {
      whereClause += ' AND date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClause += ' AND date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final maps = await db.query(
      'transactions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: '$sortBy $sortOrder', // ví dụ: "date DESC"
    );

    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }
```

### 7.2. `getFinancialSummary` — SUM thu / chi

```dart
  // income = SUM type='income'
  // expense = SUM type='expense'
  // balance = income - expense
  Future<Map<String, double>> getFinancialSummary(int userId, {...}) async {
    // ...
    return {
      'income': totalIncome,
      'expense': totalExpense,
      'balance': balance,
    };
  }
```

Màn list gọi **không** truyền `startDate`/`endDate` → summary = toàn bộ lịch sử user.

---

## 8. FULL CODE — `FilterBottomSheet`

**File:** `lib/widgets/filter_bottom_sheet.dart`

### Ý tưởng

- State **tạm** `_tempType`, `_tempTimeType` (chưa ghi Provider khi chỉ chọn chip)
- **Xóa bộ lọc** → reset temp về Tất cả
- **Áp dụng** → `provider.setFilters(...)` rồi `Navigator.pop`

```dart
class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String? _tempType;
  late TimeFilterType _tempTimeType;

  @override
  void initState() {
    super.initState();
    final provider = context.read<TransactionProvider>();
    _tempType = provider.selectedType;       // load filter hiện tại
    _tempTimeType = provider.timeFilterType;
  }

  // UI:
  //  - Theo thời gian: Tất cả | Hôm nay | Tuần này | Tháng này | Năm nay
  //  - Theo loại: Tất cả | Thu nhập | Chi tiêu
  //  - [Xóa bộ lọc]  [Áp dụng]

  // Áp dụng:
  context.read<TransactionProvider>().setFilters(
    userId: widget.userId,
    type: _tempType,           // null | 'income' | 'expense'
    timeType: _tempTimeType,
  );
  Navigator.pop(context);
}
```

| Nút thời gian | Enum |
|---------------|------|
| Tất cả | `TimeFilterType.all` |
| Hôm nay | `today` |
| Tuần này | `week` |
| Tháng này | `month` |
| Năm nay | `year` |

| Nút loại | Giá trị |
|----------|---------|
| Tất cả | `null` |
| Thu nhập | `'income'` |
| Chi tiêu | `'expense'` |

---

## 9. FULL CODE — `SortDropdownWidget`

**File:** `lib/widgets/sort_dropdown_widget.dart`

```dart
final List<SortOption> options = [
  SortOption('Mới nhất', 'date', 'DESC'),
  SortOption('Cũ nhất', 'date', 'ASC'),
  SortOption('Số tiền tăng dần', 'amount', 'ASC'),
  SortOption('Số tiền giảm dần', 'amount', 'DESC'),
];
```

| Label | sortBy | sortOrder | SQL orderBy |
|-------|--------|-----------|-------------|
| Mới nhất | date | DESC | `date DESC` |
| Cũ nhất | date | ASC | `date ASC` |
| Số tiền tăng dần | amount | ASC | `amount ASC` |
| Số tiền giảm dần | amount | DESC | `amount DESC` |

Khi đổi: `onSortChanged(sortBy, sortOrder)` → `provider.setSort(...)`.

---

## 10. FULL CODE — `TransactionCard`

**File:** `lib/widgets/transaction_card.dart`

```dart
class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onTap;          // sửa
  final VoidCallback? onLongPress;   // xóa (optional)

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final color = isIncome ? AppColors.income : AppColors.expense;
    final prefix = isIncome ? '+' : '-';
    // ...
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Row(
        children: [
          // Icon tròn
          // Title + "HH:mm · dd/MM"
          // Số tiền màu xanh/hồng: +1.000.000 đ / -50.000 đ
        ],
      ),
    );
  }
}
```

| Phần UI | Nguồn |
|---------|--------|
| Title | `transaction.title` |
| Thời gian | `DateFormat('HH:mm')` + `dd/MM` |
| Màu / dấu | `type == 'income'` → xanh `+` ; else hồng `-` |
| Số tiền | `CurrencyFormatter.format(amount)` |

---

## 11. Sơ đồ luồng filter (1 hình)

```
[User gõ search]
      │ 300ms debounce
      ▼
setSearchQuery → _searchQuery
      │
[User mở ⚙ → chọn Thu + Tháng này → Áp dụng]
      │
setFilters(type: 'income', timeType: month)
      │
_calculateDateRange() → start/end tháng
      │
getTransactions(search, type, start, end, sort)
      │
List mới → group by month → SliverList
```

---

## 12. Kịch bản thuyết trình (1–2 phút)

1. **Vào tab Giao dịch** — summary số dư / thu / chi (tổng).  
2. **Danh sách nhóm tháng** — dễ đọc theo thời gian.  
3. **Tìm kiếm** — gõ tên → debounce → filter SQL `LIKE`.  
4. **Nút ⚙** — bottom sheet: lọc thời gian + Thu/Chi → Áp dụng.  
5. **Dropdown sort** — mới nhất / số tiền.  
6. **Nút +** — thêm; **tap** — sửa; **long-press** — xóa + đồng bộ budget/hũ.  
7. **Kiến trúc** — UI → Provider → Repository → SQLite; list filter, summary không filter.

### Câu kỹ thuật ngắn

> “Danh sách dùng `Consumer` + `CustomScrollView` slivers.  
> Filter/search/sort nằm ở `TransactionProvider`, query động trong repository.  
> Debounce 300ms cho search. Bottom sheet dùng state tạm, chỉ commit khi Áp dụng.  
> Summary lấy tổng toàn bộ; list mới áp dụng filter.”

---

## 13. Checklist file khi chấm / demo

- [ ] `lib/screens/transaction_list_screen.dart`
- [ ] `lib/providers/transaction_provider.dart`
- [ ] `lib/database/transaction_repository.dart`
- [ ] `lib/widgets/filter_bottom_sheet.dart`
- [ ] `lib/widgets/sort_dropdown_widget.dart`
- [ ] `lib/widgets/transaction_card.dart`
- [ ] `lib/widgets/time_filter_widget.dart` (`TimeFilterType`)
- [ ] `lib/screens/add_transaction_screen.dart` (form thêm/sửa)

---

## 14. So với bản mẫu `test/`

| Tính năng | test/ | App hiện tại |
|-----------|-------|--------------|
| Summary + search + filter sheet + sort | Có | Có |
| Group theo tháng | Có | Có |
| TransactionCard | Có | Có |
| Thêm / Sửa | Coming soon | **Có** (`AddTransactionScreen`) |
| Xóa | Không | **Có** (long-press + dialog) |
| Đồng bộ hũ/budget sau xóa | Không | **Có** |

---

*File phản ánh source hiện tại trong `asm_gr_prm`. Nếu đổi filter/summary, cập nhật mục 3, 5, 6.*
