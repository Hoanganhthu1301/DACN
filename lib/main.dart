import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/account/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/auth_service.dart';
import 'screens/dashboard_screen.dart';
import 'package:flutter/foundation.dart'; // Thêm dòng này

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Chỉ Web mới cần FirebaseOptions
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCvPd_JLGFlHVyJ3WR2eCyy1YtCaHTuJ-o",
        authDomain: "goiymonan-e8fba.firebaseapp.com",
        projectId: "goiymonan-e8fba",
        storageBucket: "goiymonan-e8fba.appspot.com",
        messagingSenderId: "655103036581",
        appId: "1:655103036581:web:340738ae9bf7ae0425514c",
        measurementId: "G-DVC9S6TSWM",
      ),
    );
  } else {
    // Android / iOS tự lấy config từ file google-services.json / GoogleService-Info.plist
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Recommendation',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const DashboardScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
