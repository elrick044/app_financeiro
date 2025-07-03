import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../models/data_schema.dart';
import '../l10n/app_localizations.dart';
import 'home_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    // Obtenha a instância de AppLocalizations no método build
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: FocusTraversalGroup(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildHeader(l10n), // Passa l10n
                    const SizedBox(height: 48),
                    _buildAuthForm(l10n), // Passa l10n
                    const SizedBox(height: 24),
                    _buildGoogleSignInButton(l10n), // Passa l10n
                    const SizedBox(height: 24),
                    _buildToggleAuthMode(l10n), // Passa l10n
                    if (!_isLogin) ...[
                      const SizedBox(height: 16),
                      _buildForgotPassword(l10n), // Passa l10n
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Recebe l10n como parâmetro
  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      children: [
        Semantics(
          label: 'Logo da carteira FinanceFlow',
          image: true,
          child: Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet,
              size: 50,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'FinanceFlow', // Este pode ser um nome fixo ou vir de l10n.appName, dependendo de como você quer o logo
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin ? l10n.welcomeBack : l10n.createYourAccount, // Strings localizadas
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  // Recebe l10n como parâmetro
  Widget _buildAuthForm(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (!_isLogin) ...[
            _buildTextField(
              controller: _nameController,
              label: l10n.fullName, // String localizada
              icon: Icons.person,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.nameRequired; // String localizada
                }
                if (value.trim().length < 2) {
                  return l10n.nameMinLength; // String localizada
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
          _buildTextField(
            controller: _emailController,
            label: l10n.email, // String localizada
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.emailRequired; // String localizada
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            label: l10n.password, // String localizada
            icon: Icons.lock,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                semanticLabel:
                _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.passwordRequired; // String localizada
              }
              if (!_isLogin && value.length < 6) {
                return l10n.passwordMinLength; // String localizada
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildSubmitButton(l10n), // Passa l10n
        ],
      ),
    );
  }

  // Este método não precisa de l10n pois ele não usa strings literais
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    List<String>? autofillHints,
    TextInputAction? textInputAction,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  // Recebe l10n como parâmetro
  Widget _buildSubmitButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _handleSubmit(l10n), // Passa l10n para _handleSubmit
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.onPrimary,
        )
            : Text(
          _isLogin ? l10n.loginButton : l10n.createAccountButton, // Strings localizadas
          semanticsLabel:
          _isLogin ? l10n.loginButton : l10n.createAccountButton, // Strings localizadas
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton(AppLocalizations l10n) {
    return Semantics(
      label: l10n.continueWithGoogle,
      button: true,
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _isLoading ? null : () => _handleGoogleSignIn(l10n), // Passa l10n para _handleGoogleSignIn
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          icon: Icon(
            Icons.g_mobiledata,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          label: Text(
            l10n.continueWithGoogle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // Recebe l10n como parâmetro
  Widget _buildToggleAuthMode(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? l10n.noAccountQuestion : l10n.alreadyHaveAccountQuestion, // Strings localizadas
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(0.7),
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _isLogin = !_isLogin;
            });
          },
          child: Text(
            _isLogin ? l10n.createAccountLink : l10n.loginLink, // Strings localizadas
            semanticsLabel: _isLogin ? l10n.createAccountLink : l10n.loginLink,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Recebe l10n como parâmetro
  Widget _buildForgotPassword(AppLocalizations l10n) {
    return TextButton(
      onPressed: () => _handleForgotPassword(l10n), // Passa l10n
      child: Text(
        l10n.forgotPassword,
        semanticsLabel: l10n.forgotPassword,// String localizada
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Recebe l10n como parâmetro para mensagens de erro/sucesso
  Future<void> _handleSubmit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserModel? user;

      if (_isLogin) {
        user = await _firebaseService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        user = await _firebaseService.createUserWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
      }

      if (user != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isLogin
                  ? '${l10n.signInError}${e.toString()}' // String localizada com erro
                  : '${l10n.signUpError}${e.toString()}', // String localizada com erro
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Recebe l10n como parâmetro para mensagens de erro
  Future<void> _handleGoogleSignIn(AppLocalizations l10n) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _firebaseService.signInWithGoogle();

      if (user != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.googleSignInError}${e.toString()}'), // String localizada com erro
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Recebe l10n como parâmetro para mensagens
  Future<void> _handleForgotPassword(AppLocalizations l10n) async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.enterEmailForPasswordRecovery), // String localizada
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    try {
      await _firebaseService.resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.recoveryEmailSent), // String localizada
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.passwordResetError}${e.toString()}'), // String localizada com erro
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
