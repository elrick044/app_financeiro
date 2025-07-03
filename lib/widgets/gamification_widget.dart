import 'package:flutter/material.dart';
import '../../models/data_schema.dart';
// Importa a classe de localizações gerada

import '../l10n/app_localizations.dart';

class GamificationWidget extends StatelessWidget {
  final UserModel user;

  const GamificationWidget({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    // Obtenha a instância de AppLocalizations no método build
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      container: true,
      label: l10n.yourAchievements, // Usando string localizada
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.tertiary.withOpacity(0.8),
              Theme.of(context).colorScheme.tertiary,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, l10n), // Passa l10n
            const SizedBox(height: 16),
            _buildPointsSection(context, l10n), // Passa l10n
            const SizedBox(height: 16),
            _buildAchievements(context, l10n), // Passa l10n
          ],
        ),
      ),
    );
  }

  // Recebe l10n
  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Semantics(
      label: l10n.yourAchievements, // Usando string localizada
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon( // Changed to const Icon as properties are fixed
                Icons.emoji_events,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.yourAchievements, // Usando string localizada
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  l10n.keepGoingToUnlockMore, // Usando string localizada
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Recebe l10n
  Widget _buildPointsSection(BuildContext context, AppLocalizations l10n) {
    final level = _calculateLevel(user.points);
    final nextLevelPoints = _getNextLevelPoints(level);
    final progress = user.points % 100 / 100;

    return Semantics(
      label: l10n.levelInfo( level,  user.points,  nextLevelPoints - user.points), // String localizada com placeholders
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.totalPoints, // Usando string localizada
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.points}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            _buildLevelBadge(context, level, progress, l10n), // Passa l10n
          ],
        ),
      ),
    );
  }

  // Recebe l10n
  Widget _buildLevelBadge(BuildContext context, int level, double progress, AppLocalizations l10n) {
    return Semantics(
      label: l10n.levelProgressInfo( (progress * 100).toStringAsFixed(0),  level), // String localizada com placeholders
      hint: l10n.levelProgressInfo( (progress * 100).toStringAsFixed(0),  level), // Usando string localizada
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$level',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.level(level), // String localizada com placeholder
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Recebe l10n
  Widget _buildAchievements(BuildContext context, AppLocalizations l10n) {
    final achievements = _getAchievements(l10n); // Passa l10n para obter conquistas localizadas
    final unlockedAchievements = user.achievements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.unlockedAchievements, // Usando string localizada
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (unlockedAchievements.isEmpty)
          _buildEmptyAchievements(context, l10n) // Passa l10n
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: achievements.map((achievement) {
              final isUnlocked = unlockedAchievements.contains(achievement.id);
              return Semantics(
                label: isUnlocked
                    ? l10n.achievementUnlockedStatus(achievement.name, achievement.description) // String localizada com placeholder
                    : l10n.achievementLockedStatus(achievement.name, achievement.description), // String localizada com placeholder
                child: _buildAchievementBadge(context, achievement, isUnlocked),
              );
            }).toList(),
          ),
      ],
    );
  }

  // Recebe l10n
  Widget _buildEmptyAchievements(BuildContext context, AppLocalizations l10n) {
    return Semantics(
      label: l10n.noAchievementsYet, // Usando string localizada
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.lock_outline,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.noAchievementsYet, // Usando string localizada
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementBadge(
      BuildContext context, Achievement achievement, bool isUnlocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isUnlocked
            ? Colors.white.withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked
              ? Colors.white.withOpacity(0.4)
              : Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(
              achievement.icon,
              color: isUnlocked ? Colors.white : Colors.white.withOpacity(0.5),
              size: 16,
            ),
          ),
          const SizedBox(width: 6),
          ExcludeSemantics(
            child: Text(
              achievement.name, // O nome da conquista já vem localizado do _getAchievements
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isUnlocked ? Colors.white : Colors.white.withOpacity(0.7),
                fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateLevel(int points) {
    return (points / 100).floor() + 1;
  }

  int _getNextLevelPoints(int level) {
    return level * 100;
  }

  // Agora recebe l10n para criar Achievements com nomes e descrições localizadas
  List<Achievement> _getAchievements(AppLocalizations l10n) {
    return [
      Achievement(
        id: 'first_transaction',
        name: l10n.achievementFirstTransactionName,
        description: l10n.achievementFirstTransactionDescription,
        icon: Icons.star,
      ),
      Achievement(
        id: 'budget_keeper',
        name: l10n.achievementBudgetKeeperName,
        description: l10n.achievementBudgetKeeperDescription,
        icon: Icons.shield,
      ),
      Achievement(
        id: 'consistent_user',
        name: l10n.achievementConsistentUserName,
        description: l10n.achievementConsistentUserDescription,
        icon: Icons.trending_up,
      ),
      Achievement(
        id: 'saver',
        name: l10n.achievementSaverName,
        description: l10n.achievementSaverDescription,
        icon: Icons.savings,
      ),
    ];
  }
}

// A classe Achievement não precisa ser alterada, pois agora ela recebe
// strings já localizadas através do construtor.
class Achievement {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}