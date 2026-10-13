import 'package:flutter/material.dart';

/// A depth-aware page transition. The incoming page slides in from the right
/// with a fade and a subtle scale-up, while the page being left behind gently
/// recedes — sliding back, scaling down and dimming — giving a layered,
/// "premium" sense of depth (similar to iOS / Material shared-axis motion).
class PremiumPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  PremiumPageRoute({
    required this.child,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 240),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            // A simple, fast, smooth slide + fade — one lightweight transition
            // with no scale/dim layers, so navigation feels snappy and never
            // janks, even on lower-end devices.
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
              reverseCurve: Curves.easeIn,
            );

            final slideIn = Tween<Offset>(
              begin: const Offset(0.12, 0),
              end: Offset.zero,
            ).animate(curved);

            return SlideTransition(
              position: slideIn,
              child: FadeTransition(opacity: curved, child: child),
            );
          },
        );
}

/// A Material "fade-through" transition — the old page fades and scales out
/// while the new page fades and scales in from ~92%. Ideal for switching
/// between unrelated destinations (e.g. bottom-nav tabs) where a directional
/// slide would feel arbitrary.
class FadeThroughPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  FadeThroughPageRoute({
    required this.child,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 220),
          reverseTransitionDuration: const Duration(milliseconds: 180),
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            // Simple, fast cross-fade — cheap to composite and smooth for
            // switching between unrelated destinations (e.g. bottom-nav tabs).
            final fadeIn = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );
            return FadeTransition(opacity: fadeIn, child: child);
          },
        );
}

extension PremiumNavigator on NavigatorState {
  Future<T?> pushPremium<T>(Widget child) {
    return push(PremiumPageRoute<T>(child: child));
  }

  Future<T?> pushReplacementPremium<T>(Widget child) {
    return pushReplacement(PremiumPageRoute<T>(child: child));
  }

  Future<T?> pushFadeThrough<T>(Widget child) {
    return push(FadeThroughPageRoute<T>(child: child));
  }

  Future<T?> pushReplacementFadeThrough<T>(Widget child) {
    return pushReplacement(FadeThroughPageRoute<T>(child: child));
  }
}

extension PremiumContext on BuildContext {
  Future<T?> pushPremium<T>(Widget child) {
    return Navigator.of(this).push(PremiumPageRoute<T>(child: child));
  }

  Future<T?> pushReplacementPremium<T>(Widget child) {
    return Navigator.of(this)
        .pushReplacement(PremiumPageRoute<T>(child: child));
  }

  Future<T?> pushFadeThrough<T>(Widget child) {
    return Navigator.of(this).push(FadeThroughPageRoute<T>(child: child));
  }

  Future<T?> pushReplacementFadeThrough<T>(Widget child) {
    return Navigator.of(this)
        .pushReplacement(FadeThroughPageRoute<T>(child: child));
  }
}
