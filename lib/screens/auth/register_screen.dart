import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_decorations.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      email: _emailController.text,
      password: _passwordController.text,
      name: _nameController.text,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registrasi akun berhasil. Selamat datang.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Gagal mendaftar akun.'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
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
          // Background Neomorphic Ambient Circles
          Positioned(
            top: -60,
            right: -60,
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
            bottom: -60,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowDark.withValues(alpha: 0.4),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 18 : 28,
                  vertical: isCompact ? 16 : 20,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Raised Back Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: isCompact ? 40 : 44,
                            height: isCompact ? 40 : 44,
                            decoration: AppDecorations.squircleIcon(radius: 12),
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: isCompact ? 16 : 18,
                                color: AppColors.textPrimary,
                              ),
                              onPressed: () => Navigator.pop(context),
                              tooltip: 'Kembali',
                            ),
                          ),
                          Container(
                            width: isCompact ? 40 : 44,
                            height: isCompact ? 40 : 44,
                            decoration: AppDecorations.squircleIcon(radius: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/logo.webp',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isCompact ? 18 : 24),

                      // Heading
                      Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: isCompact ? 24 : 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Daftarkan akun operator lahan ARVEN IoT',
                        style: TextStyle(
                          fontSize: isCompact ? 12.5 : 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: isCompact ? 20 : 28),

                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Full name
                            _buildNeomorphicInputField(
                              controller: _nameController,
                              hintText: 'Nama Lengkap Operator',
                              icon: Icons.person_outline_rounded,
                              textCapitalization: TextCapitalization.words,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Nama lengkap tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Email
                            _buildNeomorphicInputField(
                              controller: _emailController,
                              hintText: 'Alamat Email',
                              icon: Icons.email_outlined,
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
                            const SizedBox(height: 16),

                            // Password
                            _buildNeomorphicInputField(
                              controller: _passwordController,
                              hintText: 'Kata Sandi (Minimal 6 Karakter)',
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
                            const SizedBox(height: 16),

                            // Confirm Password
                            _buildNeomorphicInputField(
                              controller: _confirmPasswordController,
                              hintText: 'Ulangi Kata Sandi',
                              icon: Icons.lock_reset_rounded,
                              obscureText: _obscureConfirmPassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Konfirmasi kata sandi tidak boleh kosong';
                                }
                                if (val != _passwordController.text) {
                                  return 'Konfirmasi kata sandi tidak cocok';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),

                            // Register Action Button (Centered text)
                            GestureDetector(
                              onTap: authProvider.isLoading ? null : _handleRegister,
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
                                        'Daftar Akun',
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
                      const SizedBox(height: 26),

                      // Back to login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Sudah memiliki akun? ',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              authProvider.clearError();
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Masuk di sini',
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
    TextCapitalization textCapitalization = TextCapitalization.none,
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
        textCapitalization: textCapitalization,
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
}
