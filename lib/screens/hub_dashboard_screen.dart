import 'package:flutter/material.dart';
import '../ad_manager.dart';
import '../banner_ad_widget.dart';
import '../core/services/arcade_hub_service.dart';
import '../core/services/auth_service.dart';
import '../core/services/wallet_service.dart';
import '../core/theme/app_theme.dart';
import '../games/block_puzzle/block_puzzle_screen.dart';
import '../games/knife_hit/knife_hit_screen.dart';
import '../games/match3_candy/match3_screen.dart';
import '../games/memory_matrix/memory_matrix_screen.dart';
import '../games/merge_2048/merge_2048_screen.dart';
import '../models/game_stat.dart';
import 'compliance_screen.dart';
import 'game_screen.dart';
import 'profile_screen.dart';
import 'referral_screen.dart';
import 'wallet_screen.dart';

class HubDashboardScreen extends StatefulWidget {
  const HubDashboardScreen({super.key});

  @override
  State<HubDashboardScreen> createState() => _HubDashboardScreenState();
}

class _HubDashboardScreenState extends State<HubDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Show App Open Ad on cold start after brief delay for smooth UI mounting
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        AdManager.instance.showAppOpenAd(waitForLoad: true);
      }
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _launchGame(String gameId, int level) {
    Widget screen;
    switch (gameId) {
      case 'bubble_shooter':
        screen = GameScreen(levelNumber: level);
        break;
      case 'block_puzzle':
        screen = BlockPuzzleScreen(levelNumber: level);
        break;
      case 'match3_candy':
        screen = Match3Screen(levelNumber: level);
        break;
      case 'merge_2048':
        screen = Merge2048Screen(levelNumber: level);
        break;
      case 'memory_matrix':
        screen = MemoryMatrixScreen(levelNumber: level);
        break;
      case 'knife_hit':
        screen = KnifeHitScreen(levelNumber: level);
        break;
      default:
        screen = GameScreen(levelNumber: level);
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _showLevelSelectDialog(GameStat game) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(game.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    '${game.title} (40 Levels)',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: 40,
                  itemBuilder: (context, i) {
                    final lvl = i + 1;
                    final isUnlocked = lvl <= game.unlockedLevel;
                    final stars = game.starsPerLevel[lvl] ?? 0;

                    return GestureDetector(
                      onTap: isUnlocked
                          ? () {
                              Navigator.of(context).pop();
                              _launchGame(game.id, lvl);
                            }
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isUnlocked ? AppTheme.cardDark : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isUnlocked ? AppTheme.neonCyan : Colors.white10,
                            width: isUnlocked ? 1.5 : 1,
                          ),
                          boxShadow: isUnlocked
                              ? [
                                  BoxShadow(
                                    color: AppTheme.neonCyan.withValues(alpha: 0.2),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!isUnlocked)
                              const Icon(Icons.lock_rounded, color: Colors.white24, size: 20)
                            else ...[
                              Text(
                                '$lvl',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (stars > 0)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    stars,
                                    (_) => const Icon(Icons.star_rounded, color: AppTheme.neonGold, size: 10),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ArcadeHubService.instance,
        WalletService.instance,
        AuthService.instance,
      ]),
      builder: (context, _) {
        final hub = ArcadeHubService.instance;
        final wallet = WalletService.instance;
        final games = hub.allGames;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top Navigation Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        // App Logo & Title
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ProfileScreen()),
                            );
                          },
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  width: 38,
                                  height: 38,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.gamepad_rounded, color: AppTheme.neonCyan, size: 32),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'IKRAM',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  Text(
                                    'ARCADE HUB',
                                    style: TextStyle(
                                      color: AppTheme.neonCyan,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Gems & USDT Pill (Tapping opens Wallet)
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const WalletScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.cardDark,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.neonGold, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.neonGold.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Text('💎', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                Text(
                                  '${wallet.gemsBalance}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(\$${wallet.usdtEquivalent.toStringAsFixed(2)})',
                                  style: const TextStyle(
                                    color: AppTheme.neonGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Legal & Compliance Shield 🛡️
                        IconButton.filledTonal(
                          icon: const Icon(Icons.shield_rounded, color: AppTheme.neonCyan, size: 20),
                          tooltip: 'Legal & Policy Center',
                          style: IconButton.styleFrom(backgroundColor: AppTheme.cardDark),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ComplianceScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Quick Action Hub Bar (Invite & Earn / Free Gems / Wallet)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        // Free Gems via Rewarded Ad
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              AdManager.instance.showRewardedAd(
                                context: context,
                                onUserEarnedReward: (_) {
                                  wallet.addGems(50, reason: 'Rewarded Ad Bonus');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('🎉 +50 Free Gems added to your wallet!'),
                                        backgroundColor: AppTheme.neonGreen,
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.cardDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.5)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.video_library_rounded, color: AppTheme.neonCyan, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    '+50 GEMS 🎬',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Invite & Earn
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ReferralScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.cardDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.neonGold.withValues(alpha: 0.5)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.card_giftcard_rounded, color: AppTheme.neonGold, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'INVITE & EARN',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Header Section Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '6-IN-1 ARCADE ARENA (240 LEVELS)',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          '⭐ ${hub.totalStarsEarned} Stars',
                          style: const TextStyle(
                            color: AppTheme.neonGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Games Grid
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: games.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final game = games[i];

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderGlow),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Game Icon Badge
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.6)),
                                ),
                                child: Center(
                                  child: Text(game.icon, style: const TextStyle(fontSize: 28)),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      game.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      game.description,
                                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.neonCyan.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Level ${game.unlockedLevel} / 40',
                                            style: const TextStyle(color: AppTheme.neonCyan, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '⭐ ${game.totalStars} Stars',
                                          style: const TextStyle(color: AppTheme.neonGold, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Action Buttons
                              Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _launchGame(game.id, game.unlockedLevel),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.neonCyan,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      minimumSize: Size.zero,
                                    ),
                                    child: const Text('PLAY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(height: 4),
                                  TextButton(
                                    onPressed: () => _showLevelSelectDialog(game),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text('Levels', style: TextStyle(color: Colors.white54, fontSize: 11)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom AdMob Banner
                  const SafeArea(top: false, child: BannerAdWidget()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
