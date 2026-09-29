import 'package:flutter/material.dart';

enum VehicleCategory {
  starter,
  muscle,
  suv,
  supercar,
  hypercar,
}

enum TrackType {
  cityHighway,
  mountainRidge,
  desertDunes,
}

enum WeatherType {
  sunny,
  rainy,
  night,
}

enum CarGameMode {
  career,
  endless,
  timeAttack,
  freeRide,
}

enum CameraView {
  thirdPerson,
  hood,
  cockpit,
}

class CarModel {
  final String id;
  final String name;
  final String description;
  final VehicleCategory category;
  final int basePrice;
  final bool isUnlocked;
  final Color primaryColor;
  final Color underglowColor;
  final int engineLevel; // 1-5
  final int brakesLevel; // 1-5
  final int tiresLevel; // 1-5
  final int nitroLevel; // 1-5

  // Base Stats (1.0 to 10.0 scale)
  final double baseTopSpeed; // in km/h
  final double baseAcceleration; // 0-100 thrust
  final double baseHandling; // grip & steer response
  final double baseBraking; // stopping power
  final double baseDurability; // crash resistance

  const CarModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.basePrice,
    this.isUnlocked = false,
    this.primaryColor = const Color(0xFF00F0FF),
    this.underglowColor = const Color(0xFF00F0FF),
    this.engineLevel = 1,
    this.brakesLevel = 1,
    this.tiresLevel = 1,
    this.nitroLevel = 1,
    required this.baseTopSpeed,
    required this.baseAcceleration,
    required this.baseHandling,
    required this.baseBraking,
    required this.baseDurability,
  });

  // Upgraded Stats
  double get currentTopSpeed => baseTopSpeed + ((engineLevel - 1) * 15.0);
  double get currentAcceleration => baseAcceleration + ((engineLevel - 1) * 0.8);
  double get currentHandling => baseHandling + ((tiresLevel - 1) * 0.7);
  double get currentBraking => baseBraking + ((brakesLevel - 1) * 0.9);
  double get currentNitroPower => 1.0 + ((nitroLevel - 1) * 0.25);

  CarModel copyWith({
    String? id,
    String? name,
    String? description,
    VehicleCategory? category,
    int? basePrice,
    bool? isUnlocked,
    Color? primaryColor,
    Color? underglowColor,
    int? engineLevel,
    int? brakesLevel,
    int? tiresLevel,
    int? nitroLevel,
    double? baseTopSpeed,
    double? baseAcceleration,
    double? baseHandling,
    double? baseBraking,
    double? baseDurability,
  }) {
    return CarModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      basePrice: basePrice ?? this.basePrice,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      primaryColor: primaryColor ?? this.primaryColor,
      underglowColor: underglowColor ?? this.underglowColor,
      engineLevel: engineLevel ?? this.engineLevel,
      brakesLevel: brakesLevel ?? this.brakesLevel,
      tiresLevel: tiresLevel ?? this.tiresLevel,
      nitroLevel: nitroLevel ?? this.nitroLevel,
      baseTopSpeed: baseTopSpeed ?? this.baseTopSpeed,
      baseAcceleration: baseAcceleration ?? this.baseAcceleration,
      baseHandling: baseHandling ?? this.baseHandling,
      baseBraking: baseBraking ?? this.baseBraking,
      baseDurability: baseDurability ?? this.baseDurability,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isUnlocked': isUnlocked,
      'primaryColor': primaryColor.toARGB32(),
      'underglowColor': underglowColor.toARGB32(),
      'engineLevel': engineLevel,
      'brakesLevel': brakesLevel,
      'tiresLevel': tiresLevel,
      'nitroLevel': nitroLevel,
    };
  }

  static CarModel fromJson(Map<String, dynamic> json, CarModel basePreset) {
    return basePreset.copyWith(
      isUnlocked: json['isUnlocked'] as bool? ?? basePreset.isUnlocked,
      primaryColor: json['primaryColor'] != null
          ? Color(json['primaryColor'] as int)
          : basePreset.primaryColor,
      underglowColor: json['underglowColor'] != null
          ? Color(json['underglowColor'] as int)
          : basePreset.underglowColor,
      engineLevel: json['engineLevel'] as int? ?? basePreset.engineLevel,
      brakesLevel: json['brakesLevel'] as int? ?? basePreset.brakesLevel,
      tiresLevel: json['tiresLevel'] as int? ?? basePreset.tiresLevel,
      nitroLevel: json['nitroLevel'] as int? ?? basePreset.nitroLevel,
    );
  }

  // 5 Master Preset Vehicles
  static final List<CarModel> defaultFleet = [
    // 1. Starter Hatchback (Mehran / Civic Style)
    const CarModel(
      id: 'car_swift',
      name: 'Swift City Turbo',
      description: 'Nimble starter hatchback, agile in tight city traffic with balanced fuel efficiency.',
      category: VehicleCategory.starter,
      basePrice: 0,
      isUnlocked: true,
      primaryColor: Color(0xFF00E5FF),
      underglowColor: Color(0xFF00E5FF),
      baseTopSpeed: 160.0,
      baseAcceleration: 5.5,
      baseHandling: 7.5,
      baseBraking: 6.0,
      baseDurability: 6.5,
    ),

    // 2. American Muscle (Mustang V8 Style)
    const CarModel(
      id: 'car_v8_muscle',
      name: 'Apex V8 Muscle',
      description: 'Roaring muscle brute with massive torque, aggressive throttle drift, and raw horsepower.',
      category: VehicleCategory.muscle,
      basePrice: 10000,
      isUnlocked: false,
      primaryColor: Color(0xFFFF2A6D),
      underglowColor: Color(0xFFFF2A6D),
      baseTopSpeed: 220.0,
      baseAcceleration: 7.2,
      baseHandling: 6.2,
      baseBraking: 6.8,
      baseDurability: 7.8,
    ),

    // 3. Heavy 4x4 Off-Road Cruiser (Land Cruiser / Jeep Style)
    const CarModel(
      id: 'car_sahara_4x4',
      name: 'Titan 4x4 Cruiser',
      description: 'Heavy armored suspension, immune to minor road bumps with supreme road stability.',
      category: VehicleCategory.suv,
      basePrice: 25000,
      isUnlocked: false,
      primaryColor: Color(0xFFFFBE0B),
      underglowColor: Color(0xFFFFBE0B),
      baseTopSpeed: 195.0,
      baseAcceleration: 6.0,
      baseHandling: 7.0,
      baseBraking: 8.2,
      baseDurability: 9.5,
    ),

    // 4. Aerodynamic Supercar (Lamborghini Style)
    const CarModel(
      id: 'car_veneno_gt',
      name: 'Veneno GT Aero',
      description: 'Low-slung supercar with razor-sharp carbon aerodynamics and instantaneous acceleration.',
      category: VehicleCategory.supercar,
      basePrice: 50000,
      isUnlocked: false,
      primaryColor: Color(0xFF05FFA1),
      underglowColor: Color(0xFF05FFA1),
      baseTopSpeed: 280.0,
      baseAcceleration: 8.8,
      baseHandling: 8.6,
      baseBraking: 8.5,
      baseDurability: 6.0,
    ),

    // 5. Ultimate Hypercar (Bugatti / Phantom Style)
    const CarModel(
      id: 'car_phantom_hyper',
      name: 'Phantom Hyper-X',
      description: 'Quad-turbo hypercar masterpiece delivering 340+ km/h top speeds and supreme nitro drive.',
      category: VehicleCategory.hypercar,
      basePrice: 100000,
      isUnlocked: false,
      primaryColor: Color(0xFFB5179E),
      underglowColor: Color(0xFFB5179E),
      baseTopSpeed: 340.0,
      baseAcceleration: 9.8,
      baseHandling: 9.4,
      baseBraking: 9.5,
      baseDurability: 7.5,
    ),
  ];
}
