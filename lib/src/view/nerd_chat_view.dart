// nerd_chat_widget.dart
// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/chat_widget_controller.dart';
import '../models/chat_widget_config.dart';
import '../models/widget_position.dart';
import '../utils/text_style_helper.dart';
import 'widgets/animated_dot.dart';
import 'widgets/chat_bubble_widget.dart';
import 'widgets/minimize_button.dart';

/// Overlay-based chat widget with stable upper part and moving input section
class _PersistedWidgetState {
  final ChatWidgetController controller;
  final Size cachedScreenSize;
  final bool cachedIsWeb;
  final Offset cachedPosition;
  final Offset cachedMiniPosition;
  final FocusNode focusNode;
  final ChatWidgetConfig config;

  _PersistedWidgetState({
    required this.controller,
    required this.cachedScreenSize,
    required this.cachedIsWeb,
    required this.cachedPosition,
    required this.cachedMiniPosition,
    required this.focusNode,
    required this.config,
  });
}

class NerdChatWidget extends StatefulWidget {
  final ChatWidgetConfig? chatWidgetConfig;
  final Function(String message)? onMessageSent;
  final VoidCallback? onWidgetOpened;
  final VoidCallback? onWidgetClosed;
  final String apiKey;
  final String agentId;

  const NerdChatWidget({
    Key? key,
    this.chatWidgetConfig,
    required this.apiKey,
    required this.agentId,
    this.onMessageSent,
    this.onWidgetOpened,
    this.onWidgetClosed,
  }) : super(key: key);

  @override
  State<NerdChatWidget> createState() => _NerdChatWidgetState();
}

class _NerdChatWidgetState extends State<NerdChatWidget>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // ---------- Package-level persistent cache ----------
  static final Map<String, _PersistedWidgetState> _widgetCache = {};

  ChatWidgetController? _controller;
  late AnimationController _pulseController;
  late ChatWidgetConfig config;
  late FocusNode _textFieldFocusNode;

  late Size _cachedScreenSize;
  late bool _cachedIsWeb;
  late Offset _cachedPosition;
  late Offset _cachedMiniPosition;

  bool _isInitialized = false;
  bool _reusedFromCache = false;

  // keyboard / layout state
  double _keyboardHeight = 0.0;
  double _inputBottomOffset = 24.0; // Start above powered-by widget (updated after first measurement)
  // static const double _minTop = 8.0;
  static const double _keyboardMargin = 8.0; // visual gap between input and keyboard top
  static const double _baseBottomOffset = 16.0;

  // overlay
  OverlayEntry? _overlayEntry;

  // settle debounce for metric events (coalesce multiple frames)
  Timer? _metricsSettleTimer;
  static const Duration _settleDelay = Duration(milliseconds: 140);

  // measurement keys
  final GlobalKey _headerKey = GlobalKey();
  final GlobalKey _inputKey = GlobalKey();
  final GlobalKey _selectedFileKey = GlobalKey();
  final GlobalKey _poweredByKey = GlobalKey();

  // measured heights
  double _headerHeight = 56.0;
  double _inputHeight = 60.0;
  double _selectedFileHeight = 0.0;
  double _poweredByHeight = 24.0; // Default height to prevent initial overlap

  // previous messages count to decide when to auto-scroll
  int _lastMessagesLength = 0;

  // avoid rebuilds when nothing changed
  double _lastInputBottomOffset = -1;
  double _lastKeyboardHeight = -1;

  // focus listener handle
  late VoidCallback _focusListener;

  String get _cacheKey => widget.agentId.isNotEmpty ? widget.agentId : 'nerd_chat_default';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    debugPrint('[NerdChatWidget] initState() called for key=$_cacheKey');

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    if (_widgetCache.containsKey(_cacheKey)) {
      final cached = _widgetCache[_cacheKey]!;
      _controller = cached.controller;
      _cachedScreenSize = cached.cachedScreenSize;
      _cachedIsWeb = cached.cachedIsWeb;
      _cachedPosition = cached.cachedPosition;
      _cachedMiniPosition = cached.cachedMiniPosition;
      config = cached.config;
      _textFieldFocusNode = cached.focusNode;

      _reusedFromCache = true;
      _isInitialized = true;

      _controller!.addListener(_onControllerChanged);
      _lastMessagesLength = _controller?.messages.length ?? 0;

      debugPrint('[NerdChatWidget] Reused cached state for key=$_cacheKey');
      _attachFocusListener();
      return;
    }

    _textFieldFocusNode = FocusNode();
    _reusedFromCache = false;
    _attachFocusListener();
  }

  void _attachFocusListener() {
    _focusListener = () {
      if (_textFieldFocusNode.hasFocus) {
        debugPrint('[NerdChatWidget] Input focused -> scheduling keyboard adapt');
        Future.delayed(const Duration(milliseconds: 260), () {
          if (!mounted) return;
          _scheduleMetricsSettle();
        });
      } else {
        debugPrint('[NerdChatWidget] Input lost focus -> resetting shortly');
        Future.delayed(const Duration(milliseconds: 80), () {
          if (!mounted) return;
          _scheduleMetricsSettle();
        });
      }
    };

    try {
      _textFieldFocusNode.removeListener(_focusListener);
    } catch (_) {}
    _textFieldFocusNode.addListener(_focusListener);
  }

  void _detachFocusListener() {
    try {
      _textFieldFocusNode.removeListener(_focusListener);
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('[NerdChatWidget] didChangeDependencies called. Already initialized: $_isInitialized');

    if (_isInitialized && _controller != null) {
      debugPrint('[NerdChatWidget] Skipping heavy init since already initialized.');
      _scheduleMetricsSettle();
      return;
    }

    _initializeEverything();
    _isInitialized = true;

    if (_controller != null) {
      _widgetCache[_cacheKey] = _PersistedWidgetState(
        controller: _controller!,
        cachedScreenSize: _cachedScreenSize,
        cachedIsWeb: _cachedIsWeb,
        cachedPosition: _cachedPosition,
        cachedMiniPosition: _cachedMiniPosition,
        focusNode: _textFieldFocusNode,
        config: config,
      );
      debugPrint('[NerdChatWidget] Cached state for key=$_cacheKey');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showOverlay();
      _scheduleMetricsSettle(immediate: true);
    });
  }

  void _initializeEverything() {
    debugPrint('[NerdChatWidget] Starting initialization...');

    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final screenH = mq.size.height;
    final isMobile = screenW < 600;

    _cachedScreenSize = Size(screenW, screenH);
    _cachedIsWeb = !isMobile;
    debugPrint('[NerdChatWidget] Screen: ${screenW}x${screenH}, isMobile: $isMobile');

    config = widget.chatWidgetConfig ?? ChatWidgetConfig();
    final passed = widget.chatWidgetConfig;
    final bool shouldOverrideDefaults = isMobile &&
        (passed == null || (passed.width == 350 && passed.height == 500));

    if (shouldOverrideDefaults) {
      final newWidth = screenW - 40;
      final newHeight = screenH * 0.7;
      config = config.copyWith(width: newWidth, height: newHeight, );
      debugPrint('[NerdChatWidget] Applied responsive config: ${newWidth}x${newHeight}');
    }

    _calculatePositions();
    debugPrint('[NerdChatWidget] Positions cached: $_cachedPosition, $_cachedMiniPosition');

    debugPrint('[NerdChatWidget] Creating controller...');
    _controller = ChatWidgetController(
      config: config,
      onMessageSent: widget.onMessageSent,
      onWidgetOpened: widget.onWidgetOpened,
      onWidgetClosed: widget.onWidgetClosed,
      agentId: widget.agentId,
      apiKey: widget.apiKey,
    );

    _controller!.addListener(_onControllerChanged);
    debugPrint('[NerdChatWidget] Initialization complete!');

    _lastMessagesLength = _controller?.messages.length ?? 0;
  }

  // read logical keyboard height
  double _getKeyboardHeight() {
    final window = WidgetsBinding.instance.window;
    final physical = window.viewInsets.bottom;
    final dpr = window.devicePixelRatio;
    return physical / dpr;
  }

  // SCHEDULED COALESCE MECHANISM -------------------------------------------
  // Lightweight immediate update used to reflect a small offset during animation
  void _lightweightOffsetUpdate() {
    final keyboardH = _getKeyboardHeight();
    _keyboardHeight = keyboardH;

    // Calculate input bottom offset from the widget's bottom edge
    // When keyboard is closed: position above powered-by widget
    // When keyboard is open: position above keyboard with margin
    final newInputOffset = (_keyboardHeight > 0) 
        ? (_keyboardHeight - _baseBottomOffset + _keyboardMargin) 
        : _poweredByHeight; // When closed, sit above powered-by

    // only quick-set if changed noticeably to avoid tiny rebuild spam
    if ((newInputOffset - _lastInputBottomOffset).abs() > 1.0) {
      _inputBottomOffset = newInputOffset;
      _lastInputBottomOffset = _inputBottomOffset;
      _updateOverlay();
    }
  }

  // schedule settle: cancel previous and call final update after delay
  void _scheduleMetricsSettle({bool immediate = false}) {
    // call a lightweight offset update now so widget follows keyboard a bit
    _lightweightOffsetUpdate();

    _metricsSettleTimer?.cancel();
    if (immediate) {
      // do final update immediately
      _onMetricsSettled();
      return;
    }
    _metricsSettleTimer = Timer(_settleDelay, _onMetricsSettled);
  }

  // the "settled" heavy update: measure and rebuild only if needed
  void _onMetricsSettled() {
    _metricsSettleTimer?.cancel();

    final keyboardH = _getKeyboardHeight();
    // ignore tiny jitter from platform
    if ((_lastKeyboardHeight - keyboardH).abs() < 0.5 && _overlayEntry != null) {
      _measureParts();
      return;
    }
    _lastKeyboardHeight = keyboardH;
    _keyboardHeight = keyboardH;

    // Calculate input bottom offset - account for widget's base position
    // When keyboard closed: position above powered-by widget
    // When keyboard open: position above keyboard with margin
    final newInputOffset = (_keyboardHeight > 0) 
        ? (_keyboardHeight - _baseBottomOffset + _keyboardMargin) 
        : _poweredByHeight; // When closed, sit above powered-by
    _inputBottomOffset = newInputOffset;

    debugPrint(
        '[NerdChatWidget] settled: keyboard=$_keyboardHeight, inputOffset=$_inputBottomOffset');

    // measure parts (header/input/etc.)
    _measureParts();
    // then rebuild overlay (debounced by this call)
    _debouncedOverlayRebuild();
  }

  // small debounce to avoid many markNeedsBuild calls
  Timer? _overlayRebuildDebounce;
  void _debouncedOverlayRebuild() {
    _overlayRebuildDebounce?.cancel();
    _overlayRebuildDebounce = Timer(const Duration(milliseconds: 40), () {
      _updateOverlay();
    });
  }

  // Measurement of component heights
  void _measureParts() {
    double headerH = 56.0;
    double inputH = 60.0;
    double selectedFileH = 0.0;
    double poweredByH = 0.0;

    try {
      final headerBox = _headerKey.currentContext?.findRenderObject() as RenderBox?;
      if (headerBox != null && headerBox.hasSize) headerH = headerBox.size.height;
    } catch (_) {}

    try {
      final inputBox = _inputKey.currentContext?.findRenderObject() as RenderBox?;
      if (inputBox != null && inputBox.hasSize) inputH = inputBox.size.height;
    } catch (_) {}

    try {
      final fileBox = _selectedFileKey.currentContext?.findRenderObject() as RenderBox?;
      if (fileBox != null && fileBox.hasSize) selectedFileH = fileBox.size.height;
    } catch (_) {}

    try {
      final poweredBox = _poweredByKey.currentContext?.findRenderObject() as RenderBox?;
      if (poweredBox != null && poweredBox.hasSize) poweredByH = poweredBox.size.height;
    } catch (_) {}

    bool changed = false;
    if ((_headerHeight - headerH).abs() > 0.5) {
      _headerHeight = headerH;
      changed = true;
    }
    if ((_inputHeight - inputH).abs() > 0.5) {
      _inputHeight = inputH;
      changed = true;
    }
    if ((_selectedFileHeight - selectedFileH).abs() > 0.5) {
      _selectedFileHeight = selectedFileH;
      changed = true;
    }
    // Only update powered-by height if we got a valid measurement (> 0)
    // This prevents resetting to 0 on first frame before layout completes
    if (poweredByH > 0 && (_poweredByHeight - poweredByH).abs() > 0.5) {
      _poweredByHeight = poweredByH;
      // Also update input offset to match new powered-by height when keyboard is closed
      if (_keyboardHeight == 0) {
        _inputBottomOffset = _poweredByHeight;
      }
      changed = true;
    }

    if (changed) {
      debugPrint(
          '[NerdChatWidget] measured header=${_headerHeight.toStringAsFixed(1)}, input=${_inputHeight.toStringAsFixed(1)}, selected=${_selectedFileHeight.toStringAsFixed(1)}, powered=${_poweredByHeight.toStringAsFixed(1)}');
      _updateOverlay();
    }
  }

  // Overlay management ------------------------------------------------------
  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(builder: (context) {
      final mq = MediaQuery.of(context);
      final screenWidth = mq.size.width;
      final safeBottom = mq.viewPadding.bottom;

      final bool isRight = config.position == WidgetPosition.bottomRight;

      if (_controller?.isMinimized ?? false) {
        // minimized floating button anchored to safe area bottom-right
        final double miniPadding = 16.0;
        final double miniBottom = safeBottom + 16.0;
        return Positioned(
            left: isRight ? null : miniPadding,   // Left when bottomLeft
     right: isRight ? miniPadding : null,  // Right when bottomRight
         bottom: miniBottom,
          child: Material(
            color: Colors.transparent,
            child: MinimizeButtonWidget(
              position: _cachedMiniPosition,
              config: config,
              pulseController: _pulseController,
              showPopup: _controller!.showPopup,
              onTap: _controller!.openWidget,
            ),
          ),
        );
      }

      // Normal (non-minimized) overlay - fixed position
      final left = isRight
          ? null
          : _cachedPosition.dx.clamp(8.0, math.max(8.0, screenWidth - config.width - 8.0));
      final right = isRight ? 8.0 : null;
      final bottom = _baseBottomOffset;

      return Positioned(
        left: left?.toDouble(),
        right: right,
        bottom: bottom,
        child: SafeArea(
          top: false,
          left: false,
          right: false,
          bottom: true,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: config.width,
              height: config.height,
              child: _overlayContent(),
            ),
          ),
        ),
      );
    });

    try {
      Overlay.of(context).insert(_overlayEntry!);
      debugPrint('[NerdChatWidget] inserted overlay');
    } catch (e) {
      debugPrint('[NerdChatWidget] failed to insert overlay: $e');
    }
  }

  void _updateOverlay() {
    if (_overlayEntry != null) {
      try {
        _overlayEntry!.markNeedsBuild();
      } catch (_) {}
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showOverlay();
      });
    }
  }

  void _removeOverlay() {
    try {
      _overlayEntry?.remove();
    } catch (_) {}
    _overlayEntry = null;
  }

  // Build the full overlay content using Stack with positioned input area
  Widget _overlayContent() {
    if (_controller?.isMinimized ?? false) {
      return const SizedBox.shrink();
    }

    // Calculate heights for fixed upper part
    final upperPartHeight = _headerHeight;
    
    // Calculate total input section height (input + selected file only, powered-by stays fixed)
    final inputSectionHeight = _inputHeight + _selectedFileHeight;
    
    // Powered-by stays at the bottom (not animated)
    final bottomFixedHeight = _poweredByHeight;
    
    // Messages list gets the remaining space minus a buffer for the input section
    // Since input can now overlap the message area when keyboard is up, we need to account for that
    final messagesHeight = config.height - upperPartHeight - inputSectionHeight - bottomFixedHeight;

    return Container(
      width: config.width,
      height: config.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 40,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Fixed upper part: Header + Messages
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header (measured, fixed at top)
                  Container(key: _headerKey, child: _buildHeader()),
                  
                  // Messages list with fixed height
                  SizedBox(
                    height: messagesHeight,
                    child: _buildMessagesList(),
                  ),
                ],
              ),
            ),

            // Moving input section (input + selected file only)
            // Position is calculated from screen bottom, accounting for keyboard
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              bottom: _inputBottomOffset, // This is already relative to the widget's coordinate system
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Selected file indicator (measured)
                  if (_controller!.selectedFile != null)
                    Container(key: _selectedFileKey, child: _buildSelectedFileIndicator()),

                  // Input area (measured)
                  Container(key: _inputKey, child: _buildInputArea()),
                ],
              ),
            ),

            // Fixed powered-by at the very bottom (doesn't move with keyboard)
            if (config.showPoweredBy)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  key: _poweredByKey,
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: _buildPoweredBy(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant NerdChatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isInitialized) return;

    if (widget.chatWidgetConfig != oldWidget.chatWidgetConfig) {
      config = widget.chatWidgetConfig ?? ChatWidgetConfig();
      _calculatePositions();
      _scheduleMetricsSettle(immediate: true);
      debugPrint('[NerdChatWidget] config changed, recalculated positions');
    }

    if (widget.agentId != oldWidget.agentId) {
      debugPrint('[NerdChatWidget] agentId changed from ${oldWidget.agentId} to ${widget.agentId}');
    }
  }

  // didChangeMetrics now just schedules the settle logic
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _lightweightOffsetUpdate();
    _scheduleMetricsSettle();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    debugPrint('[NerdChatWidget] dispose called for key=$_cacheKey, reusedFromCache=$_reusedFromCache');

    _detachFocusListener();

    try {
      _controller?.removeListener(_onControllerChanged);
    } catch (_) {}

    try {
      _pulseController.dispose();
    } catch (_) {}

    if (!_reusedFromCache) {
      if (_widgetCache.containsKey(_cacheKey)) {
        _widgetCache.remove(_cacheKey);
        debugPrint('[NerdChatWidget] Removed cached state for key=$_cacheKey');
      }

      try {
        _controller?.dispose();
      } catch (_) {}
      try {
        _textFieldFocusNode.dispose();
      } catch (_) {}
    }

    _metricsSettleTimer?.cancel();
    _overlayRebuildDebounce?.cancel();
    _removeOverlay();

    super.dispose();
  }

  void _onControllerChanged() {
    final newLen = _controller?.messages.length ?? 0;
    debugPrint('[NerdChatWidget] Controller changed, messages: $newLen (last: $_lastMessagesLength)');

    // Auto-scroll only when new messages arrive
    if (newLen > _lastMessagesLength) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        try {
          _controller?.scrollToBottom();
        } catch (_) {}
      });
    }
    _lastMessagesLength = newLen;

    // Re-measure because selected-file or other parts may have changed
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _measureParts();
    });

    // update overlay if needed
    _debouncedOverlayRebuild();
  }

  // --- UI pieces (mostly reused) -----------------------------------------
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: config.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: config.agentAvatarProvider,
              backgroundColor: config.primaryColor.withOpacity(0.8),
              child: config.agentAvatarProvider == null
                  ? Text(
                      config.agentName.length >= 2
                          ? config.agentName.substring(0, 2).toUpperCase()
                          : config.agentName.toUpperCase(),
                      style: TextStyleHelper.getChatTextStyle(
                        config,
                        size: 14,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  config.agentName,
                  style: TextStyleHelper.getChatTextStyle(
                    config,
                    size: 14,
                    weight: FontWeight.w600,
                    color: config.headerTextColor,
                  ),
                ),
                if (config.agentRole.isNotEmpty)
                  Text(
                    config.agentRole,
                    style: TextStyleHelper.getChatTextStyle(
                      config,
                      size: 12,
                      color: config.headerTextColor.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (config.showMinimizeButton)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: config.headerTextColor,
                      size: 18,
                    ),
                    onPressed: _controller!.toggleMinimize,
                  ),
                ),
              const SizedBox(width: 6),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.close,
                    color: config.headerTextColor,
                    size: 16,
                  ),
                  onPressed: _controller!.closeWidget,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return Container(
      color: const Color(0xFFFAFAFA),
      child: ListView.builder(
        controller: _controller!.scrollController,
        padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 12),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: _controller!.messages.length + (_controller!.isTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _controller!.messages.length && _controller!.isTyping) {
            return _buildTypingIndicator();
          }

          final message = _controller!.messages[index];
          return ChatBubbleWidget(
            message: message,
            config: config,
            controller: _controller!,
          );
        },
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${config.agentName} is typing',
            style: TextStyleHelper.getChatTextStyle(
              config,
              size: 11,
              color: Colors.grey[600],
            ).copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(width: 6),
          const SizedBox(
            width: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AnimatedDotWidget(delay: 0),
                AnimatedDotWidget(delay: 200),
                AnimatedDotWidget(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 36,
                maxHeight: 80,
              ),
              child: TextField(
                key: const ValueKey('chat_input_field'),
                focusNode: _textFieldFocusNode,
                controller: _controller!.textController,
                style: TextStyleHelper.getChatTextStyle(config, size: 13),
                enableInteractiveSelection: true,
                decoration: InputDecoration(
                  hintText: config.placeholderText,
                  hintStyle: TextStyleHelper.getChatTextStyle(
                    config,
                    size: 13,
                    color: Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: config.accentColor.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
                maxLines: null,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  _controller!.sendMessage();
                  _textFieldFocusNode.unfocus();
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (config.enableFileUpload)
            _buildCircularButton(
              icon: Icons.attach_file,
              backgroundColor: const Color(0xFF3d4f5c),
              iconColor: Colors.white,
              onPressed: _controller!.pickFile,
            ),
          if (config.enableFileUpload) const SizedBox(width: 8),
          if (config.enableSpeech)
            _buildCircularButton(
              icon: Icons.mic,
              backgroundColor: const Color(0xFF3d4f5c),
              iconColor: Colors.white,
              onPressed: () {},
            ),
          if (config.enableSpeech) const SizedBox(width: 8),
          _buildCircularButton(
            icon: _controller!.isUploading ? Icons.hourglass_empty : Icons.send,
            backgroundColor: const Color(0xFF3d4f5c),
            iconColor: Colors.white,
            onPressed: _controller!.isUploading ? null : () {
              _controller!.sendMessage();
              _textFieldFocusNode.unfocus();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    VoidCallback? onPressed,
  }) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: iconColor, size: 14),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSelectedFileIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_file, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _controller!.selectedFile!.name,
              style: TextStyleHelper.getChatTextStyle(
                config,
                size: 11,
                color: Colors.grey[700],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _controller!.clearSelectedFile,
            icon: const Icon(Icons.close, size: 14, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildPoweredBy() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[100]!)),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            config.poweredByText,
            style: TextStyleHelper.getChatTextStyle(
              config,
              size: 10,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(width: 3),
          InkWell(
            onTap: () async {
              final Uri url = Uri.parse(config.poweredByUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
            child: Text(
              config.poweredByBrand,
              style: TextStyleHelper.getChatTextStyle(
                config,
                size: 10,
                color: config.poweredByColor,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _calculatePositions() {
    final screenSize = _cachedScreenSize;
    final isWeb = _cachedIsWeb;

    final padding = isWeb ? 80.0 : 150.0;
    const widthpadding = 20.0;

    switch (config.position) {
      case WidgetPosition.bottomLeft:
        _cachedPosition = Offset(
          widthpadding,
          screenSize.height - config.height - padding,
        );
        _cachedMiniPosition = Offset(
          screenSize.width * 0.08,
          screenSize.height - config.height + (screenSize.height * 0.45),
        );
        break;
      case WidgetPosition.bottomRight:
        _cachedPosition = Offset(
          screenSize.width - config.width - widthpadding,
          screenSize.height - config.height - padding,
        );
        final miniWidthPadding =
            isWeb ? (screenSize.width * 0.15) : (screenSize.width * 0.65);
        _cachedMiniPosition = Offset(
          screenSize.width - config.width + miniWidthPadding,
          screenSize.height - config.height + (screenSize.height * 0.45),
        );
        break;
    }
  }

  // The widget itself no longer paints UI directly; overlay handles it.
  // Return a small placeholder so parent layout is unaffected.
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}