import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/constants/app_colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
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
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
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
    final password = _passwordCtrl.text;

    try {
      // Create user account and profile via AuthService (passes name!)
      await _authService.signUp(
        email: email,
        password: password,
        name: name,
      );
      
      // Wait for Firestore to complete
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Verify user is authenticated
      if (_authService.currentUser == null) {
        throw Exception('Account creation failed. Please try again.');
      }

      if (mounted) {
        _showSnackBar('🎉 Account created successfully!', AppColors.green);
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = _parseErrorMessage(e.toString());
        _showSnackBar(errorMessage, AppColors.red);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _parseErrorMessage(String error) {
    if (error.contains('email-already-in-use')) {
      return 'This email is already registered. Try signing in instead';
    } else if (error.contains('invalid-email')) {
      return 'Please enter a valid email address';
    } else if (error.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters';
    } else if (error.contains('operation-not-allowed')) {
      return 'Email/password sign-up is not enabled';
    } else if (error.contains('network-request-failed')) {
      return 'Network error. Check your internet connection';
    } else if (error.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later';
    }
    
    return error
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll('Exception:', '')
        .trim();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordCtrl.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
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
          // Background gradient glows
          Positioned(
            top: -120,
            left: -60,
            child: _CircularGlow(
              color: AppColors.indigo.withValues(alpha: 0.12),
              size: 350,
            ),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: _CircularGlow(
              color: AppColors.blue.withValues(alpha: 0.1),
              size: 300,
            ),
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
                        // Hero Icon
                        Hero(
                          tag: 'auth_icon',
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.indigo.withValues(alpha: 0.2),
                                  blurRadius: 40,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.rocket_launch_rounded,
                              size: 56,
                              color: AppColors.indigo,
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Title
                        Text(
                          'Get Started',
                          style: GoogleFonts.poppins(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your account to start managing projects',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 56),

                        // Full Name Field
                        _buildInputLabel('FULL NAME'),
                        _ModernTextField(
                          controller: _nameCtrl,
                          focusNode: _nameFocus,
                          hint: 'e.g. John Doe',
                          icon: Icons.person_outline_rounded,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Please enter your name'
                              : null,
                          onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                        ),
                        const SizedBox(height: 24),

                        // Email Field
                        _buildInputLabel('EMAIL ADDRESS'),
                        _ModernTextField(
                          controller: _emailCtrl,
                          focusNode: _emailFocus,
                          hint: 'name@example.com',
                          icon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: _validateEmail,
                          onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                        ),
                        const SizedBox(height: 24),

                        // Password Field
                        _buildInputLabel('PASSWORD'),
                        _ModernTextField(
                          controller: _passwordCtrl,
                          focusNode: _passwordFocus,
                          hint: 'Min. 6 characters',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          obscure: _obscurePass,
                          onToggleObscure: () => setState(() => _obscurePass = !_obscurePass),
                          textInputAction: TextInputAction.next,
                          validator: _validatePassword,
                          onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
                        ),
                        const SizedBox(height: 24),

                        // Confirm Password Field
                        _buildInputLabel('CONFIRM PASSWORD'),
                        _ModernTextField(
                          controller: _confirmCtrl,
                          focusNode: _confirmFocus,
                          hint: 'Repeat password',
                          icon: Icons.verified_user_outlined,
                          isPassword: true,
                          obscure: _obscureConfirm,
                          onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          textInputAction: TextInputAction.done,
                          validator: _validateConfirmPassword,
                          onFieldSubmitted: (_) => _signup(),
                        ),

                        const SizedBox(height: 48),

                        // Create Account Button
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _signup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.indigo,
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor: AppColors.indigo.withValues(alpha: 0.4),
                              disabledBackgroundColor: AppColors.indigo.withValues(alpha: 0.6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'CREATE ACCOUNT',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.arrow_forward_rounded, size: 20),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Sign In Link
                        GestureDetector(
                          onTap: _loading ? null : () => Navigator.pop(context),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary,
                                  fontSize: 15,
                                ),
                                children: [
                                  const TextSpan(text: 'Already a member? '),
                                  TextSpan(
                                    text: 'Sign In',
                                    style: const TextStyle(
                                      color: AppColors.indigo,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
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
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.black.withValues(alpha: 0.6),
            letterSpacing: 1.2,
          ),
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
    if (widget.focusNode == null) {
      _localFocusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _localFocusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _localFocusNode,
        obscureText: widget.obscure,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        validator: widget.validator,
        onFieldSubmitted: widget.onFieldSubmitted,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: _isFocused ? AppColors.indigo : Colors.black,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: GoogleFonts.poppins(
            color: AppColors.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            widget.icon,
            color: _isFocused ? AppColors.indigo : Colors.black54,
            size: 22,
          ),
          suffixIcon: widget.isPassword
              ? IconButton(
                  onPressed: widget.onToggleObscure,
                  icon: Icon(
                    widget.obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _isFocused ? AppColors.indigo : Colors.black54,
                    size: 20,
                  ),
                  tooltip: widget.obscure ? 'Show password' : 'Hide password',
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 22,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Colors.black, width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Colors.black, width: 2.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: AppColors.indigo, width: 2.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2.5),
          ),
          errorStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CircularGlow extends StatelessWidget {
  final Color color;
  final double size;

  const _CircularGlow({
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 50,
          ),
        ],
      ),
    );
  }
}
