import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipt_application/view_models/auth_view_model.dart';
import 'package:lottie/lottie.dart';

// ignore: use_key_in_widget_constructors
class RegisterView extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _RegisterViewState createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _showModal(
      BuildContext context, String animationPath, String message) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(animationPath, height: 100, repeat: false),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _register(
      BuildContext context, AuthViewModel authViewModel) async {
    await _showModal(
        context, 'assets/animations/loader.json', 'Registering...');

    final isRegistered = await authViewModel.register(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _usernameController.text.trim(),
    );

    if (!context.mounted) return;

    Navigator.pop(context); // Close the loading animation

    if (isRegistered) {
      await _showModal(context, 'assets/animations/success.json',
          'Registration Successful!');
      if (context.mounted) {
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted)
            Navigator.pop(context); // Close the success modal
          if (context.mounted) Navigator.pop(context); // Navigate back to login
        });
      }
    } else {
      await _showModal(context, 'assets/animations/error.json',
          'Registration Failed. Try Again.');
      if (context.mounted) {
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) Navigator.pop(context); // Close the error modal
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    return Scaffold(
      backgroundColor:
          const Color.fromARGB(255, 177, 199, 176), // Set page background color
      appBar: AppBar(
        title: const Text(
          'Register',
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold), // Larger and bolder title
        ),
        backgroundColor: const Color.fromARGB(255, 177, 199, 176),
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Icon and Name
              Column(
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
                  const SizedBox(height: 10),
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
                ],
              ),
              const SizedBox(height: 30),
              // Registration Form
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                  fillColor: Colors.white, // Set the background color to white
                  filled: true, // Enable the background color
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                  fillColor: Colors.white, // Set the background color to white
                  filled: true, // Enable the background color
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _passwordController.text = _passwordController.text;
                      });
                    },
                  ),
                  fillColor: Colors.white, // Set the background color to white
                  filled: true, // Enable the background color
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _register(context, authViewModel),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: const Color.fromARGB(255, 27, 179, 19),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 18, // Increase font size
                    fontWeight: FontWeight.bold, // Make text bold
                  ),
                ),
                child: const Text("Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
