// ignore_for_file: use_build_context_synchronously, use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:receipt_application/view_models/auth_view_model.dart';
import 'package:receipt_application/views/bottomnav_view.dart';
import 'package:receipt_application/views/register_view.dart';

class AuthView extends StatefulWidget {
  final bool isLoggedIn;

  AuthView({required this.isLoggedIn});

  @override
  _AuthViewState createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late AnimationController _logoController;
  late Animation<double> _smoothController;
  late AnimationController _fadeOutController;

  @override
  void initState() {
    super.initState();

    // Animation for moving the logo and text upward
    _logoController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _smoothController = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut, // Smooth acceleration and deceleration
    );

    // Animation for fading out the "Powered By" section and loader
    _fadeOutController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _startAnimations();
  }

  void _startAnimations() async {
    // Keep splash screen visible for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    if (widget.isLoggedIn) {
      // If logged in, skip animations and go directly to HomeView
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BottomNavView()),
      );
    } else {
      // Not logged in: Perform splash-to-login transition
      _logoController.forward(); // Move logo and text upward
      await Future.delayed(const Duration(milliseconds: 300));
      _fadeOutController.forward(); // Fade out "Powered By" section and loader
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _logoController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final double topPadding = MediaQuery.of(context).size.height * 0.915;
    final double finalYPosition =
        MediaQuery.of(context).size.height - topPadding;
    final double adjustedPosition = 1 - (finalYPosition / 100);
    final double adjustedPosition2 = 1 - (finalYPosition + 1 / 100);

    print('Original Height: $height');
    print('Padding: $topPadding');
    print('Y Translation: $finalYPosition');
    print('Final Translation: $adjustedPosition');
    print('Final Translation 2: $adjustedPosition2');

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 177, 199, 176),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Splash Screen
          AnimatedBuilder(
            animation: _logoController,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo and "ExpenseSnap" transition upward
                  Transform.translate(
                    offset: Offset(
                        0,
                        -_smoothController.value *
                            MediaQuery.of(context).size.height *
                            adjustedPosition),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: const Color.fromARGB(255, 11, 61, 68),
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/images/expenseSnap_icon.png',
                              height: 120,
                              width: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "ExpenseSnap",
                          style: TextStyle(
                            color: Color.fromARGB(255, 11, 61, 68),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // "Powered By" Section (fades out during transition)
                  FadeTransition(
                    opacity: Tween<double>(begin: 1, end: 0)
                        .animate(_fadeOutController),
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Powered By",
                              style: TextStyle(
                                color: Color.fromARGB(255, 11, 61, 68),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Image.asset(
                              'assets/images/openai_icon.png',
                              height: 20,
                              width: 20,
                            ),
                            const SizedBox(width: 8),
                            Image.asset(
                              'assets/images/google_icon.png',
                              height: 20,
                              width: 20,
                            ),
                            const SizedBox(width: 8),
                            Image.asset(
                              'assets/images/firebase_icon.png',
                              height: 20,
                              width: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Lottie.asset(
                          'assets/animations/loader.json',
                          height: 50,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          // Login Form Animation
          if (!widget.isLoggedIn)
            FadeTransition(
              opacity:
                  _fadeOutController, // Ensure the form fades in as "Powered By" fades out
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1), // Start off-screen below
                  end: Offset.zero,
                ).animate(
                    _smoothController), // Tie slide-in animation to logoController
                child: RepaintBoundary(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                              height: MediaQuery.of(context).size.height *
                                  0.32), // Push form below the logo
                          // Login Form Container
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Email Field
                                TextField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    labelText: "Email",
                                    prefixIcon: Icon(Icons.email),
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 15),
                                // Password Field
                                TextField(
                                  controller: _passwordController,
                                  decoration: const InputDecoration(
                                    labelText: "Password",
                                    prefixIcon: Icon(Icons.lock),
                                    border: OutlineInputBorder(),
                                  ),
                                  obscureText: true,
                                ),
                                const SizedBox(height: 20),
                                // Sign In with Email Button
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor:
                                        const Color.fromARGB(255, 11, 61, 68),
                                    side: const BorderSide(
                                      color: Color.fromARGB(255, 11, 61, 68),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                  onPressed: () async {
                                    final authViewModel =
                                        Provider.of<AuthViewModel>(context,
                                            listen: false);
                                    final isSuccess =
                                        await authViewModel.loginWithEmail(
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text.trim(),
                                    );
                                    if (isSuccess) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                BottomNavView()),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "Email/Password sign-in failed")),
                                      );
                                    }
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Lottie.asset(
                                        'assets/animations/login_button.json',
                                        height: 30,
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        "Sign in with Email",
                                        style: TextStyle(
                                          color:
                                              Color.fromARGB(255, 11, 61, 68),
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Divider for Separation
                                const Row(
                                  children: [
                                    Expanded(child: Divider()),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text(
                                        "OR",
                                        style: TextStyle(
                                          color:
                                              Color.fromARGB(255, 11, 61, 68),
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Divider()),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Sign In with Google Button
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Color.fromARGB(255, 11, 61, 68),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                  onPressed: () async {
                                    final authViewModel =
                                        Provider.of<AuthViewModel>(context,
                                            listen: false);
                                    final result =
                                        await authViewModel.loginWithGoogle();

                                    if (result == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "Google sign-in canceled")),
                                      );
                                    } else if (result == false) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text("Google sign-in failed")),
                                      );
                                    } else {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                BottomNavView()),
                                      );
                                    }
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Lottie.asset(
                                        'assets/animations/google_login.json',
                                        height: 30,
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        "Sign in with Google",
                                        style: TextStyle(
                                          color:
                                              Color.fromARGB(255, 11, 61, 68),
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Register Button
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color.fromARGB(255, 11, 61, 68),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => RegisterView()),
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Lottie.asset(
                                        'assets/animations/register_button.json',
                                        height: 30,
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        "Don't have an account? Register",
                                        style: TextStyle(
                                          color:
                                              Color.fromARGB(255, 11, 61, 68),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Footer Text
                          const Text(
                            "Sign in to access your account",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color.fromARGB(255, 11, 61, 68),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
