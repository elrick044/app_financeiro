import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'theme.dart';
import 'pages/onboarding_page.dart';
import 'pages/auth_page.dart';
import 'pages/home_page.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // await Firebase.initializeApp(
  //   options: const FirebaseOptions(
  //     apiKey: "demo-api-key",
  //     authDomain: "demo-project.firebaseapp.com",
  //     projectId: "demo-project",
  //     storageBucket: "demo-project.appspot.com",
  //     messagingSenderId: "123456789",
  //     appId: "1:123456789:web:demo-app-id",
  //   ),
  // );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const FinanceFlowApp());
}

class FinanceFlowApp extends StatelessWidget {
  const FinanceFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinanceFlow',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        AppLocalizations.delegate, // O delegado gerado a partir dos seus arquivos .arb
        GlobalMaterialLocalizations.delegate, // Para widgets do Material Design
        GlobalWidgetsLocalizations.delegate,  // Para widgets genéricos
        GlobalCupertinoLocalizations.delegate, // Para widgets do estilo iOS (se usar)
      ],

      supportedLocales: const [
        Locale('en'), // Inglês
        //Locale('es'), // Espanhol
        Locale('pt'), // Português
        // Adicione outros Locales que você tiver arquivos .arb
      ],

      locale: const Locale('en'),

      home: const AppWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  bool _hasSeenOnboarding = false;
  bool _isAuthenticated = false;//mudar para true

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    try {
      // Check if user has seen onboarding
      final prefs = await SharedPreferences.getInstance();
      _hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

      // Check authentication state
      final currentUser = _firebaseService.currentUser;
      _isAuthenticated = currentUser != null;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'FinanceFlow',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const CircularProgressIndicator(
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Navigation logic
    if (!_hasSeenOnboarding) {
      return const OnboardingPage();
    } else if (!_isAuthenticated) {
      return const AuthPage();
    } else {
      return const HomePage();
    }
  }
}