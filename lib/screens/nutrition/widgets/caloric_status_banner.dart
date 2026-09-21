import 'package:flutter/material.dart';
import '../../../services/nutrition_calculator_service.dart';

class CaloricStatusBanner extends StatelessWidget {
  final AdequacyCategory status;
  final String petName;

  const CaloricStatusBanner({
    super.key,
    required this.status,
    required this.petName,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    String message;

    switch (status) {
      case AdequacyCategory.insufficient:
        bgColor = const Color(0xFFB56576); // Muted Red
        message = "Insufficient nutrition for $petName";
        break;
      case AdequacyCategory.lacking:
        bgColor = const Color(0xFFCB997E); // Soft Orange / Bronze
        message = "Almost there, still lacking a bit of nutrition";
        break;
      case AdequacyCategory.optimal:
        bgColor = const Color(0xFF759C86); // Soft Sage Green
        message = "Hooray! Let's proceed to feed the meal to $petName";
        break;
      case AdequacyCategory.excess:
        bgColor = const Color(0xFF7F5539); // Muted Brown / Dark Terracotta
        message = "Overfeeding! It might harm $petName's health";
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: bgColor.withAlpha(80), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
