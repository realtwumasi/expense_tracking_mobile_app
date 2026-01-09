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

  static Map<int, IconData> get _supportedIcons => {
    Icons.fastfood.codePoint: Icons.fastfood,
    Icons.directions_bus.codePoint: Icons.directions_bus,
    Icons.shopping_cart.codePoint: Icons.shopping_cart, // Grocery
    Icons.wifi.codePoint: Icons.wifi,
    Icons.lightbulb.codePoint: Icons.lightbulb,
    Icons.movie.codePoint: Icons.movie,
    Icons.local_hospital.codePoint: Icons.local_hospital,
    Icons.category.codePoint: Icons.category,
  };

  IconData get iconData {
    return _supportedIcons[iconCodePoint] ?? Icons.category;
  }

  Color get color => Color(colorValue);
}
