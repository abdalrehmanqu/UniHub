import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/unihub_logo.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  late final ProviderSubscription<AuthStateData> _authSubscription;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  bool _isLogin = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _authSubscription = ref.listenManual<AuthStateData>(
      authControllerProvider,
      (previous, next) {
        final message = next.errorMessage;
        if (message != null &&
            message.isNotEmpty &&
            message != previous?.errorMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      },
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _animationController.forward();
  }

  @override
  void reassemble() {
    super.reassemble();
    _animationController
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _authSubscription.close();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authController = ref.read(authControllerProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_isLogin) {
      await authController.signIn(email: email, password: password);
    } else {
      final username = _usernameController.text.trim();
      final displayName = _displayNameController.text.trim();
      await authController.signUp(
        email: email,
        password: password,
        username: username,
        displayName: displayName.isEmpty ? null : displayName,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);

    InputDecoration inputDecoration({
      required String label,
      String? hint,
      IconData? icon,
      Widget? suffix,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFFFF1E7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFCC5C2E), Color(0xFFE0894E), Color(0xFFF0B36D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = constraints.maxHeight;
              final whiteHeight = screenHeight * 0.75;
              final headerHeight = screenHeight - whiteHeight;
              final logoHeight =
                  (headerHeight * 1.25).clamp(240.0, 360.0).toDouble();
              final logoTopOffset = -(logoHeight - headerHeight) * 0.35;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: double.infinity,
                          height: whiteHeight,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFFBF7),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(32),
                            ),
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    _isLogin ? 'Welcome Back!' : 'Create account',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _isLogin
                                        ? 'Sign in to catch campus updates and community posts.'
                                        : 'Join your campus community in seconds.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  if (!_isLogin) ...[
                                    TextFormField(
                                      controller: _displayNameController,
                                      textInputAction: TextInputAction.next,
                                      decoration: inputDecoration(
                                        label: 'Display name',
                                        hint: 'Ava Martinez',
                                        icon: Icons.badge_outlined,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _usernameController,
                                      textInputAction: TextInputAction.next,
                                      decoration: inputDecoration(
                                        label: 'Username',
                                        hint: 'campus_ava',
                                        icon: Icons.alternate_email,
                                      ),
                                      validator: (value) {
                                        if (_isLogin) return null;
                                        if (value == null || value.trim().length < 3) {
                                          return 'Username must be at least 3 characters.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    decoration: inputDecoration(
                                      label: 'Email',
                                      hint: 'you@qu.edu.qa',
                                      icon: Icons.email_outlined,
                                    ),
                                    validator: (value) {
                                      if (value == null || !value.contains('@')) {
                                        return 'Enter a valid email.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    decoration: inputDecoration(
                                      label: 'Password',
                                      icon: Icons.lock_outline,
                                      suffix: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.length < 6) {
                                        return 'Password must be at least 6 characters.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    height: 54,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFCC5C2E),
                                          Color(0xFFE07A3F),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFCC5C2E)
                                              .withOpacity(0.25),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: authState.isLoading ? null : _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                      child: authState.isLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                              ),
                                            )
                                          : Text(
                                              _isLogin ? 'Sign In' : 'Create account',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.4,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: authState.isLoading
                                        ? null
                                        : () {
                                            setState(() {
                                              _isLogin = !_isLogin;
                                            });
                                          },
                                    child: Text(
                                      _isLogin
                                          ? 'Need an account? Sign up'
                                          : 'Already have an account? Sign in',
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'By continuing, you agree to the campus community guidelines.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
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
                  Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: headerHeight,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              top: logoTopOffset,
                              left: 0,
                              right: 0,
                              child: UniHubLogo(
                                variant: UniHubLogoVariant.vertical,
                                height: logoHeight,
                                forceLight: true,
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 8,
                              child: Text(
                                'Connect with campus life',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
