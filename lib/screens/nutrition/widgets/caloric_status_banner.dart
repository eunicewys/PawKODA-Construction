import 'package:flutter/material.dart';
import '../../../services/nutrition_calculator_service.dart';

class CaloricStatusBanner extends StatelessWidget {
  final AdequacyCategory status;
  final String petName;
  final bool isSickPet;

  const CaloricStatusBanner({
    super.key,
    required this.status,
    required this.petName,
    this.isSickPet = false,
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
        bgColor = const Color(0xFFE07A5F); // Soft Orange
        message = "Almost there, still lacking a bit of nutrition";
        break;
      case AdequacyCategory.optimal:
        bgColor = const Color(0xFF759C86); // Soft Sage Green
        message = isSickPet 
            ? "Optimal! Portions match $petName's therapeutic target"
            : "Optimal! Portions match $petName's daily energy requirement";
        break;
      case AdequacyCategory.excess:
        bgColor = const Color(0xFF8D6E63); // Muted Brown
        message = isSickPet
            ? "Excessive intake! This may exacerbate $petName's condition"
            : "Excessive intake! This may lead to unhealthy weight gain";
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
