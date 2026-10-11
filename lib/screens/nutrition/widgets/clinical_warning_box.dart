import 'package:flutter/material.dart';

/// ClinicalWarningBox: Displays real-time clinical safety hazard alerts when therapeutic limits are violated.
class ClinicalWarningBox extends StatelessWidget {
  final List<String> warnings;

  const ClinicalWarningBox({
    super.key,
    required this.warnings,
  });

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBE8E5), // Soft terracotta background
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD32F2F), width: 2.0), // Solid red border
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD32F2F).withAlpha(30),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.medical_services_outlined, color: Color(0xFFD32F2F), size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "CLINICAL SAFETY HAZARD DETECTED",
                  style: TextStyle(
                    color: Color(0xFFD32F2F),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...warnings.map((warning) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("• ", style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    warning,
                    style: const TextStyle(
                      color: Color(0xFF2D3142),
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
