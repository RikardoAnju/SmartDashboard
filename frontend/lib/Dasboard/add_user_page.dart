import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddUserPage extends StatefulWidget {
  final String userEmail;
  final Map<String, dynamic>? userData;

  const AddUserPage({
    super.key,
    required this.userEmail,
    this.userData,
  });

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = {
    'username': TextEditingController(),
    'firstName': TextEditingController(),
    'lastName': TextEditingController(),
    'email': TextEditingController(),
    'phone': TextEditingController(),
    'password': TextEditingController(),
    'confirmPassword': TextEditingController(),
  };

  int _selectedGroup = 2;
  String _selectedStatus = 'active';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  String? _validateField(String? value, String fieldName, {int? minLength}) {
    if (value == null || value.isEmpty) return '$fieldName is required';
    if (minLength != null && value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Confirm Password is required';
    if (value != _controllers['password']!.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Clean and validate all input data
      final username = _controllers['username']!.text.trim();
      final firstName = _controllers['firstName']!.text.trim();
      final lastName = _controllers['lastName']!.text.trim();
      final email = _controllers['email']!.text.trim();
      final phone = _controllers['phone']!.text.trim();
      final password = _controllers['password']!.text;
      final confirmPassword = _controllers['confirmPassword']!.text;

     
      final requestBody = <String, dynamic>{
        "username": username,
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "phone": phone,
        "password": password,
        "confirmPassword": confirmPassword,
        "group": _selectedGroup,
        "isAktif": _selectedStatus,
        "agreeTerms": true,
      };

      // Debug print to check JSON structure
      print('Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('http://localhost:8080/v1/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          _showSnackBar(
            responseData['message'] ?? 'User created successfully',
            Colors.green,
          );
        } catch (e) {
          // If response body is not JSON, show generic success message
          _showSnackBar('User created successfully', Colors.green);
        }
        
        // Clear form after successful submission
        _clearForm();
      } else {
        String errorMessage = 'Failed to create user';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['error'] ?? errorData['message'] ?? errorMessage;
        } catch (e) {
          // If error response is not JSON, use status code
          errorMessage = 'Server error: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error details: $e');
      _showSnackBar('Error: ${e.toString().replaceFirst('Exception: ', '')}', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _controllers.values.forEach((controller) => controller.clear());
    setState(() {
      _selectedGroup = 2;
      _selectedStatus = 'active';
    });
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header Card
              _buildHeader(),
              const SizedBox(height: 24),
              
              // Form Card
              _buildFormCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.person_add, size: 32, color: Color(0xFF3B82F6)),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create New User',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                'Fill in the details to add a new user',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Username field
            _buildTextField(
              'username',
              'Username',
              Icons.person_outline,
              validator: (v) => _validateField(v, 'Username', minLength: 3),
            ),
            
            // First Name and Last Name row
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'firstName',
                    'First Name',
                    Icons.badge_outlined,
                    validator: (v) => _validateField(v, 'First Name'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    'lastName',
                    'Last Name',
                    Icons.badge_outlined,
                    validator: (v) => _validateField(v, 'Last Name'),
                  ),
                ),
              ],
            ),
            
            // Email field
            _buildTextField(
              'email',
              'Email',
              Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            
            // Phone field
            _buildTextField(
              'phone',
              'Phone',
              Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) => _validateField(v, 'Phone', minLength: 10),
            ),
            
            // Password field
            _buildTextField(
              'password',
              'Password',
              Icons.lock_outline,
              obscureText: _obscurePassword,
              validator: (v) => _validateField(v, 'Password', minLength: 8),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            
            // Confirm Password field
            _buildTextField(
              'confirmPassword',
              'Confirm Password',
              Icons.lock_outline,
              obscureText: _obscureConfirmPassword,
              validator: _validateConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
            
            // Group and Status row
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    'Group',
                    _selectedGroup,
                    [{'value': 2, 'label': 'User'}],
                    (v) => setState(() => _selectedGroup = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    'Status',
                    _selectedStatus,
                    [
                      {'value': 'active', 'label': 'Active'},
                      {'value': 'inactive', 'label': 'Inactive'},
                      {'value': 'suspended', 'label': 'Suspended'},
                    ],
                    (v) => setState(() => _selectedStatus = v!),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Submit button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'Create User',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Reset button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _clearForm,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6B7280),
                  side: const BorderSide(color: Color(0xFF6B7280)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Reset Form',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String key,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key]!,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF6B7280)),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color(0xFF3B82F6),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>(
    String label,
    T value,
    List<Map<String, dynamic>> items,
    Function(T?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<T>(
        value: value,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color(0xFF3B82F6),
              width: 2,
            ),
          ),
        ),
        items: items
            .map<DropdownMenuItem<T>>(
              (item) => DropdownMenuItem<T>(
                value: item['value'],
                child: Text(item['label']),
              ),
            )
            .toList(),
      ),
    );
  }
}