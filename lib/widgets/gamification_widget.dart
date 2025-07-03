import 'package:flutter/material.dart';
import '../../models/data_schema.dart';

class GamificationWidget extends StatelessWidget {
  final UserModel user;

  const GamificationWidget({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Seção de gamificação com conquistas e pontuação',
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
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildPointsSection(context),
            const SizedBox(height: 16),
            _buildAchievements(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Semantics(
      label: 'Cabeçalho de conquistas',
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
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
                  'Suas Conquistas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Continue assim para desbloquear mais!',
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

  Widget _buildPointsSection(BuildContext context) {
    final level = _calculateLevel(user.points);
    final nextLevelPoints = _getNextLevelPoints(level);
    final progress = user.points % 100 / 100;

    return Semantics(
      label:
      'Você está no nível $level com ${user.points} pontos. Faltam ${nextLevelPoints - user.points} para o próximo nível.',
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
                  'Pontos Totais',
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
            _buildLevelBadge(context, level, progress),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelBadge(BuildContext context, int level, double progress) {
    return Semantics(
      label: 'Indicador de progresso do nível',
      hint: 'Progresso de ${(progress * 100).toStringAsFixed(0)}% para o nível $level',
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
            'Nível $level',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements(BuildContext context) {
    final achievements = _getAchievements();
    final unlockedAchievements = user.achievements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conquistas Desbloqueadas',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (unlockedAchievements.isEmpty)
          _buildEmptyAchievements(context)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: achievements.map((achievement) {
              final isUnlocked = unlockedAchievements.contains(achievement.id);
              return Semantics(
                label: '${achievement.name}. ${achievement.description}. ${isUnlocked ? 'Desbloqueada' : 'Bloqueada'}',
                child: _buildAchievementBadge(context, achievement, isUnlocked),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildEmptyAchievements(BuildContext context) {
    return Semantics(
      label: 'Nenhuma conquista desbloqueada',
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
                'Continue registrando suas transações para desbloquear conquistas!',
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
              achievement.name,
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

  List<Achievement> _getAchievements() {
    return [
      Achievement(
        id: 'first_transaction',
        name: 'Primeira Transação',
        description: 'Registrou sua primeira transação',
        icon: Icons.star,
      ),
      Achievement(
        id: 'budget_keeper',
        name: 'Controlador',
        description: 'Não ultrapassou o orçamento mensal',
        icon: Icons.shield,
      ),
      Achievement(
        id: 'consistent_user',
        name: 'Consistente',
        description: 'Registrou transações por 7 dias seguidos',
        icon: Icons.trending_up,
      ),
      Achievement(
        id: 'saver',
        name: 'Poupador',
        description: 'Teve mais receitas que despesas no mês',
        icon: Icons.savings,
      ),
    ];
  }
}

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
