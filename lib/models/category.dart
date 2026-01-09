import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final int iconCodePoint;
  final String? iconFontFamily;
  final String? iconFontPackage;
  final int colorValue;

  Category({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    this.iconFontFamily,
    this.iconFontPackage,
    required this.colorValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'iconFontFamily': iconFontFamily,
      'iconFontPackage': iconFontPackage,
      'colorValue': colorValue,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      iconCodePoint: map['iconCodePoint'],
      iconFontFamily: map['iconFontFamily'],
      iconFontPackage: map['iconFontPackage'],
      colorValue: map['colorValue'],
    );
  }

  static const Map<int, IconData> _supportedIcons = {
    0xe25a: Icons.fastfood,
    0xe1d5: Icons.directions_bus,
    0xe6e0: Icons.wifi,
    0xe3ab: Icons.lightbulb,
    0xe404: Icons.movie,
    0xe37f: Icons.local_hospital,
    0xe148: Icons.category,
  };

  IconData get iconData {
    return _supportedIcons[iconCodePoint] ?? Icons.category;
  }

  Color get color => Color(colorValue);
}
