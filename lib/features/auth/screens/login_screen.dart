import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/services/security_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();

  final AuthService _authService = AuthService();

  bool _loading = false;
  bool _obscure = true;
  bool _canCheckBiometrics = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await SecurityService.instance.isBiometricAvailable;
    final enabled = await SecurityService.instance.isBiometricEnabled;
    if (mounted) {
      setState(() => _canCheckBiometrics = available && enabled);
    }
    if (_canCheckBiometrics) {
      _loginWithBiometrics();
    }
  }

  Future<void> _loginWithBiometrics() async {
    final authenticated = await SecurityService.instance.authenticate(
      reason: context.tr('biometric_login_reason'),
    );

    if (authenticated) {
      final credentials = await SecureStorageService.getCredentials();
      if (credentials != null) {
        _emailCtrl.text = credentials['email'] ?? '';
        _passwordCtrl.text = credentials['password'] ?? '';
        _login();
      } else {
        if (mounted) {
          _showSnackBar(context.tr('no_stored_credentials'), AppColors.rose);
        }
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loading || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    final email = _emailCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text;

    try {
      await _authService.signIn(email, password);
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (_authService.currentUser != null && mounted) {
        await SecureStorageService.saveCredentials(email, password);
        _showSnackBar(context.tr('welcome_back_snack'), AppColors.emerald);
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) context.go('/');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(_parseErrorMessage(e.toString()), AppColors.rose);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _parseErrorMessage(String error) {
    if (error.contains('invalid-credential')) return context.tr('invalid_credential');
    if (error.contains('user-not-found')) return context.tr('user_not_found');
    if (error.contains('wrong-password')) return context.tr('wrong_password');
    return error.replaceAll(RegExp(r'\[.*?\]'), '').replaceAll('Exception:', '').trim();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.semiBold.copyWith(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: _CircularGlow(color: AppColors.indigo.withValues(alpha: 0.08), size: 300),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _CircularGlow(color: AppColors.blue.withValues(alpha: 0.08), size: 250),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Hero(
                          tag: 'auth_icon',
                          child: Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.indigo.withValues(alpha: 0.15),
                                  blurRadius: 30, offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Center(child: Icon(Icons.rocket_launch_rounded, size: 50, color: AppColors.indigo)),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(context.tr('welcome_back'), style: AppTextStyles.h1.copyWith(color: AppColors.textPrimary)),
                        Text(context.tr('sign_in_desc'), style: AppTextStyles.medium.copyWith(fontSize: 15, color: AppColors.textSecondary)),
                        const SizedBox(height: 48),
                        _ModernTextField(
                          controller: _emailCtrl,
                          hint: context.tr('email'),
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v == null || v.isEmpty ? context.tr('email_required') : null,
                          onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                        ),
                        const SizedBox(height: 20),
                        _ModernTextField(
                          controller: _passwordCtrl,
                          focusNode: _passwordFocus,
                          hint: context.tr('password'),
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          obscure: _obscure,
                          onToggleObscure: () => setState(() => _obscure = !_obscure),
                          validator: (v) => v == null || v.isEmpty ? context.tr('password_required') : null,
                          onFieldSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_canCheckBiometrics)
                              IconButton(
                                onPressed: _loginWithBiometrics,
                                icon: const Icon(Icons.fingerprint_rounded, color: AppColors.indigo, size: 32),
                                tooltip: 'Login with Biometrics',
                              ),
                            TextButton(
                              onPressed: () {},
                              child: Text(context.tr('forgot_password'), style: AppTextStyles.semiBold.copyWith(color: AppColors.indigo, fontSize: 13)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity, height: 60,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.indigo,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: _loading
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                : Text(context.tr('sign_in'), style: AppTextStyles.semiBold.copyWith(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 40),
                        GestureDetector(
                          onTap: _loading ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary, fontSize: 14),
                              children: [
                                TextSpan(text: context.tr('dont_have_account')),
                                TextSpan(text: context.tr('sign_up'), style: AppTextStyles.semiBold.copyWith(color: AppColors.indigo)),
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
        ],
      ),
    );
  }
}

class _ModernTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final Function(String)? onFieldSubmitted;

  const _ModernTextField({
    required this.controller, required this.hint, required this.icon,
    this.isPassword = false, this.obscure = false, this.onToggleObscure,
    this.keyboardType, this.validator, this.focusNode, this.onFieldSubmitted,
  });

  @override
  State<_ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<_ModernTextField> {
  bool _isFocused = false;
  late FocusNode _localFocusNode;

  @override
  void initState() {
    super.initState();
    _localFocusNode = widget.focusNode ?? FocusNode();
    _localFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _localFocusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) _localFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() => _isFocused = _localFocusNode.hasFocus);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _localFocusNode,
      obscureText: widget.obscure,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      style: AppTextStyles.semiBold.copyWith(fontSize: 15, color: _isFocused ? AppColors.indigo : AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: AppTextStyles.regular.copyWith(color: AppColors.textMuted, fontSize: 14),
        prefixIcon: Icon(widget.icon, color: _isFocused ? AppColors.indigo : AppColors.textSecondary, size: 22),
        suffixIcon: widget.isPassword ? IconButton(
          onPressed: widget.onToggleObscure,
          icon: Icon(widget.obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, 
            color: _isFocused ? AppColors.indigo : AppColors.textSecondary, size: 20),
        ) : null,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: AppColors.border, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: AppColors.border, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.indigo, width: 2.0)),
        errorStyle: AppTextStyles.medium.copyWith(fontSize: 12),
      ),
    );
  }
}

class _CircularGlow extends StatelessWidget {
  final Color color;
  final double size;
  const _CircularGlow({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)]),
  );
}
