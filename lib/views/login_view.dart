import 'package:flutter/material.dart';
import '../services/push_notification_service.dart';
import '../theme/app_theme.dart';
import 'home_view.dart';
import '../viewmodels/login_viewmodel.dart';
import '../main.dart';

class LoginView extends StatefulWidget {
  final LoginViewModel viewModel;

  const LoginView({super.key, required this.viewModel});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Bind controllers to viewmodel setters
    _emailController.addListener(() {
      widget.viewModel.setEmail(_emailController.text);
    });
    _passwordController.addListener(() {
      widget.viewModel.setPassword(_passwordController.text);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    final success = await widget.viewModel.login();
    final user = widget.viewModel.currentUser;

    if (success && user != null) {
      await PushNotificationService.instance.registerTokenForUser(user.id);
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeView(
            user: user,
            onLogout: () {
              PushNotificationService.instance.clearCurrentUser();
              widget.viewModel.reset();
              navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => LoginView(viewModel: widget.viewModel),
                ),
                (route) => false,
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Graphic
                Container(
                  height: size.height * 0.4,
                  decoration: const BoxDecoration(
                    color: AppColors.brandBlack,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                    child: Image.asset('assets/attij-2.jpg', fit: BoxFit.cover),
                  ),
                ),

                // Form Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Form Header
                      const Text(
                        'Se connecter',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandBlack,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Veuillez entrer vos identifiants pour continuer.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Error message container if present
                      if (widget.viewModel.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.error.withAlpha(50),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.viewModel.errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Email input field
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        enabled: !widget.viewModel.isLoading,
                        decoration: const InputDecoration(
                          labelText: 'Adresse e-mail',
                          hintText: 'exemple@attijari.tn',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password input field
                      TextField(
                        controller: _passwordController,
                        obscureText: !widget.viewModel.isPasswordVisible,
                        textInputAction: TextInputAction.done,
                        enabled: !widget.viewModel.isLoading,
                        onSubmitted: (_) => _handleLogin(),
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          hintText: '••••••••',
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColors.textLight,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              widget.viewModel.isPasswordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textLight,
                            ),
                            onPressed: widget.viewModel.isLoading
                                ? null
                                : () => widget.viewModel
                                      .togglePasswordVisibility(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Forgot Password Link
                      const SizedBox(height: 32),

                      // Login Button
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: AppColors.brandGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryRed.withAlpha(80),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: widget.viewModel.isLoading
                              ? null
                              : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: widget.viewModel.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'SE CONNECTER',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Create Account Prompt
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "En cas de problème d'authentification ? ",
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: widget.viewModel.isLoading
                                ? null
                                : () {},
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.secondaryOrange,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Contactez-nous',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
