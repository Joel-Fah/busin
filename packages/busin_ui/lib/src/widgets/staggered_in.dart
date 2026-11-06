import 'dart:async';

import 'package:flutter/material.dart';

import '../tokens/shape.dart';

/// Brings its child in with a short fade and rise, [index] steps after the first, so a list arrives as a wave and
/// not as a block. Plays once, when first built. Under reduced motion the child is simply there.
class StaggeredIn extends StatefulWidget {
  const StaggeredIn({super.key, required this.child, this.index = 0, this.step = const Duration(milliseconds: 50), this.rise = 12});

  final Widget child;

  /// Position in the wave; the first item is 0.
  final int index;
  final Duration step;

  /// How far the child travels up while appearing, in logical pixels.
  final double rise;

  @override
  State<StaggeredIn> createState() => _StaggeredInState();
}

class _StaggeredInState extends State<StaggeredIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: BusinMotion.normal);
  Timer? _delay;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (BusinMotion.reduced(context)) {
      _controller.value = 1;
      return;
    }
    // Long lists should not take seconds to appear: the wave stops growing after ten steps.
    final wait = widget.step * widget.index.clamp(0, 10);
    _delay = Timer(wait, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: BusinMotion.soft);
    return AnimatedBuilder(
      animation: curved,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: curved.value.clamp(0, 1),
        child: Transform.translate(offset: Offset(0, (1 - curved.value) * widget.rise), child: child),
      ),
    );
  }
}
