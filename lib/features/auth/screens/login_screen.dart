import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wedding_app/features/auth/screens/signup_screen.dart';
import 'package:wedding_app/features/dashboard/screens/client_dashboard_screen.dart';
import 'package:wedding_app/features/dashboard/screens/guest_dashboard_screen.dart';
import 'package:wedding_app/features/dashboard/screens/photographer_dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
    // checkLoginStatus(context);
  }

  Future<void> checkLoginStatus(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('rememberMe') ?? false;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && remember) {
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ,));// client dashboard or photographer dashboard
    }
  }

  void _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Step 1: Sign in
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: "${_emailController.text.trim()}@abc.com",
            password: _passwordController.text.trim(),
          );

      // Save preference if remember me is ticked
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.setBool('rememberMe', rememberMe);

      // Step 2: Get role from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists || !userDoc.data().toString().contains('role')) {
        throw FirebaseAuthException(
          code: 'no-role',
          message: 'User role not found.',
        );
      }

      String role = userDoc['role'];

      // Step 3: Navigate based on role

      if (role == 'photographer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PhotographerDashboardScreen(
              photographerId: userCredential.user!.uid,
            ),
          ),
        );
      } else if (role == 'client') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ClientDashboardScreen(clientId: userCredential.user!.uid),
          ),
        );
      } else {
        throw FirebaseAuthException(
          code: 'invalid-role',
          message: 'Invalid user role.',
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Login failed.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: rememberMe,
                  onChanged: (v) => setState(() => rememberMe = v ?? false),
                ),
                const Text('Remember me'),
              ],
            ),
            SizedBox(height: 25),
            if (_error != null)
              Text(_error!, style: TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text("Login"),
            ),
            SizedBox(height: 5),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SignupScreen()),
              ),
              child: Text(
                "Create an account",
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
            SizedBox(height: 5),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GuestDashboardScreen()),
              ),
              child: Text(
                "Guest Mode",
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
