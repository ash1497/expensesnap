import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:receipt_application/view_models/auth_view_model.dart';
import 'package:receipt_application/view_models/history_view_model.dart';
import 'package:receipt_application/view_models/image_view_model.dart';
import 'package:receipt_application/view_models/bottomnav_view_model.dart';
import 'package:receipt_application/views/auth_view.dart';
import 'package:receipt_application/views/bottomnav_view.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock the app orientation to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize the AuthViewModel and check login status
  final authViewModel = AuthViewModel();
  await authViewModel.checkLoginStatus();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authViewModel), // AuthViewModel
        ChangeNotifierProvider(
            create: (_) => ImageViewModel()), // ImageViewModel
        ChangeNotifierProvider(
            create: (_) => BottomNavViewModel()), // BottomNavViewModel
        ChangeNotifierProvider(
            create: (_) => HistoryViewModel()), // HistoryViewModel
      ],
      child: MyApp(authViewModel: authViewModel),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthViewModel authViewModel;

  MyApp({required this.authViewModel});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ExpenseSnap',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Always start at AuthView and pass the isLoggedIn flag
      home: AuthView(isLoggedIn: authViewModel.uid != null),
    );
  }
}
