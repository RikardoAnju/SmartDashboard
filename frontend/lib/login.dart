import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // For web-specific features

import 'package:frontend/Dasboard/adminpage.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _showPassword = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Focus nodes for better web navigation
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  String get apiUrl => 'http://localhost:8080';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // Load saved credentials for web
  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('rememberedEmail');
      final rememberMe = prefs.getBool('rememberMe') ?? false;

      if (savedEmail != null && rememberMe) {
        setState(() {
          _emailController.text = savedEmail;
          _rememberMe = true;
        });
      }
    } catch (e) {
      print('Error loading saved credentials: $e');
    }
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save all tokens and user data
      await prefs.setString('accessToken', data['accessToken']);
      await prefs.setString('refreshToken', data['refreshToken']);
      await prefs.setString('userId', data['userId']);

      // Save email if remember me is checked
      if (_rememberMe) {
        await prefs.setString(
          'rememberedEmail',
          _emailController.text.trim().toLowerCase(),
        );
        await prefs.setBool('rememberMe', true);
      } else {
        await prefs.remove('rememberedEmail');
        await prefs.setBool('rememberMe', false);
      }

      print('Tokens saved successfully:');
      print('- AccessToken: ${data['accessToken'].substring(0, 20)}...');
      print('- RefreshToken: ${data['refreshToken'].substring(0, 20)}...');
      print('- UserId: ${data['userId']}');
    } catch (e) {
      print('Error saving tokens: $e');
      throw Exception('Gagal menyimpan token: $e');
    }
  }

  // Handle Enter key press for web
  void _handleKeyPress(RawKeyEvent event) {
    if (event.runtimeType == RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        _handleLogin();
      }
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final loginPayload = {
        'email': _emailController.text.trim().toLowerCase(),
        'password': _passwordController.text,
        'rememberMe': _rememberMe,
      };

      print('Login attempt: $loginPayload');
      print('Using API URL: $apiUrl');

      final response = await http.post(
        Uri.parse('$apiUrl/v1/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(loginPayload),
      );

      print('Response status: ${response.statusCode}');
      final data = json.decode(response.body);
      print('Response data: $data');

      if (response.statusCode == 200 && data['code'] == 200) {
        await _saveTokens(data);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login berhasil!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              width: 300,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Adminpage(
                userEmail: _emailController.text.trim().toLowerCase(),
                userData: data,
              ),
            ),
          );
        }
      } else {
        String errorMessage = 'Login gagal. Silakan coba lagi.';
        if (data['error'] != null) {
          errorMessage = data['error'];
        } else if (data['message'] != null) {
          errorMessage = data['message'];
        }
        _showErrorDialog(errorMessage);
      }
    } catch (error) {
      print('Login error: $error');
      if (error.toString().contains('SocketException')) {
        _showErrorDialog(
          'Tidak dapat terhubung ke server. Pastikan server backend berjalan di $apiUrl',
        );
      } else {
        _showErrorDialog('Terjadi kesalahan koneksi. Silakan coba lagi.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Login Gagal'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToRegister() {
    // TODO: Navigate to register page when needed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur registrasi akan segera tersedia'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 768;
    final isLargeScreen = screenSize.width > 1200;

    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: _handleKeyPress,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF0F9FF),
                Color(0xFFE0F2FE),
                Color(0xFFFEFCE8),
                Color(0xFFF3E8FF),
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!isSmallScreen) ...[
                      Expanded(
                        flex: isLargeScreen ? 2 : 1,
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selamat Datang di',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Piposmart Laundry',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Sistem manajemen laundry yang modern dan efisien untuk mengelola bisnis laundry Anda dengan mudah.',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF6B7280),
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],

                    // Right side - Login form
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isSmallScreen ? double.infinity : 450,
                      ),
                      child: Card(
                        elevation: 24,
                        shadowColor: Colors.black.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(isSmallScreen ? 24.0 : 40.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Header with Logo
                                Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ), 
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ), 
                                            child: Image.asset(
                                              'assets/img/logo.png',
                                              height: 32,
                                              width: 32,
                                              fit: BoxFit.contain,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return const Icon(
                                                      Icons
                                                          .local_laundry_service,
                                                      size: 32,
                                                      color: Colors.red,
                                                    );
                                                  },
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 12),
                                        const Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Piposmart',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red,
                                              ),
                                            ),
                                            Text(
                                              'Laundry',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 32),
                                    const Text(
                                      'Masuk ke Akun Anda',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Selamat datang kembali! Silakan masukkan detail Anda.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF6B7280),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),

                                // Email Field
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Email',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _emailController,
                                      focusNode: _emailFocusNode,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      onFieldSubmitted: (_) {
                                        _passwordFocusNode.requestFocus();
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Email harus diisi';
                                        }
                                        if (!RegExp(
                                          r'\S+@\S+\.\S+',
                                        ).hasMatch(value)) {
                                          return 'Format email tidak valid';
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Masukkan email Anda',
                                        prefixIcon: const Icon(
                                          Icons.email_outlined,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFD1D5DB),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFD1D5DB),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF2563EB),
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                        filled: true,
                                        fillColor: const Color(0xFFF9FAFB),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Password Field
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Password',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _passwordController,
                                      focusNode: _passwordFocusNode,
                                      obscureText: !_showPassword,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) {
                                        _handleLogin();
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Password harus diisi';
                                        }
                                        if (value.length < 6) {
                                          return 'Password minimal 6 karakter';
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Masukkan password Anda',
                                        prefixIcon: const Icon(
                                          Icons.lock_outlined,
                                        ),
                                        suffixIcon: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _showPassword = !_showPassword;
                                            });
                                          },
                                          icon: Icon(
                                            _showPassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: const Color(0xFF6B7280),
                                          ),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFD1D5DB),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFD1D5DB),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF2563EB),
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                        filled: true,
                                        fillColor: const Color(0xFFF9FAFB),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                           

                                // Login Button
                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: const Color(
                                        0xFF9CA3AF,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : const Text(
                                            'Masuk',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Register Link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                 
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
       
      ),
    );
  }
}

class AnimatedTrustIndicator extends StatefulWidget {
  final IconData icon;
  final String text;

  const AnimatedTrustIndicator({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  State<AnimatedTrustIndicator> createState() => _AnimatedTrustIndicatorState();
}

class _AnimatedTrustIndicatorState extends State<AnimatedTrustIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              size: 16,
              color: Color(0xFF3B82F6).withOpacity(_animation.value),
            ),
            const SizedBox(width: 8),
            Text(
              widget.text,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}
