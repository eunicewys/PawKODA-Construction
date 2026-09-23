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

    return ClipPath(
      clipper: _ArtisticFringeClipper(),
      child: Container(
        height: 125, // Slightly increased for breathing room
        width: double.infinity,
        color: dustyOlive,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0), // Minimal top padding
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Align to top
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
                  onPressed: onBack,
                  padding: const EdgeInsets.only(top: 8), // Small adjustment for arrow
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12), // Tuck text high up
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white.withAlpha(220), // Brighter
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtisticFringeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 15); // Start lower on the left

    // Artistic imbalanced wave: Much shallower to stay away from text
    // Deep dip on the left (but not rising high)
    var firstControlPoint = Offset(size.width * 0.35, size.height + 15);
    var firstEndPoint = Offset(size.width * 0.6, size.height - 5);
    
    // Very shallow ripple on the right
    var secondControlPoint = Offset(size.width * 0.8, size.height - 15);
    var secondEndPoint = Offset(size.width, size.height - 5);

    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
