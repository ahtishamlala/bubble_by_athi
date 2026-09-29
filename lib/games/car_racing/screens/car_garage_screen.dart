import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/wallet_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/car_model.dart';
import '../services/car_garage_service.dart';

class CarGarageScreen extends StatefulWidget {
  const CarGarageScreen({super.key});

  @override
  State<CarGarageScreen> createState() => _CarGarageScreenState();
}

class _CarGarageScreenState extends State<CarGarageScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  final List<Color> _paintColors = [
    const Color(0xFF00E5FF), // Cyber Cyan
    const Color(0xFFFF2A6D), // Crimson Pink
    const Color(0xFFFFBE0B), // Electric Gold
    const Color(0xFF05FFA1), // Acid Green
    const Color(0xFFB5179E), // Royal Violet
    const Color(0xFF1E293B), // Stealth Carbon
    Colors.white,            // Pearl White
  ];

  @override
  void initState() {
    super.initState();
    final garage = CarGarageService.instance;
    final selectedIdx = garage.allCars.indexWhere((c) => c.id == garage.selectedCarId);
    _currentIndex = selectedIdx != -1 ? selectedIdx : 0;
    _pageController = PageController(initialPage: _currentIndex, viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([CarGarageService.instance, WalletService.instance]),
      builder: (context, _) {
        final garage = CarGarageService.instance;
        final wallet = WalletService.instance;
        final cars = garage.allCars;
        final activeCar = cars.isNotEmpty && _currentIndex < cars.length ? cars[_currentIndex] : garage.currentCar;

        return Scaffold(
          appBar: AppBar(
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.garage_rounded, color: AppTheme.neonCyan, size: 22),
                SizedBox(width: 8),
                Text('Cyber Garage & Tuning'),
              ],
            ),
            actions: [
              // Coins Balance Badge
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.neonGold, width: 1.2),
                ),
                child: Row(
                  children: [
                    const Text('🪙 ', style: TextStyle(fontSize: 13)),
                    Text(
                      '${wallet.gemsBalance} Coins',
                      style: const TextStyle(
                        color: AppTheme.neonGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                // 1. Vehicle Carousel Preview (3D Viewport)
                SizedBox(
                  height: 230,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: cars.length,
                    onPageChanged: (idx) {
                      setState(() => _currentIndex = idx);
                      HapticFeedback.selectionClick();
                      AudioService.instance.playClick();
                    },
                    itemBuilder: (context, idx) {
                      final car = cars[idx];
                      final isSelected = car.id == garage.selectedCarId;

                      return _buildCarShowcaseCard(car, isSelected);
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Vehicle Selector / Action Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildCarActionButton(activeCar, garage, wallet),
                ),

                const SizedBox(height: 20),

                // 2. Performance Specs & Stat Bars
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildPerformanceStatsCard(activeCar),
                ),

                const SizedBox(height: 20),

                // 3. Tuning & Performance Upgrades Shop
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildTuningShopCard(activeCar, garage),
                ),

                const SizedBox(height: 20),

                // 4. Customization (Paint Booth & Neon Underglow)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildCustomizationCard(activeCar, garage),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCarShowcaseCard(CarModel car, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSelected ? AppTheme.neonCyan : AppTheme.borderGlow,
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (isSelected ? car.primaryColor : Colors.black).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    car.name,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    car.category.name.toUpperCase(),
                    style: TextStyle(
                      color: car.primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.neonCyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.neonCyan),
                  ),
                  child: const Text('ACTIVE', style: TextStyle(color: AppTheme.neonCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const Spacer(),

          // Stylized Vehicle Illustration with Neon Glow
          Stack(
            alignment: Alignment.center,
            children: [
              // Underglow aura
              Container(
                width: 140,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: car.underglowColor.withValues(alpha: 0.4),
                  boxShadow: [
                    BoxShadow(color: car.underglowColor.withValues(alpha: 0.8), blurRadius: 28, spreadRadius: 4),
                  ],
                ),
              ),
              // Car Icon / Graphic representation
              Icon(
                Icons.directions_car_filled_rounded,
                size: 92,
                color: car.primaryColor,
              ),
            ],
          ),
          const Spacer(),

          Text(
            car.description,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCarActionButton(CarModel car, CarGarageService garage, WalletService wallet) {
    if (!car.isUnlocked) {
      final canAfford = wallet.gemsBalance >= car.basePrice;

      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: () async {
            try {
              await garage.purchaseCar(car.id);
              HapticFeedback.heavyImpact();
              AudioService.instance.playVictory();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🎉 ${car.name} unlocked successfully!'),
                    backgroundColor: AppTheme.neonGreen,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceAll('Exception: ', '')),
                    backgroundColor: AppTheme.neonPink,
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.lock_open_rounded, color: Colors.black, size: 20),
          label: Text(
            'UNLOCK FOR ${car.basePrice} COINS',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: canAfford ? AppTheme.neonGold : Colors.white24,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
    }

    final isSelected = car.id == garage.selectedCarId;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: isSelected ? null : () => garage.selectCar(car.id),
        icon: Icon(isSelected ? Icons.check_circle_rounded : Icons.drive_eta_rounded, size: 20),
        label: Text(
          isSelected ? 'SELECTED (ACTIVE VEHICLE)' : 'SELECT THIS CAR',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppTheme.cardDark : AppTheme.neonCyan,
          foregroundColor: isSelected ? Colors.white54 : Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildPerformanceStatsCard(CarModel car) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderGlow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PERFORMANCE SPECIFICATIONS',
            style: TextStyle(color: AppTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 14),

          _buildStatRow('Top Speed', '${car.currentTopSpeed.round()} km/h', car.currentTopSpeed / 360.0, AppTheme.neonCyan),
          const SizedBox(height: 10),
          _buildStatRow('Acceleration', '${(car.currentAcceleration * 10).round()}%', car.currentAcceleration / 12.0, AppTheme.neonGold),
          const SizedBox(height: 10),
          _buildStatRow('Handling / Grip', '${(car.currentHandling * 10).round()}%', car.currentHandling / 12.0, AppTheme.neonGreen),
          const SizedBox(height: 10),
          _buildStatRow('Braking Power', '${(car.currentBraking * 10).round()}%', car.currentBraking / 12.0, const Color(0xFFFF5252)),
          const SizedBox(height: 10),
          _buildStatRow('Nitro Output', 'x${car.currentNitroPower.toStringAsFixed(1)}', (car.currentNitroPower - 0.8) / 1.5, const Color(0xFF00E5FF)),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, double fraction, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.05, 1.0),
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildTuningShopCard(CarModel car, CarGarageService garage) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderGlow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PERFORMANCE TUNING SHOP',
                style: TextStyle(color: AppTheme.neonGold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              Text('Levels 1-5', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 14),

          _buildUpgradeTile(
            title: 'Engine & Turbocharger',
            subtitle: '+15 km/h Top Speed & Thrust',
            currentLevel: car.engineLevel,
            icon: Icons.speed_rounded,
            onUpgrade: () => _handleUpgrade(car, 'engine', garage),
          ),
          const Divider(color: Colors.white10, height: 20),

          _buildUpgradeTile(
            title: 'Brakes & Calipers',
            subtitle: '+Braking deceleration & stop power',
            currentLevel: car.brakesLevel,
            icon: Icons.disc_full_rounded,
            onUpgrade: () => _handleUpgrade(car, 'brakes', garage),
          ),
          const Divider(color: Colors.white10, height: 20),

          _buildUpgradeTile(
            title: 'Racing Tires & Suspension',
            subtitle: '+Cornering grip & drift control',
            currentLevel: car.tiresLevel,
            icon: Icons.tire_repair_rounded,
            onUpgrade: () => _handleUpgrade(car, 'tires', garage),
          ),
          const Divider(color: Colors.white10, height: 20),

          _buildUpgradeTile(
            title: 'Nitro NOS Injection',
            subtitle: '+Boost acceleration & capacity',
            currentLevel: car.nitroLevel,
            icon: Icons.local_fire_department_rounded,
            onUpgrade: () => _handleUpgrade(car, 'nitro', garage),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeTile({
    required String title,
    required String subtitle,
    required int currentLevel,
    required IconData icon,
    required VoidCallback onUpgrade,
  }) {
    final isMax = currentLevel >= 5;
    final cost = CarGarageService.instance.getUpgradeCost(currentLevel);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.backgroundDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.neonCyan, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 4),
              // Level Dots
              Row(
                children: List.generate(5, (idx) {
                  final filled = idx < currentLevel;
                  return Container(
                    margin: const EdgeInsets.only(right: 4),
                    width: 14,
                    height: 5,
                    decoration: BoxDecoration(
                      color: filled ? AppTheme.neonGreen : Colors.white12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: isMax ? null : onUpgrade,
          style: ElevatedButton.styleFrom(
            backgroundColor: isMax ? Colors.white12 : AppTheme.neonGreen,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            isMax ? 'MAX' : '$cost 🪙',
            style: TextStyle(
              color: isMax ? Colors.white38 : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  void _handleUpgrade(CarModel car, String component, CarGarageService garage) async {
    try {
      await garage.upgradeComponent(carId: car.id, component: component);
      HapticFeedback.mediumImpact();
      AudioService.instance.playMatch();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚡ ${component.toUpperCase()} upgraded successfully!'),
            backgroundColor: AppTheme.neonGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.neonPink,
          ),
        );
      }
    }
  }

  Widget _buildCustomizationCard(CarModel car, CarGarageService garage) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderGlow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CUSTOMIZATION & PAINT BOOTH',
            style: TextStyle(color: AppTheme.neonPink, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 14),

          // Primary Body Paint
          const Text('Primary Body Paint:', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _paintColors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, idx) {
                final color = _paintColors[idx];
                final isSelected = car.primaryColor.toARGB32() == color.toARGB32();

                return GestureDetector(
                  onTap: () {
                    garage.updateCustomization(carId: car.id, primaryColor: color);
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white24,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 10)]
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          // Neon Underglow Lighting
          const Text('Neon Underglow Lighting:', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _paintColors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, idx) {
                final color = _paintColors[idx];
                final isSelected = car.underglowColor.toARGB32() == color.toARGB32();

                return GestureDetector(
                  onTap: () {
                    garage.updateCustomization(carId: car.id, underglowColor: color);
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : color.withValues(alpha: 0.5),
                        width: isSelected ? 3 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
