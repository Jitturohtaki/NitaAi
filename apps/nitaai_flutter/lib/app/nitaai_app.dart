import 'package:flutter/material.dart';

import '../services/nitaai_api.dart';
import '../ui/screens/cart/cart_screen.dart';
import '../ui/screens/chat/chat_screen.dart';
import '../ui/theme/app_theme.dart';

class NitaAiApp extends StatefulWidget {
  const NitaAiApp({super.key});

  @override
  State<NitaAiApp> createState() => _NitaAiAppState();
}

class _NitaAiAppState extends State<NitaAiApp> {
  final NitaAiApi _api = NitaAiApi();
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    ChatScreen(api: _api),
    CartScreen(api: _api),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NitaAi',
      theme: AppTheme.build(),
      home: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Chat',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_cart_outlined),
              selectedIcon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
          ],
        ),
      ),
    );
  }
}
