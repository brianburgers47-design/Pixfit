// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

import 'app/theme/app_theme.dart';
import 'features/entitlements/entitlement_service.dart';
import 'features/home/home_screen.dart';

Future<void> main() async {
  print('APP STARTED');
  WidgetsFlutterBinding.ensureInitialized();
  print('BINDINGS INITIALIZED');
  print('ENTITLEMENT INIT START');
  print('BEFORE INIT SERVICE');
  await EntitlementService.instance.bootstrap();
  print('AFTER INIT SERVICE');
  runApp(const PixfitApp());
  print('RUNAPP CALLED');
}

class PixfitApp extends StatelessWidget {
  const PixfitApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('APP BUILDING');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pixfit',
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
