import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../global_forest/data/services/feed_preferences.dart';
import '../../../global_forest/presentation/pages/create_post_page.dart';
import '../../../global_forest/presentation/pages/global_forest_page.dart';
import '../../data/services/earned_trees.dart';

/// Parabéns depois de conquistar uma árvore pessoal: convida a comemorar no
/// feed global (a árvore já está lá, com ou sem post) e a ligar o opt-in
/// "me avise quando alguém plantar".
class TreeCelebrationPage extends StatefulWidget {
  const TreeCelebrationPage({super.key, required this.tree});

  final EarnedTree tree;

  @override
  State<TreeCelebrationPage> createState() => _TreeCelebrationPageState();
}

class _TreeCelebrationPageState extends State<TreeCelebrationPage>
    with SingleTickerProviderStateMixin {
  final FeedPreferences _preferences = FeedPreferences();
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  bool _feedUpdates = false;

  @override
  void initState() {
    super.initState();
    _preferences.feedUpdatesEnabled().then((enabled) {
      if (mounted) setState(() => _feedUpdates = enabled);
    });
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  Future<void> _toggleFeedUpdates(bool enabled) async {
    setState(() => _feedUpdates = enabled);
    await _preferences.setFeedUpdates(enabled);
  }

  Future<void> _celebrate() async {
    final orderId = widget.tree.orderId;
    if (orderId == null) return;
    final posted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreatePostPage(
          itemId: orderId,
          treeNumber: widget.tree.treeNumber,
        ),
      ),
    );
    if (posted != true || !mounted) return;
    // Publicou: mostra o post no feed, no topo.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GlobalForestPage(highlightItemId: orderId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tree = widget.tree;
    final where = [tree.speciesName, tree.country]
        .where((s) => s.isNotEmpty)
        .join(' · ');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ScaleTransition(
                scale: CurvedAnimation(parent: _pop, curve: Curves.elasticOut),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0B7A35), Color(0xFF43A047)],
                    ),
                  ),
                  child: Center(
                    child: FaIcon(
                      tree.isPlanted
                          ? FontAwesomeIcons.tree
                          : FontAwesomeIcons.seedling,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                tree.treeNumber > 0
                    ? l10n.celebrationTitle(tree.treeNumber)
                    : l10n.celebrationTitleNoNumber,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                tree.isPlanted
                    ? (where.isEmpty
                          ? l10n.celebrationPlantedBody
                          : l10n.celebrationPlantedBodyWhere(where))
                    : l10n.celebrationPendingBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.earthAmericas,
                      color: AppColors.primaryDark,
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        l10n.celebrationInFeed,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SwitchListTile(
                  value: _feedUpdates,
                  onChanged: _toggleFeedUpdates,
                  activeTrackColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  title: Text(
                    l10n.feedUpdatesOptInTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    l10n.feedUpdatesOptInBody,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              if (tree.orderId != null)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _celebrate,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const FaIcon(
                      FontAwesomeIcons.champagneGlasses,
                      size: 16,
                    ),
                    label: Text(
                      l10n.celebrationShareButton,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  l10n.celebrationNotNow,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
