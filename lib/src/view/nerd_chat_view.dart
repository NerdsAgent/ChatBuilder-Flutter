import 'package:flutter/material.dart';
import '../controllers/chat_widget_controller.dart';
import '../models/chat_widget_config.dart';
import '../models/widget_position.dart';
import '../utils/text_style_helper.dart';
import 'widgets/animated_dot.dart';
import 'widgets/chat_bubble_widget.dart';
import 'widgets/minimize_button.dart';
import 'package:url_launcher/url_launcher.dart';


class NerdChatWidget extends StatefulWidget {
  final ChatWidgetConfig config;
  final Function(String message)? onMessageSent;
  final VoidCallback? onWidgetOpened;
  final VoidCallback? onWidgetClosed;

  const NerdChatWidget({
    Key? key,
    required this.config,
    this.onMessageSent,
    this.onWidgetOpened,
    this.onWidgetClosed,
  }) : super(key: key);

  @override
  State<NerdChatWidget> createState() => _NerdChatWidgetState();
}

class _NerdChatWidgetState extends State<NerdChatWidget>
    with TickerProviderStateMixin {
  late ChatWidgetController _controller;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _controller = ChatWidgetController(
      config: widget.config,
      onMessageSent: widget.onMessageSent,
      onWidgetOpened: widget.onWidgetOpened,
      onWidgetClosed: widget.onWidgetClosed,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Offset _getPosition() {
    final screenSize = MediaQuery.of(context).size;
    final bool isWeb = screenSize.width > 600;
    final padding =isWeb? 80.0:150.0;
    const widthpadding = 20.0;


    switch (widget.config.position) {
      case WidgetPosition.bottomLeft:
        return Offset(
          widthpadding,
          screenSize.height - widget.config.height - padding,
        );
      case WidgetPosition.bottomRight:
      return Offset(
          screenSize.width - widget.config.width - widthpadding,
          screenSize.height - widget.config.height - padding,
        );
    }
  }

    Offset _getPositionForMini() {
    final screenSize = MediaQuery.of(context).size;
     final bool isWeb = screenSize.width > 600;
  final   padding = -(screenSize.height*0.45);
    final widthpadding = - ( isWeb? (screenSize.width*0.15): (screenSize.width*0.65));


    switch (widget.config.position) {
      case WidgetPosition.bottomLeft:
        return Offset(
        screenSize.width*0.08  ,
          screenSize.height - widget.config.height - padding,
        );
      case WidgetPosition.bottomRight:
      return Offset(
          screenSize.width - widget.config.width - widthpadding,
          screenSize.height - widget.config.height - padding,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_controller.isMinimized)
          MinimizeButtonWidget(
            position: _getPositionForMini(),
            config: widget.config,
            pulseController: _pulseController,
            showPopup: _controller.showPopup,
            onTap: _controller.openWidget,
          ),
        if (!_controller.isMinimized) _buildChatWidget(),
      ],
    );
  }

  Widget _buildChatWidget() {
    final position = _getPosition();

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Container(
        width: widget.config.width,
        height: widget.config.height,
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
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildMessagesList()),
              if (_controller.selectedFile != null) _buildSelectedFileIndicator(),
              _buildInputArea(),
              if (widget.config.showPoweredBy) _buildPoweredBy(),
             // SizedBox(height: 30,)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced from 16
      decoration: BoxDecoration(
        color: widget.config.primaryColor,
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
                width: 1.5, // Reduced from 2
              ),
            ),
            child: CircleAvatar(
              radius: 18, // Reduced from 22
              backgroundImage: widget.config.agentAvatarProvider,
              backgroundColor: widget.config.primaryColor.withOpacity(0.8),
              child: widget.config.agentAvatarProvider == null
                  ? Text(
                      widget.config.agentName.length >= 2
                          ? widget.config.agentName
                              .substring(0, 2)
                              .toUpperCase()
                          : widget.config.agentName.toUpperCase(),
                      style: TextStyleHelper.getChatTextStyle(
                        widget.config,
                        size: 14, // Reduced from 18
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10), // Reduced from 12
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.config.agentName,
                  style: TextStyleHelper.getChatTextStyle(
                    widget.config,
                    size: 14, // Reduced from 16
                    weight: FontWeight.w600,
                    color: widget.config.headerTextColor,
                  ),
                ),
                if (widget.config.agentRole.isNotEmpty)
                  Text(
                    widget.config.agentRole,
                    style: TextStyleHelper.getChatTextStyle(
                      widget.config,
                      size: 12, // Reduced from 14
                      color: widget.config.headerTextColor.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.config.showMinimizeButton)
                Container(
                  width: 28, // Reduced from 32
                  height: 28, // Reduced from 32
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: widget.config.headerTextColor,
                      size: 18, // Reduced from 22
                    ),
                    onPressed: _controller.toggleMinimize,
                  ),
                ),
              const SizedBox(width: 6), // Reduced from 8
              Container(
                width: 28, // Reduced from 32
                height: 28, // Reduced from 32
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.close,
                    color: widget.config.headerTextColor,
                    size: 16, // Reduced from 20
                  ),
                  onPressed: _controller.closeWidget,
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
        controller: _controller.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // Reduced from 16
        itemCount: _controller.messages.length + (_controller.isTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _controller.messages.length && _controller.isTyping) {
            return _buildTypingIndicator();
          }

          final message = _controller.messages[index];
          return ChatBubbleWidget(
            message: message,
            config: widget.config,
            controller: _controller,
          );
        },
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6), // Reduced from 8
      child: Row(
        children: [
          Text(
            '${widget.config.agentName} is typing',
            style: TextStyleHelper.getChatTextStyle(
              widget.config,
              size: 11, // Reduced from 12
              color: Colors.grey[600],
            ).copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(width: 6), // Reduced from 8
          const SizedBox(
            width: 24, // Reduced from 30
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
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
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
                controller: _controller.textController,
                style: TextStyleHelper.getChatTextStyle(widget.config, size: 13),
                decoration: InputDecoration(
                  hintText: widget.config.placeholderText,
                  hintStyle: TextStyleHelper.getChatTextStyle(
                    widget.config,
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
                      color: widget.config.accentColor.withOpacity(0.5),
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
                onSubmitted: (_) => _controller.sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (widget.config.enableFileUpload)
            _buildCircularButton(
              icon: Icons.attach_file,
              backgroundColor: const Color(0xFF3d4f5c),
              iconColor: Colors.white,
              onPressed: _controller.pickFile,
            ),
          if (widget.config.enableFileUpload) const SizedBox(width: 8),
          if (widget.config.enableSpeech)
            _buildCircularButton(
              icon: Icons.mic,
              backgroundColor: const Color(0xFF3d4f5c),
              iconColor: Colors.white,
              onPressed: () {
                // Speech functionality
              },
            ),
          if (widget.config.enableSpeech) const SizedBox(width: 8),
          _buildCircularButton(
            icon: _controller.isUploading ? Icons.hourglass_empty : Icons.send,
            backgroundColor: const Color(0xFF3d4f5c),
            iconColor: Colors.white,
            onPressed: _controller.isUploading ? null : _controller.sendMessage,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Reduced
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_file, size: 14, color: Colors.grey[600]), // Reduced
          const SizedBox(width: 6), // Reduced from 8
          Expanded(
            child: Text(
              _controller.selectedFile!.name,
              style: TextStyleHelper.getChatTextStyle(
                widget.config,
                size: 11, // Reduced from 12
                color: Colors.grey[700],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _controller.clearSelectedFile,
            icon: const Icon(Icons.close, size: 14, color: Colors.red), // Reduced
          ),
        ],
      ),
    );
  }

  Widget _buildPoweredBy() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12), // Reduced
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
            widget.config.poweredByText,
            style: TextStyleHelper.getChatTextStyle(
              widget.config,
              size: 10, // Reduced from 11
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(width: 3), // Reduced from 4
          InkWell(
            onTap: ()async {
              final Uri url = Uri.parse(widget.config.poweredByUrl);
             if(await canLaunchUrl(url)){
               await launchUrl(url);
             }
            },
            child: Text(
              widget.config.poweredByBrand,
              style: TextStyleHelper.getChatTextStyle(
                widget.config,
                size: 10, // Reduced from 11
                color: widget.config.poweredByColor,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}