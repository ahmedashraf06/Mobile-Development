import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

Future<void> saveCitizenFcmToken() async {
  final token = await FirebaseMessaging.instance.getToken();
  final user = FirebaseAuth.instance.currentUser;

  if (token != null && user != null) {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'fcmToken': token,
    });
  }
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  bool _hasLoginError = false;

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _hasLoginError = false;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (email == 'admin@balaghny.online') {
        Navigator.pushReplacementNamed(context, '/government/home');
      } else {
        Navigator.pushReplacementNamed(context, '/citizen/home');
      }
    } on FirebaseAuthException {
      setState(() => _hasLoginError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email or password is incorrect'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(8));
    const inputBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: Color(0xFFCED4DA)),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Hello',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'Again!',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 45,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1877F2),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Welcome back you’ve been missed',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 32),

                _buildLabeledField(
                  label: 'Email*',
                  child: TextFormField(
                    controller: _emailController,
                    style: const TextStyle(
                      // Input text color
                      fontFamily: 'Poppins',
                      color: Color(0xFF4E4B66),
                    ),
                    decoration: InputDecoration(
                      hintText: 'name@example.com',
                      hintStyle: const TextStyle(
                        // Hint text color
                        color: Color(0xFF4E4B66),
                        fontFamily: 'Poppins',
                      ),
                      enabledBorder: inputBorder,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color:
                              _hasLoginError
                                  ? Colors.red
                                  : const Color(0xFFCED4DA),
                        ),
                      ),
                    ),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: 16),

                _buildLabeledField(
                  label: 'Password*',
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF4E4B66),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Your password',
                      hintStyle: const TextStyle(
                        color: Color(0xFF4E4B66),
                        fontFamily: 'Poppins',
                      ),
                      enabledBorder: inputBorder,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color:
                              _hasLoginError
                                  ? Colors.red
                                  : const Color(0xFFCED4DA),
                        ),
                      ),

                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF4E4B66),
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1877F2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        _loading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              'Login',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 16),

                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/signup');
                    },
                    child: const Text.rich(
                      TextSpan(
                        text: 'Don’t have an account ? ',
                        style: TextStyle(fontFamily: 'Poppins'),
                        children: [
                          TextSpan(
                            text: 'Sign Up',
                            style: TextStyle(
                              color: Color(0xFF1877F2),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/advertiser');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC043),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Post an advertisement now!',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
