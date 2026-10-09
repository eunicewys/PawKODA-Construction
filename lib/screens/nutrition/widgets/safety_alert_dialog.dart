import 'package:flutter/material.dart';

/// SafetyAlertDialog: Interceptor modal displayed when an unsafe/toxic or allergen ingredient is selected.
class SafetyAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final List<String> alternatives;

  const SafetyAlertDialog({
    super.key,
    this.title = "WARNING: Toxic / Allergen Detected!",
    required this.message,
    required this.alternatives,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Colors.red, width: 2.5), // Solid red border
      ),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF2D3142), height: 1.3),
            ),
            if (alternatives.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                "Safe Suggested Alternatives:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2D3142)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: alternatives.map((alt) => Chip(
                  label: Text(alt, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B705C))),
                  backgroundColor: const Color(0xFFFFE8D6).withAlpha(150),
                  side: BorderSide.none,
                )).toList(),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Dismiss & Block", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
