import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  

  try {
    await dotenv.load(fileName: "assets/.env");
  } catch (e) {
    print('Error loading .env file: $e');
    
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login App',
      theme: ThemeData(
        primarySwatch: Colors.blue, 
        useMaterial3: true,
        // Optional: Add custom theme configurations
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2563EB),
          foregroundColor: Colors.white,
        ),
      ),
      // Directly set LoginPage as home
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
      // Use onGenerateRoute for MaterialPageRoute navigation
      onGenerateRoute: (RouteSettings settings) {
        if (settings.name == '/login') {
          return MaterialPageRoute(
            builder: (context) => const LoginPage(),
          );
        }
       
        return MaterialPageRoute(
          builder: (context) => const LoginPage(),
        );
      },
    );
  }
}