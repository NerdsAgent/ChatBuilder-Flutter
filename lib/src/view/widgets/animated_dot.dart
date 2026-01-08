import 'package:flutter/material.dart';

class AnimatedDotWidget extends StatefulWidget {
  final int delay;

  const AnimatedDotWidget({
    Key? key,
    required this.delay,
  }) : super(key: key);

  @override
  State<AnimatedDotWidget> createState() => _AnimatedDotWidgetState();
}

class _AnimatedDotWidgetState extends State<AnimatedDotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = (_controller.value + widget.delay / 1400) % 1.0;
        final offset = value < 0.5
            ? Curves.easeOut.transform(value * 2) * -10
            : Curves.easeIn.transform((1 - value) * 2) * -10;

        return Transform.translate(
          offset: Offset(0, offset),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}