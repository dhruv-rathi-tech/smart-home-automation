import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bluetooth_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  int _wrongAttempts = 0;
  bool _isLocked = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  Future<void> _checkPassword() async {
    if (_isLocked) {
      setState(() {
        _errorMessage = 'System locked. Restart app to try again.';
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString('app_password') ?? '1234';

    if (_passwordController.text == savedPassword) {
      _wrongAttempts = 0;
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BluetoothScreen()),
      );
    } else {
      _wrongAttempts++;
      if (_wrongAttempts >= 3) {
        setState(() {
          _isLocked = true;
          _errorMessage = 'System locked. Restart app to try again.';
        });
      } else {
        setState(() {
          _errorMessage =
              'Wrong password. ${3 - _wrongAttempts} attempt(s) left.';
        });
      }
      _passwordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.home, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Smart Home',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Enter password to continue'),
              const SizedBox(height: 32),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                onSubmitted: (_) => _checkPassword(),
              ),
              const SizedBox(height: 16),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLocked ? null : _checkPassword,
                  child: const Text('Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}