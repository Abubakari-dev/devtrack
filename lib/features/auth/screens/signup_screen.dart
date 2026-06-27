import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

import '../../../core/localization/app_localizations.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  final AuthService _authService = AuthService();
  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  
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
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_loading || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim().toLowerCase();
    final phone = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text;

    try {
      await _authService.signUp(
        email: email,
        password: password,
        name: name,
        phoneNumber: phone,
      );
      
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (_authService.currentUser == null) {
        throw Exception('Account creation failed. Please try again.');
      }

      if (mounted) {
        _showSnackBar(context.tr('account_created_success'), AppColors.emerald);
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.go('/');
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = _parseErrorMessage(e.toString());
        _showSnackBar(errorMessage, AppColors.rose);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _parseErrorMessage(String error) {
    if (error.contains('email-already-in-use')) {
      return context.tr('email_already_registered');
    } else if (error.contains('invalid-email')) {
      return context.tr('invalid_email_error');
    } else if (error.contains('weak-password')) {
      return context.tr('weak_password_error');
    } else if (error.contains('network-request-failed')) {
      return context.tr('network_error');
    }
    return error.replaceAll(RegExp(r'\[.*?\]'), '').replaceAll('Exception:', '').trim();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.semiBold),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            left: -60,
            child: _CircularGlow(color: AppColors.indigo.withValues(alpha: 0.1), size: 350),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: _CircularGlow(color: AppColors.blue.withValues(alpha: 0.08), size: 300),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Hero(
                          tag: 'auth_icon',
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.indigo.withValues(alpha: 0.15),
                                  blurRadius: 40,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.rocket_launch_rounded, size: 56, color: AppColors.indigo),
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(context.tr('get_started'), style: AppTextStyles.h1),
                        const SizedBox(height: 8),
                        Text(
                          context.tr('create_account_desc'),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.medium.copyWith(fontSize: 16, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 56),
                        _buildInputLabel(context.tr('full_name_label')),
                        _ModernTextField(
                          controller: _nameCtrl,
                          focusNode: _nameFocus,
                          hint: context.tr('name_hint'),
                          icon: Icons.person_outline_rounded,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => v == null || v.trim().isEmpty ? context.tr('name_required') : null,
                          onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                        ),
                        const SizedBox(height: 24),
                        _buildInputLabel(context.tr('email_label')),
                        _ModernTextField(
                          controller: _emailCtrl,
                          focusNode: _emailFocus,
                          hint: context.tr('email_hint'),
                          icon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.isEmpty) return context.tr('email_required');
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return context.tr('valid_email_required');
                            return null;
                          },
                          onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
                        ),
                        const SizedBox(height: 24),
                        _buildInputLabel(context.tr('phone_label')),
                        _ModernTextField(
                          controller: _phoneCtrl,
                          focusNode: _phoneFocus,
                          hint: context.tr('phone_number_hint'),
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.isEmpty) return context.tr('phone_required');
                            if (!RegExp(r'^\d{10}$').hasMatch(v)) return context.tr('invalid_phone_error');
                            return null;
                          },
                          onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                        ),
                        const SizedBox(height: 24),
                        _buildInputLabel(context.tr('password_label')),
                        _ModernTextField(
                          controller: _passwordCtrl,
                          focusNode: _passwordFocus,
                          hint: context.tr('password_hint'),
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          obscure: _obscurePass,
                          onToggleObscure: () => setState(() => _obscurePass = !_obscurePass),
                          textInputAction: TextInputAction.next,
                          validator: (v) => v == null || v.length < 6 ? context.tr('password_min_length') : null,
                          onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
                        ),
                        const SizedBox(height: 24),
                        _buildInputLabel(context.tr('confirm_password_label')),
                        _ModernTextField(
                          controller: _confirmCtrl,
                          focusNode: _confirmFocus,
                          hint: context.tr('confirm_password_hint'),
                          icon: Icons.verified_user_outlined,
                          isPassword: true,
                          obscure: _obscureConfirm,
                          onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          textInputAction: TextInputAction.done,
                          validator: (v) => v != _passwordCtrl.text ? context.tr('passwords_not_match') : null,
                          onFieldSubmitted: (_) => _signup(),
                        ),
                        const SizedBox(height: 48),
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _signup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.indigo,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: _loading
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(context.tr('create_account'), style: AppTextStyles.semiBold.copyWith(fontSize: 16, letterSpacing: 1)),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.arrow_forward_rounded, size: 20),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        GestureDetector(
                          onTap: _loading ? null : () => Navigator.pop(context),
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary, fontSize: 15),
                              children: [
                                TextSpan(text: context.tr('already_member')),
                                TextSpan(
                                  text: context.tr('sign_in'),
                                  style: AppTextStyles.semiBold.copyWith(color: AppColors.indigo),
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
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(fontSize: 11, letterSpacing: 1.2),
        ),
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
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final Function(String)? onFieldSubmitted;

  const _ModernTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.obscure = false,
    this.onToggleObscure,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.focusNode,
    this.onFieldSubmitted,
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
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      style: AppTextStyles.semiBold.copyWith(fontSize: 15, color: _isFocused ? AppColors.indigo : AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: AppTextStyles.regular.copyWith(color: AppColors.textMuted, fontSize: 14),
        prefixIcon: Icon(widget.icon, color: _isFocused ? AppColors.indigo : AppColors.textSecondary, size: 22),
        suffixIcon: widget.isPassword
            ? IconButton(
                onPressed: widget.onToggleObscure,
                icon: Icon(widget.obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, 
                  color: _isFocused ? AppColors.indigo : AppColors.textSecondary, size: 20),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
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
