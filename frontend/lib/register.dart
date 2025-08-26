import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  
  // Form controllers
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Form data
  int _group = 1;
  bool _agreeTerms = false;
  bool _subscribeNewsletter = false;
  
  // Error messages
  Map<String, String> _errors = {};

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearError(String field) {
    setState(() {
      _errors.remove(field);
    });
  }

  bool _validateForm() {
    Map<String, String> newErrors = {};
    
    if (_usernameController.text.trim().isEmpty) {
      newErrors['username'] = 'Username harus diisi';
    } else if (_usernameController.text.trim().length < 3) {
      newErrors['username'] = 'Username minimal 3 karakter';
    }
    
    if (_firstNameController.text.trim().isEmpty) {
      newErrors['firstName'] = 'Nama depan harus diisi';
    }
    
    if (_lastNameController.text.trim().isEmpty) {
      newErrors['lastName'] = 'Nama belakang harus diisi';
    }
    
    if (_emailController.text.trim().isEmpty) {
      newErrors['email'] = 'Email harus diisi';
    } else if (!RegExp(r'\S+@\S+\.\S+').hasMatch(_emailController.text.trim())) {
      newErrors['email'] = 'Format email tidak valid';
    }
    
    if (_phoneController.text.trim().isEmpty) {
      newErrors['phone'] = 'Nomor telepon harus diisi';
    } else if (_phoneController.text.trim().length < 10) {
      newErrors['phone'] = 'Nomor telepon minimal 10 digit';
    }
    
    if (_passwordController.text.isEmpty) {
      newErrors['password'] = 'Password harus diisi';
    } else if (_passwordController.text.length < 8) {
      newErrors['password'] = 'Password minimal 8 karakter';
    }
    
    if (_passwordController.text != _confirmPasswordController.text) {
      newErrors['confirmPassword'] = 'Password tidak sama';
    }
    
    if (!_agreeTerms) {
      newErrors['agreeTerms'] = 'Anda harus menyetujui syarat dan ketentuan';
    }
    
    setState(() {
      _errors = newErrors;
    });
    
    return newErrors.isEmpty;
  }

  Future<void> _handleRegister() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Payload yang disesuaikan dengan struktur backend Go
      final registerPayload = {
        'username': _usernameController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text,
        'confirmPassword': _confirmPasswordController.text,
        'group': _group,
        'agreeTerms': _agreeTerms,
        'subscribeNewsletter': _subscribeNewsletter,
      };

      // Coba beberapa endpoint yang mungkin
      List<String> possibleEndpoints = [
       
       "http://localhost:8080/v1/auth/register"
      ];
      
      bool success = false;
      String lastError = "";
      
      for (String endpoint in possibleEndpoints) {
        try {
          final url = Uri.parse(endpoint);
          print('Trying endpoint: $endpoint');
          print('Sending payload: $registerPayload');

          final response = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(registerPayload),
          ).timeout(
            const Duration(seconds: 10),
          );

          print('Response status: ${response.statusCode}');
          print('Response body: ${response.body}');

          // Jika tidak 404, berarti endpoint ditemukan
          if (response.statusCode != 404) {
            // Handle response
            if (response.statusCode == 200 || response.statusCode == 201) {
              _showSuccessDialog();
              _resetForm();
              success = true;
              break;
            } else {
              // Server merespon tapi ada error
              String errorMessage = 'Registrasi gagal (${response.statusCode})';
              
              if (response.body.isNotEmpty) {
                try {
                  final data = json.decode(response.body);
                  if (data['error'] != null) {
                    errorMessage = data['error'].toString();
                    _handleSpecificError(errorMessage);
                    success = true; // Error ditangani
                    break;
                  } else if (data['message'] != null) {
                    errorMessage = data['message'].toString();
                  }
                } catch (e) {
                  // Response bukan JSON
                  if (response.body.length < 200) {
                    errorMessage = response.body;
                  }
                }
              }
              
              _showErrorDialog(errorMessage);
              success = true;
              break;
            }
          } else {
            lastError = "Endpoint $endpoint tidak ditemukan (404)";
            print(lastError);
          }
        } catch (e) {
          print('Error trying $endpoint: $e');
          lastError = e.toString();
          continue;
        }
      }
      
      if (!success) {
        _showErrorDialog(
          'Tidak dapat menemukan endpoint registrasi yang valid.\n\n'
          'Endpoint yang dicoba:\n'
          '${possibleEndpoints.join('\n')}\n\n'
          'Pastikan:\n'
          '1. Backend Go berjalan di port 8080\n'
          '2. Endpoint registrasi sudah dikonfigurasi\n'
          '3. CORS sudah diatur dengan benar\n\n'
          'Last error: $lastError'
        );
      }
      
    } catch (error) {
      print('Registration error: $error');
      
      if (error.toString().contains('SocketException') || 
          error.toString().contains('Connection refused') ||
          error.toString().contains('Connection failed')) {
        _showErrorDialog(
          'Tidak dapat terhubung ke server.\n\n'
          'Pastikan:\n'
          '1. Backend Go berjalan di port 8080\n'
          '2. Tidak ada firewall yang memblokir\n'
          '3. Server dapat diakses dari aplikasi Flutter'
        );
      } else if (error.toString().contains('timeout')) {
        _showErrorDialog('Request timeout. Server mungkin tidak merespon dalam waktu yang wajar.');
      } else {
        _showErrorDialog('Terjadi kesalahan koneksi: ${error.toString()}');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleSpecificError(String errorMsg) {
    final errorLower = errorMsg.toLowerCase();
    
    if (errorLower.contains('username')) {
      setState(() {
        _errors['username'] = errorMsg;
      });
    } else if (errorLower.contains('email')) {
      setState(() {
        _errors['email'] = errorMsg;
      });
    } else if (errorLower.contains('phone') || errorLower.contains('telepon')) {
      setState(() {
        _errors['phone'] = errorMsg;
      });
    } else if (errorLower.contains('password')) {
      setState(() {
        _errors['password'] = errorMsg;
      });
    } else if (errorLower.contains('group')) {
      setState(() {
        _errors['group'] = errorMsg;
      });
    } else {
      _showErrorDialog(errorMsg);
    }
  }

  void _resetForm() {
    _usernameController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _group = 1;
      _agreeTerms = false;
      _subscribeNewsletter = false;
      _errors.clear();
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Berhasil!'),
            ],
          ),
          content: const Text('Registrasi berhasil! Silakan login untuk melanjutkan.'),
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('Error'),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(message),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar tanpa test connection button
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0F9FF), // blue-50
              Color(0xFFF0F9FF), // blue-50
              Color(0xFFFEFCE8), // yellow-50
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Card(
                  elevation: 20,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(32.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Server Info
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue, size: 16),
                                SizedBox(width: 8),
                                
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Header
                          const Column(
                            children: [
                              Text(
                                'Silahkan Anda Membuat Akun',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Akun akan dibuat dengan role Owner',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Username Field
                          _buildTextField(
                            controller: _usernameController,
                            label: 'Username',
                            hint: 'john_doe',
                            errorKey: 'username',
                          ),
                          const SizedBox(height: 24),

                          // Name Fields
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _firstNameController,
                                  label: 'Nama Depan',
                                  hint: 'John',
                                  errorKey: 'firstName',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _lastNameController,
                                  label: 'Nama Belakang',
                                  hint: 'Doe',
                                  errorKey: 'lastName',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Email Field
                          _buildTextField(
                            controller: _emailController,
                            label: 'Alamat Email',
                            hint: 'john.doe@example.com',
                            keyboardType: TextInputType.emailAddress,
                            errorKey: 'email',
                          ),
                          const SizedBox(height: 24),

                          // Phone Field
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Nomor Telepon',
                            hint: '08123456789',
                            keyboardType: TextInputType.phone,
                            errorKey: 'phone',
                          ),
                          const SizedBox(height: 24),

                          // Password Field
                          _buildPasswordField(
                            controller: _passwordController,
                            label: 'Kata Sandi',
                            hint: 'Minimal 8 karakter',
                            isPassword: true,
                            showPassword: _showPassword,
                            onToggleVisibility: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                            errorKey: 'password',
                          ),
                          const SizedBox(height: 24),

                          // Confirm Password Field
                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            label: 'Konfirmasi Kata Sandi',
                            hint: 'Ulangi kata sandi',
                            isPassword: true,
                            showPassword: _showConfirmPassword,
                            onToggleVisibility: () {
                              setState(() {
                                _showConfirmPassword = !_showConfirmPassword;
                              });
                            },
                            errorKey: 'confirmPassword',
                          ),
                          const SizedBox(height: 24),

                          // Terms and Newsletter
                          Column(
                            children: [
                              // Terms Checkbox
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: _agreeTerms,
                                    onChanged: (value) {
                                      setState(() {
                                        _agreeTerms = value ?? false;
                                      });
                                      _clearError('agreeTerms');
                                    },
                                    activeColor: const Color(0xFF2563EB),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _agreeTerms = !_agreeTerms;
                                        });
                                        _clearError('agreeTerms');
                                      },
                                      child: const Text(
                                        'Saya menyetujui Syarat & Ketentuan dan Kebijakan Privasi',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_errors['agreeTerms'] != null)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 16),
                                    child: Text(
                                      _errors['agreeTerms']!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),

                              // Newsletter Checkbox
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: _subscribeNewsletter,
                                    onChanged: (value) {
                                      setState(() {
                                        _subscribeNewsletter = value ?? false;
                                      });
                                    },
                                    activeColor: const Color(0xFF2563EB),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _subscribeNewsletter = !_subscribeNewsletter;
                                        });
                                      },
                                      child: const Text(
                                        'Saya ingin menerima newsletter dan penawaran khusus dari NutriBite',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Register Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 4,
                            ),
                            child: _isLoading
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text('Membuat Akun...'),
                                    ],
                                  )
                                : const Text(
                                    'Buat Akun sebagai Owner',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 32),

                          // Divider
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: const Text(
                                  'Atau daftar dengan',
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Login Link
                          Center(
                            child: RichText(
                              text: TextSpan(
                                text: 'Sudah punya akun? ',
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 14,
                                ),
                                children: [
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: () {
                                        // Navigate to login
                                      },
                                      child: const Text(
                                        'Masuk di sini',
                                        style: TextStyle(
                                          color: Color(0xFF2563EB),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.transparent,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 12, color: Color(0xFF6B7280)),
            SizedBox(width: 8),
            Text(
              'Data Aman',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
            SizedBox(width: 24),
            Icon(Icons.free_cancellation, size: 12, color: Color(0xFF6B7280)),
            SizedBox(width: 8),
            Text(
              'Gratis Mendaftar',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String errorKey,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: (value) => _clearError(errorKey),
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _errors[errorKey] != null ? Colors.red : const Color(0xFFD1D5DB),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _errors[errorKey] != null ? Colors.red : const Color(0xFFD1D5DB),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        if (_errors[errorKey] != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _errors[errorKey]!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isPassword,
    required bool showPassword,
    required VoidCallback onToggleVisibility,
    required String errorKey,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !showPassword,
          onChanged: (value) => _clearError(errorKey),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: IconButton(
              onPressed: onToggleVisibility,
              icon: Icon(
                showPassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF6B7280),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _errors[errorKey] != null ? Colors.red : const Color(0xFFD1D5DB),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _errors[errorKey] != null ? Colors.red : const Color(0xFFD1D5DB),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        if (_errors[errorKey] != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _errors[errorKey]!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}