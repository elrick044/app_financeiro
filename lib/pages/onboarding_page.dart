import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'auth_page.dart';
// Import AppLocalizations for internationalization

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Use string keys for title and description to fetch localized text
  final List<OnboardingItem> _onboardingItems = [
    OnboardingItem(
      titleKey: 'onboardingTitle1', // Key from .arb file
      descriptionKey: 'onboardingDescription1', // Key from .arb file
      icon: Icons.account_balance_wallet,
      color: const Color(0xFF6F61EF),
    ),
    OnboardingItem(
      titleKey: 'onboardingTitle2',
      descriptionKey: 'onboardingDescription2',
      icon: Icons.analytics,
      color: const Color(0xFF39D2C0),
    ),
    OnboardingItem(
      titleKey: 'onboardingTitle3',
      descriptionKey: 'onboardingDescription3',
      icon: Icons.emoji_events,
      color: const Color(0xFFEE8B60),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Get the AppLocalizations instance to access translated strings
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
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _onboardingItems.length,
                  itemBuilder: (context, index) {
                    // Pass l10n to the build method for localized content
                    return _buildOnboardingPage(_onboardingItems[index], l10n);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildPageIndicator(),
                    const SizedBox(height: 32),
                    // Pass l10n to the build method for localized button texts
                    _buildBottomButtons(l10n),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Now accepts AppLocalizations l10n to get localized strings
  Widget _buildOnboardingPage(OnboardingItem item, AppLocalizations l10n) {
    return Semantics(
      container: true,
      // Use resolved strings for Semantics labels
      label: 'Tela de onboarding: ${_resolveOnboardingTitle(item.titleKey, l10n)}',
      hint: _resolveOnboardingDescription(item.descriptionKey, l10n),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              label: 'Ícone representando: ${_resolveOnboardingTitle(item.titleKey, l10n)}',
              child: Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  size: 80,
                  color: item.color,
                ),
              ),
            ),
            const SizedBox(height: 48),
            ExcludeSemantics(
              child: Text(
                // Get localized title using the key
                _resolveOnboardingTitle(item.titleKey, l10n),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ExcludeSemantics(
              child: Text(
                // Get localized description using the key
                _resolveOnboardingDescription(item.descriptionKey, l10n),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper functions to resolve the localized strings based on their keys
  String _resolveOnboardingTitle(String key, AppLocalizations l10n) {
    switch (key) {
      case 'onboardingTitle1': return l10n.onboardingTitle1;
      case 'onboardingTitle2': return l10n.onboardingTitle2;
      case 'onboardingTitle3': return l10n.onboardingTitle3;
      default: return ''; // Fallback for any missing keys
    }
  }

  String _resolveOnboardingDescription(String key, AppLocalizations l10n) {
    switch (key) {
      case 'onboardingDescription1': return l10n.onboardingDescription1;
      case 'onboardingDescription2': return l10n.onboardingDescription2;
      case 'onboardingDescription3': return l10n.onboardingDescription3;
      default: return ''; // Fallback for any missing keys
    }
  }

  Widget _buildPageIndicator() {
    return Semantics(
      label: 'Indicador de página ${_currentPage + 1} de ${_onboardingItems.length}',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _onboardingItems.length,
              (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: _currentPage == index ? 24 : 8,
            decoration: BoxDecoration(
              color: _currentPage == index
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.primary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  // Now accepts AppLocalizations l10n to get localized button texts
  Widget _buildBottomButtons(AppLocalizations l10n) {
    return Row(
      children: [
        if (_currentPage > 0)
          Expanded(
            child: Semantics(
              button: true,
              label: l10n.previousButton, // Use localized text for Semantics
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                child: Text(
                  l10n.previousButton, // Localized text
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        if (_currentPage > 0) const SizedBox(width: 16),
        Expanded(
          child: Semantics(
            button: true,
            label: _currentPage == _onboardingItems.length - 1
                ? l10n.getStartedButton // Localized text for Semantics
                : l10n.nextButton, // Localized text for Semantics
            child: ElevatedButton(
              onPressed: _currentPage == _onboardingItems.length - 1
                  ? _finishOnboarding
                  : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                _currentPage == _onboardingItems.length - 1
                    ? l10n.getStartedButton // Localized text
                    : l10n.nextButton, // Localized text
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthPage()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// Updated OnboardingItem to use string keys for internationalization
class OnboardingItem {
  final String titleKey; // Now a key
  final String descriptionKey; // Now a key
  final IconData icon;
  final Color color;

  OnboardingItem({
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
    required this.color,
  });
}