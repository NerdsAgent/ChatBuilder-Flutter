// import 'package:flutter/material.dart';
// import 'package:nerdagent/shared/services/auth/token_manager.dart';
// import 'package:nerdagent/shared/widgets/nerd_chat_widget/models/chat_widget_config.dart';
// import 'package:nerdagent/shared/widgets/nerd_chat_widget/models/widget_position.dart';
// import 'package:nerdagent/shared/widgets/nerd_chat_widget/view/nerd_chat_view.dart';

// class DemoPage extends StatefulWidget {
//   const DemoPage({Key? key}) : super(key: key);

//   @override
//   State<DemoPage> createState() => _DemoPageState();
// }

// class _DemoPageState extends State<DemoPage> {
//   String _selectedTheme = 'default';
//   WidgetPosition _position = WidgetPosition.bottomRight;
//   bool _collapsed = false;

//   Future<ChatWidgetConfig> _getConfig() async {
//     switch (_selectedTheme) {
//       case 'dark':
//         return ChatWidgetConfig(
//           agentName: 'Dark Support',
//           agentRole: 'Night Mode Agent',
//           agentId: '124',
//           apikey: 'DT_your_api_key',
//           enableDebug: true,
//           primaryColor: const Color(0xFF1a1a1a),
//           accentColor: const Color(0xFF6200EA),
//           welcomeMessage: 'Welcome to dark mode support!',
//           enableFileUpload: true,
//           position: _position,
//           collapsed: _collapsed,
//           headerTextColor: Colors.white,
//           userChatWindowColor: const Color(0xFF424242),
//           botChatWindowColor: const Color(0xFF2d2d2d),
//         );

//       case 'colorful':
//         return ChatWidgetConfig(
//           agentName: 'Happy Helper',
//           agentRole: 'Colorful Assistant',
//           agentId: '12',
//           apikey: 'DT_your_api_key',
//           enableDebug: true,
//           primaryColor: const Color(0xFFE91E63),
//           accentColor: const Color(0xFF00BCD4),
//           welcomeMessage: 'Hello! Ready to brighten your day! 🌈',
//           enableFileUpload: true,
//           showTimestamps: true,
//           position: _position,
//           collapsed: _collapsed,
//           fontFamily: 'Roboto',
//           headerTextColor: Colors.white,
//           userChatWindowColor: const Color(0xFFFCE4EC),
//           botChatWindowColor: const Color(0xFFE0F7FA),
//         );

//       case 'minimal':
//         return ChatWidgetConfig(
//           agentName: 'Assistant',
//           agentRole: 'Support',
//           agentId: '12',
//           apikey: 'DT_your_api_key',
//           enableDebug: true,
//           primaryColor: const Color(0xFF000000),
//           accentColor: const Color(0xFF000000),
//           welcomeMessage: 'How can I assist you?',
//           enableFileUpload: false,
//           showTimestamps: false,
//           showPoweredBy: false,
//           position: _position,
//           collapsed: _collapsed,
//           enablePulsingAnimation: false,
//           fontFamily: 'Arial',
//           headerTextColor: Colors.white,
//           userChatWindowColor: const Color(0xFFF5F5F5),
//           botChatWindowColor: const Color(0xFFFFFFFF),
//         );

//       default:
//         return ChatWidgetConfig(
//           agentName: 'Support Agent',
//           agentRole: 'Customer Support',
//           agentId: '124',
//           apikey: 'DT_your_api_key',
//           enableDebug: true,
//           primaryColor: const Color(0xFF2d3e50),
//           accentColor: const Color(0xFF4e8cff),
//           welcomeMessage: 'Hi! How can I help you today?',
//           placeholderText: 'Type your message...',
//           enableFileUpload: true,
//           showTimestamps: true,
//           position: _position,
//           collapsed: _collapsed,
//           token: await TokenManager.getAccessToken(),
//         );
//     }
//   }

//   // Determine if we're in mobile or web view
//   bool _isMobile(BuildContext context) {
//     return MediaQuery.of(context).size.width < 600;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isMobile = _isMobile(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Nerd Chat Widget Demo'),
//         centerTitle: true,
//       ),
//       body: Stack(
//          fit: StackFit.expand,
//         children: [
//           // Main content with proper bottom padding
//           SingleChildScrollView(
//             padding: EdgeInsets.only(
//               left: 20,
//               right: 20,
//               top: 20,
//               bottom: isMobile ? 100 : 140, // Extra padding for chat widget
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Chat Widget Demo',
//                   style: TextStyle(
//                     fontSize: 32,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 const Text(
//                   'Try out different themes and configurations for the chat widget.',
//                   style: TextStyle(fontSize: 16, color: Colors.grey),
//                 ),
//                 const SizedBox(height: 32),

//                 // Theme Selection
//                 Card(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Theme',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Wrap(
//                           spacing: 8,
//                           runSpacing: 8,
//                           children: [
//                             _ThemeChip(
//                               label: 'Default',
//                               value: 'default',
//                               groupValue: _selectedTheme,
//                               onSelected: (value) {
//                                 setState(() => _selectedTheme = value);
//                               },
//                             ),
//                             _ThemeChip(
//                               label: 'Dark',
//                               value: 'dark',
//                               groupValue: _selectedTheme,
//                               onSelected: (value) {
//                                 setState(() => _selectedTheme = value);
//                               },
//                             ),
//                             _ThemeChip(
//                               label: 'Colorful',
//                               value: 'colorful',
//                               groupValue: _selectedTheme,
//                               onSelected: (value) {
//                                 setState(() => _selectedTheme = value);
//                               },
//                             ),
//                             _ThemeChip(
//                               label: 'Minimal',
//                               value: 'minimal',
//                               groupValue: _selectedTheme,
//                               onSelected: (value) {
//                                 setState(() => _selectedTheme = value);
//                               },
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),

//                 // Position Selection
//                 Card(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Position',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Wrap(
//                           spacing: 8,
//                           runSpacing: 8,
//                           children: [
//                             _PositionChip(
//                               label: 'Bottom Right',
//                               value: WidgetPosition.bottomRight,
//                               groupValue: _position,
//                               onSelected: (value) {
//                                 setState(() => _position = value);
//                               },
//                             ),
//                             _PositionChip(
//                               label: 'Bottom Left',
//                               value: WidgetPosition.bottomLeft,
//                               groupValue: _position,
//                               onSelected: (value) {
//                                 setState(() => _position = value);
//                               },
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),

//                 // Options
//                 Card(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Options',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         SwitchListTile(
//                           title: const Text('Start Collapsed'),
//                           subtitle: const Text(
//                             'Widget starts minimized',
//                           ),
//                           value: _collapsed,
//                           onChanged: (value) {
//                             setState(() => _collapsed = value);
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),

//                 // Features
//                 Card(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Features',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         const _FeatureItem(
//                           icon: Icons.chat,
//                           title: 'Real-time Streaming',
//                           description: 'AI responses stream in real-time',
//                         ),
//                         const _FeatureItem(
//                           icon: Icons.attach_file,
//                           title: 'File Upload',
//                           description: 'Support for images, PDFs, and documents',
//                         ),
//                         const _FeatureItem(
//                           icon: Icons.palette,
//                           title: 'Customizable',
//                           description: 'Fully customizable colors and fonts',
//                         ),
//                         const _FeatureItem(
//                           icon: Icons.security,
//                           title: 'Secure',
//                           description: 'API key or JWT authentication',
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 32),
//               ],
//             ),
//           ),

//           // Chat Widget with responsive configuration
//           FutureBuilder<ChatWidgetConfig>(
//             future: _getConfig(),
//             builder: (context, asyncSnapshot) {
//               if (asyncSnapshot.connectionState == ConnectionState.waiting) {
//                 return const SizedBox.shrink();
//               }

//               if (!asyncSnapshot.hasData) {
//                 return const SizedBox.shrink();
//               }

//               // Adjust widget size for mobile
//               final config = asyncSnapshot.data!;
//               final adjustedConfig = isMobile
//                   ? config.copyWith(
//                       width: MediaQuery.of(context).size.width - 40,
//                       height: MediaQuery.of(context).size.height * 0.7,
//                     )
//                   : config;

//               return NerdChatWidget(
//                 key: ValueKey('$_selectedTheme-$_position-$_collapsed'),
//                 config: adjustedConfig,
//                 onMessageSent: (message) {
//                   debugPrint('Message sent: $message');
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text('Sent: $message'),
//                       duration: const Duration(seconds: 1),
//                     ),
//                   );
//                 },
//                 onWidgetOpened: () {
//                   debugPrint('Widget opened');
//                 },
//                 onWidgetClosed: () {
//                   debugPrint('Widget closed');
//                 },
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Helper Widgets

// class _ThemeChip extends StatelessWidget {
//   final String label;
//   final String value;
//   final String groupValue;
//   final ValueChanged<String> onSelected;

//   const _ThemeChip({
//     required this.label,
//     required this.value,
//     required this.groupValue,
//     required this.onSelected,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isSelected = value == groupValue;
//     return FilterChip(
//       label: Text(label),
//       selected: isSelected,
//       onSelected: (_) => onSelected(value),
//       backgroundColor: Colors.grey[200],
//       selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
//       checkmarkColor: Theme.of(context).primaryColor,
//     );
//   }
// }

// class _PositionChip extends StatelessWidget {
//   final String label;
//   final WidgetPosition value;
//   final WidgetPosition groupValue;
//   final ValueChanged<WidgetPosition> onSelected;

//   const _PositionChip({
//     required this.label,
//     required this.value,
//     required this.groupValue,
//     required this.onSelected,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isSelected = value == groupValue;
//     return FilterChip(
//       label: Text(label),
//       selected: isSelected,
//       onSelected: (_) => onSelected(value),
//       backgroundColor: Colors.grey[200],
//       selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
//       checkmarkColor: Theme.of(context).primaryColor,
//     );
//   }
// }

// class _FeatureItem extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final String description;

//   const _FeatureItem({
//     required this.icon,
//     required this.title,
//     required this.description,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         children: [
//           Icon(icon, color: Theme.of(context).primaryColor),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w600,
//                     fontSize: 16,
//                   ),
//                 ),
//                 Text(
//                   description,
//                   style: TextStyle(
//                     color: Colors.grey[600],
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }