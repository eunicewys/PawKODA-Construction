import 'package:flutter/material.dart';

/// CaloricAdequacyBanner: Real-time banner indicating caloric adequacy status based on target DER.
class CaloricAdequacyBanner extends StatelessWidget {
  final double adequacyRatio;
  final String petName;
  final bool isSickPet;

  const CaloricAdequacyBanner({
    super.key,
    required this.adequacyRatio,
    required this.petName,
    this.isSickPet = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    String message;

    if (adequacyRatio < 70.0) {
      bgColor = const Color(0xFFE57373); // Muted Red
      message = "Insufficient nutrition for $petName";
    } else if (adequacyRatio < 90.0) {
      bgColor = const Color(0xFFFFB74D); // Soft Orange
      message = "Almost there, still lacking a bit of nutrition";
    } else if (adequacyRatio <= 110.0) {
      bgColor = const Color(0xFF759C86); // Soft Sage Green
      message = isSickPet
          ? "Optimal! Portions match $petName's therapeutic target"
          : "Optimal! Portions match $petName's daily energy requirement";
    } else {
      bgColor = const Color(0xFF8C5A47); // Muted Brown
      message = "Excessive intake! This may harm $petName's health";
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
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Caloric Target Match: ${adequacyRatio.toStringAsFixed(1)}%",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
