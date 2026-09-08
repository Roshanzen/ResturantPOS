import 'package:flutter/material.dart';
import 'package:restaurant_pos/app/bootstrap.dart';
import 'package:restaurant_pos/screens/main_screen.dart';
import 'package:restaurant_pos/theme/pos_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _usernameController.text = '';
    _passwordController.text = '';
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authController = AppBootstrap.authController;
        await authController.login(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );

        if (!mounted) return;

        if (authController.isAuthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        } else {
          setState(() {
            _errorMessage =
                authController.errorMessage ?? 'Invalid username or password';
            _isLoading = false;
          });
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Unable to connect to the server. Please try again.';
          _isLoading = false;
        });
      }
  }

  void _handleForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Password reset is not configured. Please contact your administrator.'),
        backgroundColor: Color(0xFF6F4E37),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PosTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.language_rounded,
                          color: Color(0xFF6F4E37)),
                      tooltip: 'Language',
                    ),
                    _LanguageSelector(
                      onChanged: (_) {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6F4E37).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.coffee_rounded,
                          size: 32,
                          color: Color(0xFF6F4E37),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'RestroPOS',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: PosTheme.textPrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: PosTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Login to access your POS system',
                  style: TextStyle(
                    fontSize: 14,
                    color: PosTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  autofillHints: const [AutofillHints.username, AutofillHints.email],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email or username';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Email or Username',
                    hintText: 'Enter your email or username',
                    prefixIcon: const Icon(Icons.person_outline_rounded,
                        color: Color(0xFF6F4E37)),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  enabled: !_isLoading,
                  autofillHints: const [AutofillHints.password],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _isLoading ? null : _handleLogin(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: Color(0xFF6F4E37)),
                    suffixIcon: IconButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: PosTheme.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                      activeColor: const Color(0xFF6F4E37),
                      checkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Text(
                      'Remember me',
                      style: TextStyle(fontSize: 13, color: PosTheme.textSecondary),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _isLoading ? null : _handleForgotPassword,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6F4E37),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Forgot password?'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFD32F2F).withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 20, color: Color(0xFFD32F2F)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFD32F2F),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6F4E37),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'LOG IN',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: const Color(0xFF333333))),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: PosTheme.textMuted,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: const Color(0xFF333333))),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: TextButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Google Sign-In is not configured. Please use username and password.'),
                                backgroundColor: Color(0xFF6F4E37),
                              ),
                            );
                          },
                    icon: Image.network(
                      'https://www.google.com/favicon.ico',
                      width: 20,
                      height: 20,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.g_mobiledata_rounded, size: 22),
                    ),
                    label: const Text(
                      'Continue with Google',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: PosTheme.textSecondary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: PosTheme.textSecondary,
                      backgroundColor: PosTheme.surfaceColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF333333)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: PosTheme.textMuted,
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    child: const Text("Don't have an account? Contact your admin"),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class _LanguageSelector extends StatelessWidget {
  final ValueChanged<String?> onChanged;

  const _LanguageSelector({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: PosTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language_rounded,
              size: 18, color: Color(0xFF6F4E37)),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: 'English',
              isDense: true,
              icon: const Icon(Icons.arrow_drop_down_rounded,
                  size: 20, color: Color(0xFF6F4E37)),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C2C2C),
              ),
              items: const [
                DropdownMenuItem(value: 'English', child: Text('English')),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
