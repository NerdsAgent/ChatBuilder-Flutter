import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/chat_widget_controller.dart';
import '../../models/chat_message.dart';
import '../../models/chat_widget_config.dart';
import '../../utils/text_style_helper.dart';

class ChatBubbleWidget extends StatelessWidget {
  final ChatMessage message;
  final ChatWidgetConfig config;
  final ChatWidgetController controller;

  const ChatBubbleWidget({
    Key? key,
    required this.message,
    required this.config,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) _buildBotAvatar(),
          if (!message.isUser) const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? config.userChatWindowColor
                        : config.botChatWindowColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: message.isUser
                          ? const Radius.circular(12)
                          : const Radius.circular(2),
                      bottomRight: message.isUser
                          ? const Radius.circular(2)
                          : const Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SelectableText(
                    message.text,
                    style: TextStyleHelper.getChatTextStyle(
                      config,
                      size: 14,
                      color: const Color(0xFF2d3e50),
                      weight: FontWeight.w400,
                    ),
                  ),
                ),
                if (config.showTimestamps)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                    child: Text(
                      controller.formatTime(message.timestamp),
                      style: TextStyleHelper.getChatTextStyle(
                        config,
                        size: 10,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (message.isUser) const SizedBox(width: 10),
          if (message.isUser) _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildBotAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: config.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: config.agentAvatarProvider != null
          ? CircleAvatar(
              radius: 16,
              backgroundImage: config.agentAvatarProvider,
              backgroundColor: Colors.transparent,
            )
          : Center(
              child: Text(
                config.agentName.length >= 2
                    ? config.agentName.substring(0, 2).toUpperCase()
                    : config.agentName.toUpperCase(),
                style: TextStyleHelper.getChatTextStyle(
                  config,
                  size: 12,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: config.accentColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}