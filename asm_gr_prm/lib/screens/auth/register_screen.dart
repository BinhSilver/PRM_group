import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/budget_provider.dart';
import '../../providers/spending_jar_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_constants.dart';
import '../main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _displayNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  final _displayNameFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Password strength
  int _passwordStrength = 0; // 0-4

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    _animCtrl.forward();
    _passwordCtrl.addListener(_updatePasswordStrength);
  }

  void _updatePasswordStrength() {
    final p = _passwordCtrl.text;
    int strength = 0;
    if (p.length >= 6) strength++;
    if (p.length >= 10) strength++;
    if (RegExp(r'[A-Z]').hasMatch(p)) strength++;
    if (RegExp(r'[0-9!@#\$%^&*]').hasMatch(p)) strength++;
    setState(() => _passwordStrength = strength);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _displayNameCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _displayNameFocus.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await context.read<UserProvider>().register(
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text,
      displayName: _displayNameCtrl.text.trim(),
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isLoading = false;
        _errorMessage = error;
      });
      return;
    }

    // Tải dữ liệu cho user mới
    final userId = context.read<UserProvider>().currentUser!.id;
    await Future.wait([
      context.read<TransactionProvider>().fetchTransactions(userId),
      context.read<BudgetProvider>().loadBudgets(userId),
      context.read<SpendingJarProvider>().loadJars(userId),
    ]);

    if (!mounted) return;

    // Hiển thị chào mừng
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.celebration_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              'Chào mừng ${_displayNameCtrl.text.trim()}!',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppColors.income,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF151018),
                    const Color(0xFF2D1535),
                    const Color(0xFF151018),
                  ]
                : [
                    const Color(0xFFFFF5FA),
                    const Color(0xFFFFE4F4),
                    const Color(0xFFFFF5FA),
                  ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  // AppBar tùy chỉnh
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          key: const Key('register_back_button'),
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: isDark
                                ? AppColors.darkTextMain
                                : AppColors.lightTextMain,
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Text(
                          'Tạo tài khoản',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextMain
                                : AppColors.lightTextMain,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
                      child: Column(
                        children: [
                          // Header nhỏ
                          _buildHeader(isDark),
                          const SizedBox(height: 28),

                          // Form card
                          _buildFormCard(isDark, primaryColor),

                          const SizedBox(height: 28),

                          // Login link
                          _buildLoginLink(isDark, primaryColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_add_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đăng ký tài khoản',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.darkTextMain
                    : AppColors.lightTextMain,
              ),
            ),
            Text(
              'Điền đầy đủ thông tin bên dưới',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormCard(bool isDark, Color primaryColor) {
    final cardColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFEEE0F0);

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.06),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error banner
            if (_errorMessage != null) ...[
              _buildErrorBanner(_errorMessage!),
              const SizedBox(height: 18),
            ],

            // Tên hiển thị
            _buildLabel('Tên hiển thị', textColor),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('register_display_name_field'),
              controller: _displayNameCtrl,
              focusNode: _displayNameFocus,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(color: textColor),
              decoration: _inputDecoration(
                hint: 'Nguyễn Văn A',
                icon: Icons.badge_outlined,
                isDark: isDark,
                primaryColor: primaryColor,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Vui lòng nhập tên hiển thị';
                }
                if (v.trim().length < 2) {
                  return 'Tên quá ngắn (ít nhất 2 ký tự)';
                }
                return null;
              },
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_usernameFocus),
            ),
            const SizedBox(height: 16),

            // Username
            _buildLabel('Tên đăng nhập', textColor),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('register_username_field'),
              controller: _usernameCtrl,
              focusNode: _usernameFocus,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: textColor),
              decoration: _inputDecoration(
                hint: 'vd: nguyenvana',
                icon: Icons.alternate_email_rounded,
                isDark: isDark,
                primaryColor: primaryColor,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Vui lòng nhập tên đăng nhập';
                }
                if (v.trim().length < 3) {
                  return 'Tên đăng nhập ít nhất 3 ký tự';
                }
                if (!RegExp(r'^[a-zA-Z0-9_\.]+$').hasMatch(v.trim())) {
                  return 'Chỉ được dùng chữ, số, dấu _ và .';
                }
                return null;
              },
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_passwordFocus),
            ),
            const SizedBox(height: 16),

            // Password
            _buildLabel('Mật khẩu', textColor),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('register_password_field'),
              controller: _passwordCtrl,
              focusNode: _passwordFocus,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              style: TextStyle(color: textColor),
              decoration: _inputDecoration(
                hint: 'Ít nhất 6 ký tự',
                icon: Icons.lock_outline_rounded,
                isDark: isDark,
                primaryColor: primaryColor,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: isDark
                        ? AppColors.darkTextSub
                        : AppColors.lightTextSub,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                if (v.length < 6) return 'Mật khẩu ít nhất 6 ký tự';
                return null;
              },
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_confirmFocus),
            ),
            // Password strength indicator
            if (_passwordCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildPasswordStrength(isDark),
            ],
            const SizedBox(height: 16),

            // Confirm Password
            _buildLabel('Xác nhận mật khẩu', textColor),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('register_confirm_password_field'),
              controller: _confirmPasswordCtrl,
              focusNode: _confirmFocus,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              style: TextStyle(color: textColor),
              decoration: _inputDecoration(
                hint: 'Nhập lại mật khẩu',
                icon: Icons.lock_person_outlined,
                isDark: isDark,
                primaryColor: primaryColor,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: isDark
                        ? AppColors.darkTextSub
                        : AppColors.lightTextSub,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                if (v != _passwordCtrl.text) return 'Mật khẩu không khớp';
                return null;
              },
              onFieldSubmitted: (_) => _register(),
            ),
            const SizedBox(height: 28),

            // Register button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                key: const Key('register_submit_button'),
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Tạo tài khoản',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStrength(bool isDark) {
    final labels = ['Rất yếu', 'Yếu', 'Trung bình', 'Mạnh', 'Rất mạnh'];
    final colors = [
      AppColors.expense,
      AppColors.warning,
      AppColors.warning,
      AppColors.income,
      AppColors.income,
    ];
    final subColor = isDark ? AppColors.darkTextSub : AppColors.lightTextSub;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: i < _passwordStrength
                      ? colors[_passwordStrength]
                      : (isDark
                            ? AppColors.darkBorder
                            : const Color(0xFFEEE0F0)),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          'Độ mạnh: ${labels[_passwordStrength]}',
          style: TextStyle(
            fontSize: 11,
            color: _passwordStrength > 0 ? colors[_passwordStrength] : subColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink(bool isDark, Color primaryColor) {
    final subColor = isDark ? AppColors.darkTextSub : AppColors.lightTextSub;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Đã có tài khoản? ',
          style: TextStyle(color: subColor, fontSize: 14),
        ),
        GestureDetector(
          key: const Key('register_go_login_link'),
          onTap: () => Navigator.of(context).pop(),
          child: Text(
            'Đăng nhập',
            style: TextStyle(
              color: primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.expense.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.expense.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.expense, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.expense,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color primaryColor,
    Widget? suffixIcon,
  }) {
    final fillColor = isDark
        ? const Color(0xFF2F1B38)
        : const Color(0xFFFDF0F9);
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFEEE0F0);
    final hintColor = isDark ? AppColors.darkTextSub : AppColors.lightTextSub;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: hintColor, fontSize: 14),
      prefixIcon: Icon(icon, color: hintColor, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.expense.withValues(alpha: 0.7)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.expense),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    );
  }
}
