import 'package:flutter/material.dart';
import '../../utils/image_helper.dart';

class FringeHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Color? backgroundColor;
  final Color? accentColor;

  const FringeHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
    this.backgroundColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color mainColor = backgroundColor ?? const Color(0xFF6B705C);
    final Color subAccent = accentColor ?? mainColor.withAlpha(90);
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
              color: subAccent,
            ),
          ),

          // 2. Primary Solid Header Wave
          ClipPath(
            clipper: _SmoothWaveClipper(isBackground: false),
            child: Container(
              height: 106,
              width: double.infinity,
              color: mainColor,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 16, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (onBack != null)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                          onPressed: onBack,
                        )
                      else
                        const SizedBox(width: 16), // Padding if no back button
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
                      if (trailing != null) ...[
                        const SizedBox(width: 8),
                        trailing!,
                      ],
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

class DashboardFringeHeader extends StatelessWidget {
  final String greeting;
  final String userName;
  final String? photoUrl;
  final VoidCallback onLogout;
  final VoidCallback? onTapAvatar;

  const DashboardFringeHeader({
    super.key,
    required this.greeting,
    required this.userName,
    this.photoUrl,
    required this.onLogout,
    this.onTapAvatar,
  });

  @override
  Widget build(BuildContext context) {
    const Color dustyOlive = Color(0xFF6B705C);
    const Color powderPetal = Color(0xFFFFE8D6);
    ImageProvider? avatarImgProvider = ImageHelper.getImageProvider(photoUrl);

    return SizedBox(
      height: 120,
      width: double.infinity,
      child: Stack(
        children: [
          // 1. Soft Background Accent Wave Layer
          ClipPath(
            clipper: _SmoothWaveClipper(isBackground: true),
            child: Container(
              height: 120,
              width: double.infinity,
              color: dustyOlive.withAlpha(90),
            ),
          ),

          // 2. Primary Solid Header Wave
          ClipPath(
            clipper: _SmoothWaveClipper(isBackground: false),
            child: Container(
              height: 114,
              width: double.infinity,
              color: dustyOlive,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left Side: Greeting & User Name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              greeting,
                              style: TextStyle(
                                color: Colors.white.withAlpha(220),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Right Side: Logout Button & User Avatar
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: onLogout,
                            icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
                            tooltip: "Logout",
                          ),
                          GestureDetector(
                            onTap: onTapAvatar,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: powderPetal,
                                backgroundImage: avatarImgProvider,
                                child: avatarImgProvider == null
                                    ? Text(
                                        userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : '?',
                                        style: const TextStyle(
                                          color: dustyOlive,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
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
