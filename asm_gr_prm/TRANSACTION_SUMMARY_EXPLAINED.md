# Giải thích chi tiết: Khối **Tổng quan giao dịch**

Đây là **phần đầu tiên** trên tab **Giao dịch**.  
Hiển thị 3 số liệu chính: **Số dư hiện tại**, **Tổng thu**, **Tổng chi**.

---

## 1. Nhìn trên màn hình thấy gì?

```
┌─────────────────────────────────────────┐
│ Tổng quan giao dịch                     │  ← tiêu đề
│                                         │
│  12.500.000 đ                           │  ← số dư (to, màu primary)
│  Số dư hiện tại                         │  ← nhãn phụ
│                                         │
│  ┌──────────────┐  ┌──────────────┐     │
│  │ ↑ Tổng thu   │  │ ↓ Tổng chi   │     │
│  │ 20.000.000 đ │  │ 7.500.000 đ  │     │
│  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────┘
```

| Thành phần | Ý nghĩa nghiệp vụ | Màu |
|------------|-------------------|-----|
| **Số dư hiện tại** | Tiền còn lại = Tổng thu − Tổng chi | Hồng primary, chữ rất đậm |
| **Tổng thu** | Cộng tất cả giao dịch `type = income` | Xanh `AppColors.income` |
| **Tổng chi** | Cộng tất cả giao dịch `type = expense` | Hồng `AppColors.expense` |

### Ví dụ số liệu

| Giao dịch | Type | Amount |
|-----------|------|--------|
| Lương | income | 15.000.000 |
| Thưởng | income | 5.000.000 |
| Ăn uống | expense | 3.000.000 |
| Đi lại | expense | 4.500.000 |

→ **Tổng thu** = 20.000.000  
→ **Tổng chi** = 7.500.000  
→ **Số dư** = 20.000.000 − 7.500.000 = **12.500.000**

---

## 2. Code nằm ở đâu?

| Lớp | File | Vai trò |
|-----|------|---------|
| **UI** | `lib/screens/transaction_list_screen.dart` | Vẽ card + gọi số liệu từ provider |
| **State** | `lib/providers/transaction_provider.dart` | Giữ `balance`, `totalIncome`, `totalExpense` |
| **DB** | `lib/database/transaction_repository.dart` | SQL `SUM(amount)` theo type |
| **Format** | `lib/utils/currency_formatter.dart` | `12500000` → `12.500.000 đ` |
| **Màu** | `lib/utils/app_constants.dart` | `AppColors.primary / income / expense` |
| **Card nền** | `lib/widgets/common_card.dart` | Bo góc, viền, shadow |

---

## 3. UI được gọi từ đâu?

Trong `build()` của `TransactionListScreen`:

```dart
// file: lib/screens/transaction_list_screen.dart
child: Consumer<TransactionProvider>(
  builder: (context, provider, child) {
    // ...
    return RefreshIndicator(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  // ★ KHỐI TỔNG QUAN — nằm đầu màn hình
                  _buildSummarySection(context, provider),
                  const SizedBox(height: 22),
                  // ... search, sort, list bên dưới
                ],
              ),
            ),
          ),
          // ...
        ],
      ),
    );
  },
);
```

| Dòng / ý | Công dụng |
|----------|-----------|
| `Consumer<TransactionProvider>` | Khi provider `notifyListeners()`, khối tổng quan **tự rebuild** với số mới |
| `provider` | Object chứa `balance`, `totalIncome`, `totalExpense` |
| `_buildSummarySection(...)` | Hàm private vẽ toàn bộ card tổng quan |
| Đặt **đầu** Column | User mở tab Giao dịch là thấy ngay tài chính tổng |

---

## 4. Full code UI — `_buildSummarySection`

```dart
Widget _buildSummarySection(
  BuildContext context,
  TransactionProvider provider,
) {
  return CommonCard(
    // Card bo góc dùng chung (nền + viền + shadow)
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, // căn trái nội dung
      children: [
        // ── (1) Tiêu đề section ──────────────────────────
        Text(
          'Tổng quan giao dịch',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700, // đậm
          ),
        ),
        const SizedBox(height: 14), // khoảng cách dọc

        // ── (2) Số dư lớn ────────────────────────────────
        Text(
          CurrencyFormatter.format(provider.balance),
          // ví dụ: 12500000.0 → "12.500.000 đ"
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.primary,   // hồng chủ đạo
            fontWeight: FontWeight.w900, // rất đậm, nổi bật nhất
          ),
        ),

        // ── (3) Nhãn phụ dưới số dư ──────────────────────
        Text(
          'Số dư hiện tại',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            // màu phụ, mờ hơn số tiền
          ),
        ),
        const SizedBox(height: 16),

        // ── (4) Hàng 2 ô: Tổng thu | Tổng chi ────────────
        Row(
          children: [
            Expanded(
              // Expanded = mỗi ô chiếm ½ chiều ngang
              child: _SummaryTile(
                title: 'Tổng thu',
                amount: provider.totalIncome,
                color: AppColors.income,              // xanh
                icon: Icons.trending_up_rounded,      // mũi tên lên
              ),
            ),
            const SizedBox(width: 10), // khe giữa 2 ô
            Expanded(
              child: _SummaryTile(
                title: 'Tổng chi',
                amount: provider.totalExpense,
                color: AppColors.expense,             // hồng
                icon: Icons.trending_down_rounded,    // mũi tên xuống
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
```

### Giải thích từng phần UI

#### (1) Tiêu đề `"Tổng quan giao dịch"`

| Code | Ý nghĩa |
|------|---------|
| `Text('Tổng quan giao dịch')` | Label cố định |
| `titleLarge` | Cỡ chữ tiêu đề section |
| `fontWeight.w700` | Chữ đậm vừa |

#### (2) Số dư `provider.balance`

| Code | Ý nghĩa |
|------|---------|
| `provider.balance` | Getter từ `TransactionProvider` |
| `CurrencyFormatter.format(...)` | Format kiểu Việt Nam, ký hiệu `đ`, không thập phân |
| `headlineMedium` | Chữ **lớn hơn** title — điểm nhấn |
| `AppColors.primary` | Màu hồng app |
| `FontWeight.w900` | Đậm nhất trong card |

#### (3) Nhãn `"Số dư hiện tại"`

| Code | Ý nghĩa |
|------|---------|
| `bodySmall` | Chữ nhỏ |
| `onSurfaceVariant` | Màu secondary của theme (xám/tím nhạt) |

→ User đọc: số to = giá trị, chữ nhỏ dưới = ý nghĩa số đó.

#### (4) Row 2 ô `_SummaryTile`

| Code | Ý nghĩa |
|------|---------|
| `Row` | Xếp ngang |
| `Expanded` × 2 | 2 ô **bằng nhau**, full width card |
| `SizedBox(width: 10)` | Khoảng cách giữa thu và chi |
| `totalIncome` / `totalExpense` | Số từ provider |
| Icon `trending_up` / `trending_down` | Visual cue tăng (thu) / giảm (chi) |

---

## 5. Full code UI — `_SummaryTile` (1 ô metric)

```dart
class _SummaryTile extends StatelessWidget {
  final String title;   // "Tổng thu" / "Tổng chi"
  final double amount;  // số thô từ provider
  final Color color;    // xanh hoặc hồng
  final IconData icon;

  const _SummaryTile({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        // Nền nhạt cùng tông màu metric (alpha 8%)
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        // Viền nhạt cùng tông (alpha 18%)
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hàng trên: icon + title
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Hàng dưới: số tiền đã format
          Text(
            CurrencyFormatter.format(amount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
```

| Thành phần | Công dụng |
|------------|-----------|
| `color.withValues(alpha: 0.08)` | Nền ô “nhuốm” màu thu/chi, không chói |
| `border` alpha 0.18 | Viền cùng tông, tách ô khỏi nền card |
| `Icon` size 16 | Icon nhỏ, không át số tiền |
| `CurrencyFormatter.format(amount)` | Đồng nhất format với số dư |
| Prefix `_` | Class private, chỉ dùng trong file màn giao dịch |

**Layout 1 ô:**

```
┌────────────────────┐
│ ↑  Tổng thu        │
│ 20.000.000 đ       │
└────────────────────┘
```

---

## 6. Số liệu lấy từ đâu? (Data layer)

### 6.1. Provider lưu 3 biến

```dart
// lib/providers/transaction_provider.dart
double _totalIncome = 0;
double _totalExpense = 0;
double _balance = 0;

double get totalIncome => _totalIncome;
double get totalExpense => _totalExpense;
double get balance => _balance;
```

UI **không** tự cộng list. UI chỉ **đọc** 3 getter này.

### 6.2. Khi nào số được cập nhật?

Mỗi lần `fetchTransactions(userId)` chạy (mở app, refresh, sau thêm/sửa/xóa, sau filter…):

```dart
Future<void> fetchTransactions(int userId) async {
  _isLoading = true;
  notifyListeners();

  _calculateDateRange();

  try {
    // 1) LIST: có áp dụng search / type / time / sort
    _transactions = await _repository.getTransactions(
      userId,
      search: _searchQuery,
      type: _selectedType,
      // ...
    );

    // 2) SUMMARY: gọi KHÔNG truyền startDate/endDate/type
    //    → luôn là TỔNG toàn bộ giao dịch của user
    final summary = await _repository.getFinancialSummary(userId);
    _totalIncome = summary['income'] ?? 0;
    _totalExpense = summary['expense'] ?? 0;
    _balance = summary['balance'] ?? 0;
  } finally {
    _isLoading = false;
    notifyListeners(); // → Consumer rebuild → số trên UI đổi
  }
}
```

### Điểm quan trọng khi thuyết trình

| Vùng | Có theo filter list không? |
|------|----------------------------|
| **Danh sách giao dịch bên dưới** | **Có** (search, Thu/Chi, thời gian, sort) |
| **Tổng quan (3 số này)** | **Không** — luôn tổng toàn bộ |

Ví dụ: User lọc “Chỉ Chi + Tháng này”  
→ List chỉ hiện chi trong tháng  
→ Card tổng quan **vẫn** hiện tổng thu/chi/số dư **cả đời** tài khoản  

Lý do: giống logic bản mẫu `test/` — summary là “tổng quan tài chính”, không bị “mất số” khi lọc list.

---

## 7. SQL tính số liệu — `getFinancialSummary`

```dart
// lib/database/transaction_repository.dart
Future<Map<String, double>> getFinancialSummary(
  int userId, {
  String? month,
  DateTime? startDate,
  DateTime? endDate,
}) async {
  final db = await _dbHelper.database;

  String whereClause = 'userId = ?';
  List<dynamic> whereArgs = [userId];

  // Optional: nếu truyền month / start / end thì lọc thêm
  // Nhưng màn Giao dịch gọi: getFinancialSummary(userId)
  // → chỉ có userId, không thêm điều kiện thời gian

  // SUM toàn bộ thu
  final incomeResult = await db.rawQuery(
    'SELECT SUM(amount) as total FROM transactions WHERE $whereClause AND type = ?',
    [...whereArgs, 'income'],
  );

  // SUM toàn bộ chi
  final expenseResult = await db.rawQuery(
    'SELECT SUM(amount) as total FROM transactions WHERE $whereClause AND type = ?',
    [...whereArgs, 'expense'],
  );

  double totalIncome = incomeResult.first['total'] ?? 0.0;
  double totalExpense = expenseResult.first['total'] ?? 0.0;
  double balance = totalIncome - totalExpense;  // ★ CÔNG THỨC SỐ DƯ

  return {
    'income': totalIncome,
    'expense': totalExpense,
    'balance': balance,
  };
}
```

### Công thức (nhớ thuộc)

```
Tổng thu   = SUM(amount) WHERE type = 'income'  AND userId = ?
Tổng chi   = SUM(amount) WHERE type = 'expense' AND userId = ?
Số dư      = Tổng thu − Tổng chi
```

| Trường hợp đặc biệt | Kết quả |
|---------------------|---------|
| Chưa có giao dịch | SUM = `null` → gán `0.0` nhờ `?? 0.0` |
| Chi > Thu | Số dư **âm** (vẫn format bình thường) |
| User khác | `userId` khác → không lẫn data |

---

## 8. Format tiền — `CurrencyFormatter`

```dart
// lib/utils/currency_formatter.dart
static String format(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0, // không hiện .00
  );
  return formatter.format(amount);
}
```

| Input | Output (xấp xỉ) |
|-------|-----------------|
| `20000000` | `20.000.000 đ` |
| `0` | `0 đ` |
| `-1500000` | `-1.500.000 đ` (nếu số dư âm) |

Dùng chung cho: số dư, tổng thu, tổng chi → UI đồng nhất.

---

## 9. Luồng end-to-end (tóm tắt 1 hình)

```
┌──────────────────┐
│ User mở tab      │
│ Giao dịch /      │
│ pull refresh /   │
│ sau CRUD         │
└────────┬─────────┘
         ▼
┌──────────────────┐
│ TransactionProvider
│ .fetchTransactions(userId)
└────────┬─────────┘
         ▼
┌──────────────────┐
│ Repository       │
│ getFinancialSummary(userId)
│  SQL SUM income  │
│  SQL SUM expense │
│  balance = I - E │
└────────┬─────────┘
         ▼
┌──────────────────┐
│ Gán              │
│ _totalIncome     │
│ _totalExpense    │
│ _balance         │
│ notifyListeners()│
└────────┬─────────┘
         ▼
┌──────────────────┐
│ Consumer rebuild │
│ _buildSummarySection
│  format + paint  │
└──────────────────┘
```

---

## 10. `CommonCard` bọc ngoài

```dart
// lib/widgets/common_card.dart (ý chính)
Container(
  padding: padding, // mặc định EdgeInsets.all(16)
  decoration: BoxDecoration(
    color: Theme.of(context).cardTheme.color,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(...),
    boxShadow: isDark ? [] : [ BoxShadow(...) ],
  ),
  child: child, // = Column tiêu đề + số dư + 2 tile
)
```

→ Khối tổng quan trông như **1 card** nổi trên nền màn hình, nhất quán style app.

---

## 11. Câu thuyết trình gợi ý (30–45 giây)

> “Phần đầu màn Giao dịch là **Tổng quan giao dịch**.  
> Gồm **số dư** (Tổng thu trừ Tổng chi), và 2 ô **Tổng thu / Tổng chi**.  
> Số liệu lấy từ SQLite bằng `SUM(amount)` theo `type`, qua `TransactionProvider`.  
> UI chỉ `CurrencyFormatter` + `CommonCard` + `_SummaryTile`.  
> Lưu ý: khi user lọc list, **tổng quan vẫn giữ số tổng** — vì đây là snapshot tài chính tổng, không bị filter che.”

---

## 12. Checklist đọc code khi chấm

1. Mở `transaction_list_screen.dart` → tìm `_buildSummarySection`  
2. Xem `_SummaryTile` ngay cuối file  
3. Mở `transaction_provider.dart` → `fetchTransactions` đoạn `getFinancialSummary`  
4. Mở `transaction_repository.dart` → công thức `balance = income - expense`  
5. Demo: thêm 1 khoản thu → refresh → 3 số tăng đúng  

---

*File này chỉ đi sâu **khối Tổng quan**. Các phần search / filter / list xem `TRANSACTION_LIST_EXPLAINED.md`.*
