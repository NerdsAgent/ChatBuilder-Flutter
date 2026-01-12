import 'package:flutter/material.dart';
import '../../models/chat_widget_config.dart';
import '../../utils/text_style_helper.dart';

class MinimizeButtonWidget extends StatefulWidget {
  final Offset position;
  final ChatWidgetConfig config;
  final AnimationController pulseController;
  final bool showPopup;
  final VoidCallback onTap;

  const MinimizeButtonWidget({
    Key? key,
    required this.position,
    required this.config,
    required this.pulseController,
    required this.showPopup,
    required this.onTap,
  }) : super(key: key);

  @override
  State<MinimizeButtonWidget> createState() => _MinimizeButtonWidgetState();
}

class _MinimizeButtonWidgetState extends State<MinimizeButtonWidget> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: SizedBox(
            width: 100, // Fixed container to prevent layout shifts
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Ripples layer - animated but doesn't affect main button
                if (widget.config.enablePulsingAnimation)
                  AnimatedBuilder(
                    animation: widget.pulseController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // First ripple
                          Positioned(
                            child: Opacity(
                              opacity: (1 - widget.pulseController.value) * 0.4,
                              child: Container(
                                width: 50 + (widget.pulseController.value * 20),
                                height: 50 + (widget.pulseController.value * 20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: widget.config.primaryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Second ripple with delay
                          Positioned(
                            child: Opacity(
                              opacity: ((1 - widget.pulseController.value) * 0.3).clamp(0.0, 0.3),
                              child: Container(
                                width: 50 + (widget.pulseController.value * 30),
                                height: 50 + (widget.pulseController.value * 30),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: widget.config.primaryColor,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                // Main button - static position
                Positioned(
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.config.primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chat,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                // Popup message - absolute positioned, doesn't affect layout
                if (_isHovering || widget.showPopup)
                  Positioned(
                    bottom: 70,
                    child: AnimatedOpacity(
                      opacity: _isHovering || widget.showPopup ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: widget.config.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.config.popupMessage,
                          style: TextStyleHelper.getChatTextStyle(
                            widget.config,
                            size: 12,
                            weight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
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