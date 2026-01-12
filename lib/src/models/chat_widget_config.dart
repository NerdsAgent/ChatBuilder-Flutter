import 'package:flutter/material.dart';
import 'widget_position.dart';

class ChatWidgetConfig {
  // Agent Information
  final String agentName;
  final String agentRole;
  final String? agentAvatar;

  // Appearance
  final Color primaryColor;
  final Color accentColor;
  final String fontFamily;
  final List<String> fontFamilyFallbacks;
  final double width;
  final double height;

  // Messages
  final String welcomeMessage;
  final String thankYouMessage;
  final String placeholderText;

  // Features
  final bool showMinimizeButton;
  final bool enableFileUpload;
  final bool enableSpeech;
  final bool showTimestamps;
  final bool collapsed;

  // Position
  final WidgetPosition position;

  // Branding
  final bool showPoweredBy;
  final String? poweredByLogo;
  final String poweredByText;
  final String poweredByBrand;
  final String poweredByUrl;
  final Color poweredByColor;

  // API
  // final String agentId;
  // final String? apikey;
  final String? token;
  final String? apiEndpoint;
  final bool enableDebug;

  // Advanced
  final int zIndex;

  // Animation and Popup
  final bool enablePulsingAnimation;
  final String popupMessage;
  final int popupShowDelay;
  final int popupHideDelay;

  // Colors
  final Color headerTextColor;
  final Color userChatWindowColor;
  final Color botChatWindowColor;

  ChatWidgetConfig({
    this.agentName = 'Support Agent',
    this.agentRole = 'Customer Support',
    this.agentAvatar,
    this.primaryColor = const Color(0xFF2d3e50),
    this.accentColor = const Color(0xFF4e8cff),
    this.fontFamily = 'Segoe UI',
    this.fontFamilyFallbacks = const ['Arial', 'sans-serif'],
    this.width = 350,
    this.height = 500,
    this.welcomeMessage = 'Hi! How can I help you today?',
    this.thankYouMessage = 'Thank you for chatting with us!',
    this.placeholderText = 'Type your message...',
    this.showMinimizeButton = true,
    this.enableFileUpload = false,
    this.enableSpeech = false,
    this.showTimestamps = true,
    this.collapsed = false,
    this.position = WidgetPosition.bottomLeft,
    this.showPoweredBy = true,
    this.poweredByLogo,
    this.poweredByText = 'Powered by',
    this.poweredByBrand = 'NerdAgent',
    this.poweredByUrl = 'https://nerdagent.com',
    this.poweredByColor = const Color(0xFF4e8cff),
    // this.agentId = '',
    // this.apikey,
    this.token,
    this.apiEndpoint,
    this.enableDebug = false,
    this.zIndex = 10000,
    this.enablePulsingAnimation = true,
    this.popupMessage = 'Hi, How can I help you?',
    this.popupShowDelay = 2,
    this.popupHideDelay = 5,
    this.headerTextColor = Colors.white,
    this.userChatWindowColor = const Color(0xFFe6f4ff),
    this.botChatWindowColor = const Color(0xFFeafbe7),
  });

  ImageProvider? get agentAvatarProvider {
    if (agentAvatar != null && agentAvatar!.isNotEmpty) {
      return NetworkImage(agentAvatar!);
    }
    return null;
  }

  String getAgentAvatarUrl() {
    if (agentAvatar != null && agentAvatar!.trim().isNotEmpty) {
      return agentAvatar!;
    }

    final encodedName = Uri.encodeComponent(agentName);
    return 'https://ui-avatars.com/api/?name=$encodedName&background=2d3e50&color=ffffff&size=44';
  }

  ChatWidgetConfig copyWith({
    String? agentName,
    String? agentRole,
    String? agentAvatar,
    Color? primaryColor,
    Color? accentColor,
    String? fontFamily,
    List<String>? fontFamilyFallbacks,
    double? width,
    double? height,
    String? welcomeMessage,
    String? thankYouMessage,
    String? placeholderText,
    bool? showMinimizeButton,
    bool? enableFileUpload,
    bool? enableSpeech,
    bool? showTimestamps,
    bool? collapsed,
    WidgetPosition? position,
    bool? showPoweredBy,
    String? poweredByLogo,
    String? poweredByText,
    String? poweredByBrand,
    String? poweredByUrl,
    Color? poweredByColor,
    String? agentId,
    String? apikey,
    String? token,
    String? apiEndpoint,
    bool? enableDebug,
    int? zIndex,
    bool? enablePulsingAnimation,
    String? popupMessage,
    int? popupShowDelay,
    int? popupHideDelay,
    Color? headerTextColor,
    Color? userChatWindowColor,
    Color? botChatWindowColor,
  }) {
    return ChatWidgetConfig(
      agentName: agentName ?? this.agentName,
      agentRole: agentRole ?? this.agentRole,
      agentAvatar: agentAvatar ?? this.agentAvatar,
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      fontFamily: fontFamily ?? this.fontFamily,
      fontFamilyFallbacks: fontFamilyFallbacks ?? this.fontFamilyFallbacks,
      width: width ?? this.width,
      height: height ?? this.height,
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
      thankYouMessage: thankYouMessage ?? this.thankYouMessage,
      placeholderText: placeholderText ?? this.placeholderText,
      showMinimizeButton: showMinimizeButton ?? this.showMinimizeButton,
      enableFileUpload: enableFileUpload ?? this.enableFileUpload,
      enableSpeech: enableSpeech ?? this.enableSpeech,
      showTimestamps: showTimestamps ?? this.showTimestamps,
      collapsed: collapsed ?? this.collapsed,
      position: position ?? this.position,
      showPoweredBy: showPoweredBy ?? this.showPoweredBy,
      poweredByLogo: poweredByLogo ?? this.poweredByLogo,
      poweredByText: poweredByText ?? this.poweredByText,
      poweredByBrand: poweredByBrand ?? this.poweredByBrand,
      poweredByUrl: poweredByUrl ?? this.poweredByUrl,
      poweredByColor: poweredByColor ?? this.poweredByColor,
      // agentId: agentId ?? this.agentId,
      // apikey: apikey ?? this.apikey,
      token: token ?? this.token,
      apiEndpoint: apiEndpoint ?? this.apiEndpoint,
      enableDebug: enableDebug ?? this.enableDebug,
      zIndex: zIndex ?? this.zIndex,
      enablePulsingAnimation:
          enablePulsingAnimation ?? this.enablePulsingAnimation,
      popupMessage: popupMessage ?? this.popupMessage,
      popupShowDelay: popupShowDelay ?? this.popupShowDelay,
      popupHideDelay: popupHideDelay ?? this.popupHideDelay,
      headerTextColor: headerTextColor ?? this.headerTextColor,
      userChatWindowColor: userChatWindowColor ?? this.userChatWindowColor,
      botChatWindowColor: botChatWindowColor ?? this.botChatWindowColor,
    );
  }
}