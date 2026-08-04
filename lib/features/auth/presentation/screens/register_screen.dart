import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../legal/presentation/widgets/consent_checkbox.dart';
import 'role_selection_screen.dart';

enum PasswordStrength { none, weak, medium, strong }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _fullNameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;
  PasswordStrength _passwordStrength = PasswordStrength.none;

  void _checkPasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() => _passwordStrength = PasswordStrength.none);
      return;
    }
    if (password.length < 6) {
      setState(() => _passwordStrength = PasswordStrength.weak);
      return;
    }

    final hasLetters = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasDigits = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    if (password.length >= 8 && hasLetters && hasDigits && hasSpecial) {
      setState(() => _passwordStrength = PasswordStrength.strong);
    } else if (hasLetters && hasDigits) {
      setState(() => _passwordStrength = PasswordStrength.medium);
    } else {
      setState(() => _passwordStrength = PasswordStrength.weak);
    }
  }

  void _validateFields() {
    setState(() {
      final name = _fullNameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;

      if (name.isEmpty) {
        _fullNameError = 'Ad soyad alanı boş bırakılamaz';
      } else {
        _fullNameError = null;
      }

      if (email.isEmpty) {
        _emailError = 'E-posta adresi boş bırakılamaz';
      } else if (!email.contains('@')) {
        _emailError = 'Geçerli bir e-posta adresi giriniz';
      } else {
        _emailError = null;
      }

      if (password.isEmpty) {
        _passwordError = 'Şifre boş bırakılamaz';
      } else if (password.length < 6) {
        _passwordError = 'Şifre en az 6 karakter olmalıdır';
      } else {
        _passwordError = null;
      }

      if (confirmPassword.isEmpty) {
        _confirmPasswordError = 'Şifre tekrarı boş bırakılamaz';
      } else if (confirmPassword != password) {
        _confirmPasswordError = 'Şifreler eşleşmiyor';
      } else {
        _confirmPasswordError = null;
      }
    });
  }

  void _handleRegister() {
    _validateFields();

    if (_fullNameError != null ||
        _emailError != null ||
        _passwordError != null ||
        _confirmPasswordError != null ||
        !_termsAccepted) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
    );
  }

  Widget _buildStrengthIndicator() {
    Color color;
    double progress;
    String label;

    switch (_passwordStrength) {
      case PasswordStrength.none:
        color = Colors.transparent;
        progress = 0;
        label = '';
        break;
      case PasswordStrength.weak:
        color = AppColors.error;
        progress = 0.33;
        label = 'Zayıf';
        break;
      case PasswordStrength.medium:
        color = AppColors.warning;
        progress = 0.66;
        label = 'Orta';
        break;
      case PasswordStrength.strong:
        color = AppColors.success;
        progress = 1.0;
        label = 'Güçlü';
        break;
    }

    if (_passwordStrength == PasswordStrength.none) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.15),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Aramıza katıl',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Hemen kaydol ve gıdayı kurtarmaya başla.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.brightness == Brightness.light
                            ? AppColors.textMutedLight
                            : AppColors.textMutedDark,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Full Name Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ad Soyad',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _fullNameController,
                          decoration: InputDecoration(
                            hintText: 'John Doe',
                            prefixIcon: const Icon(Icons.person_outline_rounded),
                            errorText: _fullNameError,
                          ),
                          onChanged: (_) {
                            if (_fullNameError != null) _validateFields();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Email Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'E-posta Adresi',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'ornek@email.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                            errorText: _emailError,
                          ),
                          onChanged: (_) {
                            if (_emailError != null) _validateFields();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Password Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Şifre',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: '••••••',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            errorText: _passwordError,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          onChanged: (val) {
                            _checkPasswordStrength(val);
                            if (_passwordError != null) _validateFields();
                          },
                        ),
                        _buildStrengthIndicator(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Confirm Password Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Şifre Tekrarı',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            hintText: '••••••',
                            prefixIcon: const Icon(Icons.lock_clock_outlined),
                            errorText: _confirmPasswordError,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          onChanged: (_) {
                            if (_confirmPasswordError != null) _validateFields();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    ConsentCheckbox(
                      value: _termsAccepted,
                      onChanged: (val) {
                        setState(() {
                          _termsAccepted = val ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Submit Button (Disabled unless T&C checked)
                    FilledButton(
                      onPressed: _termsAccepted ? _handleRegister : null,
                      child: const Text('Kayıt Ol'),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
