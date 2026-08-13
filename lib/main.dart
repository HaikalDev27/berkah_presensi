import 'package:berkah_presensi/page/signin_page.dart';
import 'package:berkah_presensi/page/signup_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

   @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/SignIn',
      routes: {
			'/SignIn': (context) => const SignIn(),
			'/SignUp': (context) => const SignUp(),
      },
    );
  }
}