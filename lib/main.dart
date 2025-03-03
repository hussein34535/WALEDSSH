import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vpn_client/pages/main/main_page.dart';
import 'package:vpn_client/theme_provider.dart';

import 'design/colors.dart';

void main() {

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VPN Client',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeProvider.themeMode,
      home: const HomePage(),
    );
  }
}