import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_decorations.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Gagal masuk akun.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isCompact = MediaQuery.of(context).size.width < 360;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Neomorphic Ambient Circles (Reference Image #1)
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.6),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryLight.withValues(alpha: 0.2),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 140,
            right: -50,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.25),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -40,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowDark.withValues(alpha: 0.4),
                    blurRadius: 60,
                    spreadRadius: 12,
                  ),
                ],
              ),
            ),
          ),

          // Main Login Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 18 : 28,
                  vertical: isCompact ? 18 : 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),

                          // Raised 3D ARVEN Logo Emblem
                          Container(
                            width: isCompact ? 88 : 104,
                            height: isCompact ? 88 : 104,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(isCompact ? 24 : 30),
                              boxShadow: AppDecorations.raisedShadow,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(isCompact ? 24 : 30),
                              child: Image.asset(
                                'assets/logo.webp',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(height: isCompact ? 18 : 24),

                          // Titles
                          Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: isCompact ? 24 : 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Sign in to continue',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.0,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: isCompact ? 24 : 32),

                      // Form with Neomorphic Raised Inputs
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Email Input Pill (Reference Image #1)
                            _buildNeomorphicInputField(
                              controller: _emailController,
                              hintText: 'Username or Email',
                              icon: Icons.person_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Email tidak boleh kosong';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                                  return 'Format email tidak valid';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            // Password Input Pill (Reference Image #1)
                            _buildNeomorphicInputField(
                              controller: _passwordController,
                              hintText: 'Password',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Kata sandi tidak boleh kosong';
                                }
                                if (val.length < 6) {
                                  return 'Kata sandi minimal 6 karakter';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            // Remember Me & Forgot Password
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _rememberMe = !_rememberMe;
                                          });
                                        },
                                        child: Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            color: _rememberMe
                                                ? AppColors.primary
                                                : AppColors.surfaceWhite,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: _rememberMe
                                                  ? AppColors.primary
                                                  : AppColors.cardBorder,
                                              width: 1.5,
                                            ),
                                            boxShadow: AppDecorations.softRaisedShadow,
                                          ),
                                          child: _rememberMe
                                              ? const Icon(
                                                  Icons.check_rounded,
                                                  size: 16,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Flexible(
                                        child: Text(
                                          'Remember Me',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Silakan hubungi administrator sistem untuk reset.'),
                                        backgroundColor: AppColors.primary,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),

                            // Vibrant Gradient Login Button (Centered text, no arrow)
                            GestureDetector(
                              onTap: authProvider.isLoading ? null : _handleLogin,
                              child: Container(
                                height: 56,
                                width: double.infinity,
                                decoration: AppDecorations.primaryButtonDecoration(radius: 28),
                                alignment: Alignment.center,
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Login',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // "OR CONTINUE WITH" Divider (Reference Image #1)
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: AppColors.divider,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'OR CONTINUE WITH',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                                color: AppColors.textLight,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: AppColors.divider,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Single "Sign in with Google" Pill Button (Reference Image #4)
                      _buildGoogleSignInButton(authProvider),
                      const SizedBox(height: 30),

                      // Tagline & Register Link (Reference Image #1)
                      const Text(
                        'MONITOR  •  AUTOMATE  •  GROW SMARTER',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Belum memiliki akun? ',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              authProvider.clearError();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Daftar di sini',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
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
        ],
      ),
    );
  }

  Widget _buildNeomorphicInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.4,
        ),
        boxShadow: AppDecorations.softRaisedShadow,
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: AppColors.textLight,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 18, right: 12),
            child: Icon(icon, color: AppColors.textSecondary, size: 22),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: suffixIcon,
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildGoogleSignInButton(AuthProvider authProvider) {
    return GestureDetector(
      onTap: authProvider.isLoading
          ? null
          : () async {
              FocusScope.of(context).unfocus();
              final success = await authProvider.signInWithGoogle();
              if (!success && authProvider.errorMessage != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(authProvider.errorMessage!),
                    backgroundColor: AppColors.danger,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.cardBorder,
            width: 1.2,
          ),
          boxShadow: AppDecorations.softRaisedShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGoogleLogo(),
            const SizedBox(width: 12),
            const Text(
              'Sign in with Google',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleLogo() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

/// Official Vector Google 'G' Logo Painter (Standard 4-color Brand Mark)
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Scale standard 24x24 Google vector viewBox to canvas size
    final double scale = size.width / 24.0;
    canvas.scale(scale, scale);

    final Paint paint = Paint()..style = PaintingStyle.fill;

    // 1. Blue segment (Crossbar & right quadrant)
    paint.color = const Color(0xFF4285F4);
    final Path bluePath = Path()
      ..moveTo(22.56, 12.25)
      ..cubicTo(22.56, 11.47, 22.49, 10.72, 22.36, 10.0)
      ..lineTo(12.0, 10.0)
      ..lineTo(12.0, 14.26)
      ..lineTo(17.92, 14.26)
      ..cubicTo(17.66, 15.63, 16.88, 16.79, 15.71, 17.57)
      ..lineTo(15.71, 20.34)
      ..lineTo(19.28, 20.34)
      ..cubicTo(21.36, 18.42, 22.56, 15.6, 22.56, 12.25)
      ..close();
    canvas.drawPath(bluePath, paint);

    // 2. Green segment (Bottom arc)
    paint.color = const Color(0xFF34A853);
    final Path greenPath = Path()
      ..moveTo(12.0, 23.0)
      ..cubicTo(14.97, 23.0, 17.46, 22.02, 19.28, 20.34)
      ..lineTo(15.71, 17.57)
      ..cubicTo(14.73, 18.23, 13.48, 18.63, 12.0, 18.63)
      ..cubicTo(9.14, 18.63, 6.71, 16.7, 5.84, 14.1)
      ..lineTo(2.18, 14.1)
      ..lineTo(2.18, 16.94)
      ..cubicTo(3.99, 20.53, 7.7, 23.0, 12.0, 23.0)
      ..close();
    canvas.drawPath(greenPath, paint);

    // 3. Yellow segment (Left arc)
    paint.color = const Color(0xFFFBBC05);
    final Path yellowPath = Path()
      ..moveTo(5.84, 14.09)
      ..cubicTo(5.62, 13.43, 5.49, 12.73, 5.49, 12.0)
      ..cubicTo(5.49, 11.27, 5.62, 10.57, 5.84, 9.91)
      ..lineTo(5.84, 7.06)
      ..lineTo(2.18, 7.06)
      ..cubicTo(1.43, 8.55, 1.0, 10.22, 1.0, 12.0)
      ..cubicTo(1.0, 13.78, 1.43, 15.45, 2.18, 16.94)
      ..lineTo(5.03, 14.72)
      ..lineTo(5.84, 14.09)
      ..close();
    canvas.drawPath(yellowPath, paint);

    // 4. Red segment (Top arc)
    paint.color = const Color(0xFFEA4335);
    final Path redPath = Path()
      ..moveTo(12.0, 5.38)
      ..cubicTo(13.62, 5.38, 15.06, 5.94, 16.21, 7.02)
      ..lineTo(19.36, 3.87)
      ..cubicTo(17.45, 2.09, 14.97, 1.0, 12.0, 1.0)
      ..cubicTo(7.7, 1.0, 3.99, 3.47, 2.18, 7.06)
      ..lineTo(5.84, 9.91)
      ..cubicTo(6.71, 7.31, 9.14, 5.38, 12.0, 5.38)
      ..close();
    canvas.drawPath(redPath, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
