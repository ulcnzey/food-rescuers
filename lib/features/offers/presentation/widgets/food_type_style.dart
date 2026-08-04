import 'package:flutter/material.dart';

import '../../domain/entities/offer.dart';

class FoodTypeStyle {
  const FoodTypeStyle(this.icon, this.color, this.label);

  final IconData icon;
  final Color color;
  final String label;

  static FoodTypeStyle of(FoodType type) => switch (type) {
        FoodType.bakery =>
          const FoodTypeStyle(Icons.bakery_dining_rounded, Color(0xFFD9A441), 'Fırın'),
        FoodType.meal =>
          const FoodTypeStyle(Icons.restaurant_rounded, Color(0xFFC96A4B), 'Yemek'),
        FoodType.grocery =>
          const FoodTypeStyle(Icons.shopping_basket_rounded, Color(0xFF4B8FC9), 'Market'),
        FoodType.produce =>
          const FoodTypeStyle(Icons.eco_rounded, Color(0xFF5FA95F), 'Manav'),
        FoodType.other =>
          const FoodTypeStyle(Icons.lunch_dining_rounded, Color(0xFF8B7BB8), 'Diğer'),
      };
}