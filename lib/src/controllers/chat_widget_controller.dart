import 'dart:async';
import 'dart:developer';

import 'package:chatbuilder_flutter/src/utils/api_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/chat_widget_config.dart';


class ChatWidgetController extends ChangeNotifier {
  final ChatWidgetConfig config;
  final void Function(String message)? onMessageSent;
  final VoidCallback? onWidgetOpened;
  final VoidCallback? onWidgetClosed;

  // State
  final List<ChatMessage> _messages = [];
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  bool _isMinimized = false;
  bool _isTyping = false;
  bool _showPopup = false;
  bool _isUploading = false;
  PlatformFile? _selectedFile;

  int _messageIdCounter = 0;
  Timer? _popupTimer;
  Timer? _scrollDebounceTimer;
  String _sessionId = '';

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isMinimized => _isMinimized;
  bool get isTyping => _isTyping;
  bool get showPopup => _showPopup;
  bool get isUploading => _isUploading;
  PlatformFile? get selectedFile => _selectedFile;

  ChatWidgetController({
    required this.config,
    this.onMessageSent,
    this.onWidgetOpened,
    this.onWidgetClosed,
  }) {
    _isMinimized = config.collapsed;
    _sessionId = ApiHelper.generateSessionId();
    _initialize();
  }

  void _initialize() {
    if (config.apikey != null || config.token != null) {
      _loadAgentConfiguration();
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_isMinimized) {
        _showPopupMessage();
      } else {
        if (config.welcomeMessage.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 500), () {
            addMessage(config.welcomeMessage, isUser: false);
          });
        }
        Future.delayed(const Duration(milliseconds: 600), scrollToBottom);
      }
    });
  }

  Future<void> _loadAgentConfiguration() async {
    final configData = await ApiHelper.loadAgentConfiguration(
      agentId: config.agentId,
      apikey: config.apikey,
      token: config.token,
      enableDebug: config.enableDebug,
    );

    if (configData != null && config.enableDebug) {
      log('[Chat Widget Controller] Configuration loaded: $configData');
    }
  }

  // Message Management
  void addMessage(String text, {required bool isUser}) {
    final message = ChatMessage(
      id: 'msg-${++_messageIdCounter}',
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
    );

    _messages.add(message);
    notifyListeners();
    
    Future.delayed(const Duration(milliseconds: 100), scrollToBottom);
  }

  void updateMessage(String id, String text) {
    final index = _messages.indexWhere((m) => m.id == id);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(text: text);
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages.clear();
    textController.clear();
    _isTyping = false;
    notifyListeners();
  }

  // Send Message
  Future<void> sendMessage() async {
    final text = textController.text.trim();
    if (text.isEmpty && _selectedFile == null) return;

    if (text.isNotEmpty) {
      addMessage(text, isUser: true);
    }

    textController.clear();
    onMessageSent?.call(text);

    if (_selectedFile != null) {
      await _handleFileUpload(text.isEmpty ? null : text);
      return;
    }

    if (config.agentId.isNotEmpty) {
      await _sendMessageToAgent(text);
    }
  }

  Future<void> _sendMessageToAgent(String message) async {
    _isTyping = true;
    notifyListeners();

    try {
      if ((config.apikey == null || config.apikey!.isEmpty) &&
          (config.token == null || config.token!.isEmpty)) {
        throw Exception('No API key or token provided');
      }

      final stream = await ApiHelper.sendMessageStream(
        agentId: config.agentId,
        message: message,
        sessionId: _sessionId,
        apikey: config.apikey,
        token: config.token,
        enableDebug: config.enableDebug,
      );

      final streamMessageId = 'msg-${++_messageIdCounter}';
      final streamMessage = ChatMessage(
        id: streamMessageId,
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(streamMessage);
      notifyListeners();

      String streamedText = '';
      await for (var chunk in stream) {
        streamedText += chunk;
        updateMessage(streamMessageId, streamedText);
        _debouncedScrollToBottom();
      }

      _isTyping = false;
      notifyListeners();

      if (streamedText.trim().isEmpty) {
        updateMessage(
          streamMessageId,
          'No response received from the agent.',
        );
      }
    } catch (error) {
      if (config.enableDebug) {
        log('[Chat Widget Controller] API Error: $error');
      }
      _isTyping = false;
        log('[Chat Widget Controller] API Error: $error');
      notifyListeners();
      addMessage(
        'Sorry, I encountered an error. Please try again.',
        isUser: false,
      );
    }
  }

  Future<void> _handleFileUpload(String? message) async {
    if (_selectedFile == null) return;

    _isUploading = true;
    final fileMessageId = 'msg-${++_messageIdCounter}';
    notifyListeners();

    try {
      final fileMessage = ChatMessage(
        id: fileMessageId,
        text: '📎 Uploading ${_selectedFile!.name}...',
        isUser: true,
        timestamp: DateTime.now(),
      );
      _messages.add(fileMessage);
      notifyListeners();

      final result = await ApiHelper.sendFileMessage(
        agentId: config.agentId,
        fileName: _selectedFile!.name,
        fileBytes: _selectedFile!.bytes!,
        sessionId: _sessionId,
        message: message,
        apikey: config.apikey,
        token: config.token,
        enableDebug: config.enableDebug,
      );

      updateMessage(
        fileMessageId,
        '📎 ${_selectedFile!.name} uploaded successfully',
      );

      clearSelectedFile();

      if (result != null &&
          result['status_code'] == 200 &&
          result['data'] != null &&
          result['data']['response'] != null) {
        final responseText = result['data']['response'] as String;
        addMessage(responseText, isUser: false);
      } else {
        addMessage(
          'File uploaded successfully, but no response received from the agent.',
          isUser: false,
        );
      }
    } catch (error) {
      if (config.enableDebug) {
        log('[Chat Widget Controller] File upload error: $error');
      }
      updateMessage(fileMessageId, 'Failed to upload ${_selectedFile!.name}');
      addMessage(
        'Failed to upload file. Please try again.',
        isUser: false,
      );
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  // File Management
  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'gif',
          'webp',
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'txt',
          'csv'
        ],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Check file size (10MB limit)
        if (file.size > 10 * 1024 * 1024) {
          addMessage(
            'File size too large. Please upload files smaller than 10MB.',
            isUser: false,
          );
          return;
        }

        _selectedFile = file;
        notifyListeners();
      }
    } catch (e) {
      if (config.enableDebug) {
        log('[Chat Widget Controller] File picker error: $e');
      }
    }
  }

  void clearSelectedFile() {
    _selectedFile = null;
    notifyListeners();
  }

  // Widget State Management
  void toggleMinimize() {
    _isMinimized = !_isMinimized;
    notifyListeners();

    if (_isMinimized) {
      Future.delayed(const Duration(milliseconds: 100), _showPopupMessage);
      onWidgetClosed?.call();
    } else {
      _showPopup = false;
      notifyListeners();
      onWidgetOpened?.call();
    }
  }

  void closeWidget() {
    _isMinimized = true;
    clearMessages();
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 100), _showPopupMessage);
    onWidgetClosed?.call();
  }

  void openWidget() {
    _isMinimized = false;
    _showPopup = false;
    notifyListeners();

    if (_messages.isEmpty && config.welcomeMessage.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        addMessage(config.welcomeMessage, isUser: false);
      });
    }

    Future.delayed(const Duration(milliseconds: 100), scrollToBottom);
    onWidgetOpened?.call();
  }

  void _showPopupMessage() {
    _popupTimer?.cancel();

    Future.delayed(
      Duration(seconds: config.popupShowDelay),
      () {
        if (_isMinimized) {
          _showPopup = true;
          notifyListeners();

          _popupTimer = Timer(
            Duration(seconds: config.popupHideDelay),
            () {
              _showPopup = false;
              notifyListeners();
            },
          );
        }
      },
    );
  }

  // Scroll Management
  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _debouncedScrollToBottom() {
    _scrollDebounceTimer?.cancel();
    _scrollDebounceTimer = Timer(
      const Duration(milliseconds: 100),
      scrollToBottom,
    );
  }

  String formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  void dispose() {
    textController.dispose();
    scrollController.dispose();
    _popupTimer?.cancel();
    _scrollDebounceTimer?.cancel();
    super.dispose();
  }
}