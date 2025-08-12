import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wedding_app/features/auth/screens/login_screen.dart';
import 'package:wedding_app/features/dashboard/screens/client_dashboard_screen.dart';
import 'package:wedding_app/features/dashboard/screens/photographer_dashboard_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String _role = 'photographer';

  bool _loading = false;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  void _signup() async {
    setState(() {
      _loading = true;
    });

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': _emailController.text.trim(),
        'name': _nameController.text.trim(),
        'role': _role,
        'createdAt': Timestamp.now(),
      });

      // Navigate based on role
      if (_role == 'photographer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PhotographerDashboardScreen(
              photographerId: userCredential.user!.uid,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ClientDashboardScreen(clientId: userCredential.user!.uid),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Signup Error: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            Row(
              children: [
                const Text("Role: "),
                DropdownButton(
                  value: _role,
                  items: [
                    DropdownMenuItem(
                      value: 'photographer',
                      child: Text("Photographer"),
                    ),
                    DropdownMenuItem(value: 'client', child: Text("Client")),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _role = value);
                  },
                ),
              ],
            ),
            SizedBox(height: 25),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _signup,
                    child: const Text("Sign Up"),
                  ),
            TextButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              ),
              child: const Text("Already have an account? Login"),
            ),
          ],
        ),
      ),
    );
  }
}
