import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/wallet_service.dart';
import '../models/car_model.dart';

class CarGarageService extends ChangeNotifier {
  static final CarGarageService instance = CarGarageService._internal();
  CarGarageService._internal();

  List<CarModel> _cars = [];
  String _selectedCarId = 'car_swift';

  List<CarModel> get allCars => List.unmodifiable(_cars);
  String get selectedCarId => _selectedCarId;

  CarModel get currentCar {
    return _cars.firstWhere(
      (c) => c.id == _selectedCarId,
      orElse: () => _cars.first,
    );
  }

  Future<void> init() async {
    _cars = List.from(CarModel.defaultFleet);

    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedCarId = prefs.getString('car_racing_selected_id') ?? 'car_swift';

      final savedJsonStr = prefs.getString('car_racing_garage_fleet');
      if (savedJsonStr != null) {
        final List<dynamic> list = jsonDecode(savedJsonStr);
        final Map<String, dynamic> savedMap = {
          for (final item in list) (item as Map<String, dynamic>)['id'] as String: item
        };

        _cars = CarModel.defaultFleet.map((preset) {
          if (savedMap.containsKey(preset.id)) {
            return CarModel.fromJson(savedMap[preset.id] as Map<String, dynamic>, preset);
          }
          return preset;
        }).toList();
      }
    } catch (e) {
      debugPrint('CarGarageService init error: $e');
    }
    notifyListeners();
  }

  Future<void> selectCar(String carId) async {
    final car = _cars.firstWhere((c) => c.id == carId, orElse: () => _cars.first);
    if (!car.isUnlocked) return;

    _selectedCarId = carId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('car_racing_selected_id', _selectedCarId);
    notifyListeners();
  }

  Future<bool> purchaseCar(String carId) async {
    final idx = _cars.indexWhere((c) => c.id == carId);
    if (idx == -1) return false;

    final target = _cars[idx];
    if (target.isUnlocked) return true;

    final wallet = WalletService.instance;
    if (wallet.gemsBalance < target.basePrice) {
      throw Exception('Insufficient Coins! You need ${target.basePrice} Coins to unlock ${target.name}.');
    }

    // Deduct coins
    await wallet.addGems(-target.basePrice, reason: 'Unlocked ${target.name}');

    _cars[idx] = target.copyWith(isUnlocked: true);
    _selectedCarId = carId;

    await _saveToStorage();
    notifyListeners();
    return true;
  }

  /// Upgrade costs: Level 2 = 1,500, Level 3 = 3,500, Level 4 = 7,000, Level 5 = 12,000
  int getUpgradeCost(int currentLevel) {
    switch (currentLevel) {
      case 1:
        return 1500;
      case 2:
        return 3500;
      case 3:
        return 7000;
      case 4:
        return 12000;
      default:
        return 999999;
    }
  }

  Future<bool> upgradeComponent({
    required String carId,
    required String component, // 'engine', 'brakes', 'tires', 'nitro'
  }) async {
    final idx = _cars.indexWhere((c) => c.id == carId);
    if (idx == -1) return false;

    final car = _cars[idx];
    int currentLvl = 1;

    switch (component) {
      case 'engine':
        currentLvl = car.engineLevel;
        break;
      case 'brakes':
        currentLvl = car.brakesLevel;
        break;
      case 'tires':
        currentLvl = car.tiresLevel;
        break;
      case 'nitro':
        currentLvl = car.nitroLevel;
        break;
    }

    if (currentLvl >= 5) {
      throw Exception('Maximum upgrade level already reached for $component!');
    }

    final cost = getUpgradeCost(currentLvl);
    final wallet = WalletService.instance;
    if (wallet.gemsBalance < cost) {
      throw Exception('Insufficient Coins! You need $cost Coins for this upgrade.');
    }

    await wallet.addGems(-cost, reason: 'Upgraded $component on ${car.name}');

    switch (component) {
      case 'engine':
        _cars[idx] = car.copyWith(engineLevel: currentLvl + 1);
        break;
      case 'brakes':
        _cars[idx] = car.copyWith(brakesLevel: currentLvl + 1);
        break;
      case 'tires':
        _cars[idx] = car.copyWith(tiresLevel: currentLvl + 1);
        break;
      case 'nitro':
        _cars[idx] = car.copyWith(nitroLevel: currentLvl + 1);
        break;
    }

    await _saveToStorage();
    notifyListeners();
    return true;
  }

  Future<void> updateCustomization({
    required String carId,
    Color? primaryColor,
    Color? underglowColor,
  }) async {
    final idx = _cars.indexWhere((c) => c.id == carId);
    if (idx == -1) return;

    _cars[idx] = _cars[idx].copyWith(
      primaryColor: primaryColor ?? _cars[idx].primaryColor,
      underglowColor: underglowColor ?? _cars[idx].underglowColor,
    );

    await _saveToStorage();
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('car_racing_selected_id', _selectedCarId);
      final jsonList = _cars.map((c) => c.toJson()).toList();
      await prefs.setString('car_racing_garage_fleet', jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Save garage error: $e');
    }
  }
}
