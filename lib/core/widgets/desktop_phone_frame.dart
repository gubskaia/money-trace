import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DesktopPhoneFrame extends StatelessWidget {
  const DesktopPhoneFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!_isDesktopPlatform) {
      return child;
    }

    final mediaQuery = MediaQuery.of(context);
    final frameWidth = mediaQuery.size.width > 430
        ? 430.0
        : mediaQuery.size.width;
    final frameHeight = mediaQuery.size.height > 932
        ? 932.0
        : mediaQuery.size.height;

    final hasPreviewChrome =
        mediaQuery.size.width > frameWidth + 40 &&
        mediaQuery.size.height > frameHeight + 40;

    if (!hasPreviewChrome) {
      return child;
    }

    return ColoredBox(
      color: const Color(0xFFEFF2F5),
      child: Center(
        child: Container(
          width: frameWidth,
          height: frameHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(34),
            boxShadow: const [
              BoxShadow(
                color: Color(0x220A0F1A),
                blurRadius: 38,
                offset: Offset(0, 22),
              ),
            ],
          ),
          child: MediaQuery(
            data: mediaQuery.copyWith(size: Size(frameWidth, frameHeight)),
            child: child,
          ),
        ),
      ),
    );
  }

  bool get _isDesktopPlatform {
    if (kIsWeb) {
      return false;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.windows => true,
      TargetPlatform.macOS => true,
      TargetPlatform.linux => true,
      TargetPlatform.android => false,
      TargetPlatform.iOS => false,
      TargetPlatform.fuchsia => false,
    };
  }
}
