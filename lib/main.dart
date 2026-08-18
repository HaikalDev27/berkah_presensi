import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/app_theme.dart';
import 'screens/sign_in_screen.dart';
import 'session/session_manager.dart';

void main() async {
  runApp(const BerkahPresensiApp());

  WidgetsFlutterBinding.ensureInitialized();
  
}

class BerkahPresensiApp extends StatelessWidget {
  const BerkahPresensiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Berkah Presensi',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      locale: const Locale('id', 'ID'),
      home: const SignInScreen(),
    );
  }
}
