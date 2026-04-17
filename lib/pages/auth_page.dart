import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _agreedPrivacy = false;
  bool _agreedTerms = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _usernameController.text.trim().isNotEmpty &&
        _passwordController.text.length >= 8 &&
        _agreedPrivacy &&
        _agreedTerms;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final isLogin = authState.mode == AuthMode.login;

    ref.listen<AuthState>(authProvider, (previous, next) {
      final previousMessage = previous?.errorMessage;
      final nextMessage = next.errorMessage;
      if (nextMessage != null && nextMessage != previousMessage) {
        _showMessageDialog(
          title: isLogin ? '登录失败' : '注册失败',
          message: nextMessage,
        );
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFDF6ED),
              Color(0xFFF7F2EA),
              Color(0xFFEFE7DB),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x19000000),
                        blurRadius: 28,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1917),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            Icons.shield_moon_outlined,
                            color: Color(0xFFF6E7C8),
                            size: 34,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        isLogin ? '欢迎回来' : '创建账号',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1C1917),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isLogin
                            ? '登录后即可进入社区内容与个人中心。'
                            : '注册后即可发布帖子、评论和点赞。',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6B7280),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _AuthModeSegment(
                        mode: authState.mode,
                        onChanged: (mode) {
                          ref.read(authProvider.notifier).switchMode(mode);
                        },
                      ),
                      const SizedBox(height: 24),
                      _InputLabel(text: 'Username'),
                      const SizedBox(height: 8),
                      _AuthTextField(
                        controller: _usernameController,
                        hintText: 'Enter your username',
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 18),
                      _InputLabel(text: 'Password'),
                      const SizedBox(height: 8),
                      _AuthTextField(
                        controller: _passwordController,
                        hintText: 'At least 8 characters',
                        obscureText: true,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 18),
                      _AgreementRow(
                        value: _agreedPrivacy,
                        text: '我已阅读并同意《隐私协议》',
                        onChanged: (value) {
                          setState(() {
                            _agreedPrivacy = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      _AgreementRow(
                        value: _agreedTerms,
                        text: '我已阅读并同意《用户协议》',
                        onChanged: (value) {
                          setState(() {
                            _agreedTerms = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      _SubmitButton(
                        label: isLogin ? '登录' : '注册',
                        enabled: _isFormValid && !authState.isSubmitting,
                        loading: authState.isSubmitting,
                        onTap: _handleSubmit,
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                            children: [
                              TextSpan(
                                text: isLogin ? '还没有账号？' : '已经有账号？',
                              ),
                              TextSpan(
                                text: isLogin ? ' 去注册' : ' 去登录',
                                style: const TextStyle(
                                  color: Color(0xFF8B5E3C),
                                  fontWeight: FontWeight.w700,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    ref.read(authProvider.notifier).switchMode(
                                          isLogin
                                              ? AuthMode.register
                                              : AuthMode.login,
                                        );
                                  },
                              ),
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
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_isFormValid) {
      await _showMessageDialog(
        title: '提示',
        message: _buildValidationMessage(),
      );
      return;
    }

    await ref.read(authProvider.notifier).submit(
          username: _usernameController.text,
          password: _passwordController.text,
        );
  }

  String _buildValidationMessage() {
    if (_usernameController.text.trim().isEmpty) {
      return 'Username 不能为空。';
    }
    if (_passwordController.text.length < 8) {
      return 'Password 至少需要 8 位。';
    }
    if (!_agreedPrivacy || !_agreedTerms) {
      return '请先勾选隐私协议和用户协议。';
    }
    return '请检查输入内容。';
  }

  Future<void> _showMessageDialog({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('知道了'),
            ),
          ],
        );
      },
    );
  }
}

class _AuthModeSegment extends StatelessWidget {
  const _AuthModeSegment({
    required this.mode,
    required this.onChanged,
  });

  final AuthMode mode;
  final ValueChanged<AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EFE6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: '登录',
              selected: mode == AuthMode.login,
              onTap: () => onChanged(AuthMode.login),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: '注册',
              selected: mode == AuthMode.register,
              onTap: () => onChanged(AuthMode.register),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1F2937) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF6B7280),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  const _InputLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF6B7280),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.obscureText = false,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final ValueChanged<String> onChanged;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF8B5E3C), width: 1.2),
        ),
      ),
    );
  }
}

class _AgreementRow extends StatelessWidget {
  const _AgreementRow({
    required this.value,
    required this.text,
    required this.onChanged,
  });

  final bool value;
  final String text;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Checkbox(
            value: value,
            activeColor: const Color(0xFF8B5E3C),
            onChanged: (selected) => onChanged(selected ?? false),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF8B5E3C) : const Color(0xFFD6C4AE),
          borderRadius: BorderRadius.circular(18),
          boxShadow: enabled
              ? const [
                  BoxShadow(
                    color: Color(0x338B5E3C),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
