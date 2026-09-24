import 'package:flutter/material.dart';

class FringeHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBack;

  const FringeHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    const Color dustyOlive = Color(0xFF6B705C);
    const Color powderPetal = Color(0xFFFFE8D6);

    return SizedBox(
      height: 112,
      width: double.infinity,
      child: Stack(
        children: [
          // 1. Soft Background Accent Wave (smooths out desert sand gaps)
          ClipPath(
            clipper: _SmoothWaveClipper(isBackground: true),
            child: Container(
              height: 112,
              width: double.infinity,
              color: dustyOlive.withAlpha(90),
            ),
          ),

          // 2. Primary Solid Header Wave
          ClipPath(
            clipper: _SmoothWaveClipper(isBackground: false),
            child: Container(
              height: 106,
              width: double.infinity,
              color: dustyOlive,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 16, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                        onPressed: onBack,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  subtitle!.toUpperCase(),
                                  style: TextStyle(
                                    color: powderPetal.withAlpha(230),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.6,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmoothWaveClipper extends CustomClipper<Path> {
  final bool isBackground;

  _SmoothWaveClipper({required this.isBackground});

  @override
  Path getClip(Size size) {
    Path path = Path();
    double h = size.height;
    double w = size.width;

    if (isBackground) {
      // Soft secondary wave layer sitting slightly below primary
      path.lineTo(0, h - 8);
      path.cubicTo(
        w * 0.32, h, 
        w * 0.65, h - 26, 
        w, h - 8,
      );
    } else {
      // Silky smooth continuous S-wave strictly within bounds (no hard cuts)
      path.lineTo(0, h - 14);
      path.cubicTo(
        w * 0.32, h - 2, 
        w * 0.62, h - 24, 
        w, h - 12,
      );
    }

    path.lineTo(w, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
