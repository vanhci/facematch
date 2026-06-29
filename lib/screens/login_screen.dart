import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      _showError('请输入有效的邮箱地址');
      return;
    }
    if (password.length < 6) {
      _showError('密码至少 6 位');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isRegister) {
        await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );
        _onRegisterSuccess();
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        // AuthGate 会自动导航到主页
      }
    } on AuthException catch (e) {
      _showError(_mapAuthError(e.message));
    } catch (e) {
      _showError('网络异常，请重试');
    }

    setState(() => _isLoading = false);
  }

  bool _showRegisterSuccess = false;

  void _onRegisterSuccess() {
    setState(() {
      _showRegisterSuccess = true;
      _isRegister = false;
      _emailController.clear();
      _passwordController.clear();
    });
  }

  String _mapAuthError(String msg) {
    if (msg.contains('Invalid login credentials')) return '邮箱或密码错误';
    if (msg.contains('Email not confirmed')) return '请先确认邮箱（查看收件箱）';
    if (msg.contains('User already registered')) return '该邮箱已注册，请直接登录';
    if (msg.contains('Password should be')) return '密码至少 6 位';
    if (msg.contains('rate limit')) return '操作太频繁，请稍后再试';
    return msg;
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      _showError('先输入邮箱地址');
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      _showSuccess('密码重置链接已发送到邮箱');
    } catch (e) {
      _showError('发送失败，请重试');
    }
  }

  Widget _buildRegisterSuccess() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.gradientRose,
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: AppColors.cardShadow,
            ),
            child: const Icon(Icons.mark_email_read, color: Colors.white, size: 44),
          ),
          const SizedBox(height: 24),
          const Text('注册成功', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.neutral700)),
          const SizedBox(height: 12),
          const Text('确认邮件已发送到你的邮箱', style: TextStyle(fontSize: 15, color: AppColors.neutral500)),
          const SizedBox(height: 6),
          const Text('请查看收件箱（或垃圾邮件），点击确认链接后即可登录', style: TextStyle(fontSize: 13, color: AppColors.neutral400), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: () => setState(() => _showRegisterSuccess = false),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: const Color(0xFF4A1A2A),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
              ),
              child: const Text('去登录', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [Color(0xFFFFF0F0), Color(0xFFFCF5F5), Color(0xFFF5E9E9)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: _showRegisterSuccess ? _buildRegisterSuccess() : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientRose,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: const Icon(
                      Icons.face_retouching_natural,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '颜摹',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '看见你的妆 · 复制你的美',
                    style: TextStyle(fontSize: 13, color: AppColors.neutral400),
                  ),
                  const SizedBox(height: 40),

                  // Email
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.neutral200),
                    ),
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: '邮箱地址',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: AppColors.neutral400,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Password
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.neutral200),
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: '密码（至少6位）',
                        prefixIcon: const Icon(
                          Icons.lock_outlined,
                          color: AppColors.neutral400,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.neutral400,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resetPassword,
                      child: const Text(
                        '忘记密码？',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.neutral500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: const Color(0xFF4A1A2A),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              _isRegister ? '注册' : '登录',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Toggle register/login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isRegister ? '已有账号？' : '没有账号？',
                        style: const TextStyle(
                          color: AppColors.neutral500,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _isRegister = !_isRegister),
                        child: Text(
                          _isRegister ? '去登录' : '注册',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
