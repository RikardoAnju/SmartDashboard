import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TasksPage extends StatefulWidget {
  final String userEmail;
  final Map<String, dynamic>? userData;

  const TasksPage({
    super.key,
    required this.userEmail,
    this.userData,
  });

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  List<dynamic> users = [];
  bool isLoading = true;
  String? accessToken;

  /// ✅ Helper: base URL sesuai platform
  String getBaseUrl() {
    if (kIsWeb) {
      return "http://localhost:8080"; // Flutter Web
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:8080"; // Android Emulator
    } else {
      return "http://127.0.0.1:8080"; // iOS Simulator / Desktop
    }
  }


  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      print('Retrieved token: ${token?.substring(0, 20)}...'); 
      return token;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  
  Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', token);
      print('Token saved successfully');
    } catch (e) {
      print('Error saving token: $e');
    }
  }

 
  Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
      await prefs.remove('userId');
      print('Tokens cleared');
    } catch (e) {
      print('Error clearing tokens: $e');
    }
  }

  /// ✅ Helper: Create headers with JWT token
  Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  @override
  void initState() {
    super.initState();
   
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchUsers();
    });
  }

  Future<void> fetchUsers() async {
    setState(() => isLoading = true);

    try {
      // Ambil token dari penyimpanan lokal
      final token = await getToken();

      if (token == null || token.isEmpty) {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Token tidak ditemukan. Silakan login ulang.")),
          );
          // Navigate to login page
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      print('Fetching users with token: ${token.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse("${getBaseUrl()}/v1/users/"),
        headers: headers,
      );

      print('Fetch users response status: ${response.statusCode}');
      print('Fetch users response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['code'] == 200) {
          // Backend uses 'user_data' not 'data'
          final userData = responseData['user_data'] ?? responseData['data'];
          if (userData != null) {
            setState(() {
              users = userData;
              isLoading = false;
            });
          } else {
            throw Exception('No user data found in response');
          }
        } else {
          throw Exception('Invalid response format: ${responseData['message'] ?? 'Unknown error'}');
        }
      } else if (response.statusCode == 401) {
        // Token expired / invalid - clear stored token
        await clearToken();
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Session expired. Please login again.")),
          );
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } else {
        setState(() => isLoading = false);
        final errorBody = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal mengambil data user: ${errorBody['error'] ?? response.statusCode}")),
          );
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Fetch users error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  /// Modal Edit User dengan Password Field
void showEditUserDialog(Map<String, dynamic> user) {
  final usernameController = TextEditingController(text: user["username"]);
  final emailController = TextEditingController(text: user["email"]);
  final firstNameController = TextEditingController(text: user["firstName"] ?? "");
  final lastNameController = TextEditingController(text: user["lastName"] ?? "");
  final phoneController = TextEditingController(text: user["phone"] ?? "");
  final passwordController = TextEditingController(); // ✅ Tambahkan password field
  
  bool obscurePassword = true; // untuk hide/show password

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder( // ✅ Gunakan StatefulBuilder untuk bisa update UI
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Edit User"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameController, 
                    decoration: const InputDecoration(labelText: "Username")
                  ),
                  TextField(
                    controller: firstNameController, 
                    decoration: const InputDecoration(labelText: "First Name")
                  ),
                  TextField(
                    controller: lastNameController, 
                    decoration: const InputDecoration(labelText: "Last Name")
                  ),
                  TextField(
                    controller: emailController, 
                    decoration: const InputDecoration(labelText: "Email")
                  ),
                  TextField(
                    controller: phoneController, 
                    decoration: const InputDecoration(labelText: "Phone")
                  ),
                  // ✅ Tambahkan password field
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Password *",
                      hintText: "Enter new password",
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "* Password wajib diisi",
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text("Batal")
              ),
              ElevatedButton(
                onPressed: () async {
                  // ✅ Validasi password tidak kosong
                  if (passwordController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Password tidak boleh kosong")),
                    );
                    return;
                  }

                  try {
                    final headers = await getHeaders();
                    
                    final response = await http.put(
                      Uri.parse("${getBaseUrl()}/v1/users/${user["username"]}"),
                      headers: headers,
                      body: json.encode({
                        "username": usernameController.text,
                        "firstName": firstNameController.text,
                        "lastName": lastNameController.text,
                        "email": emailController.text,
                        "phone": phoneController.text,
                        "password": passwordController.text,
                        "group": int.tryParse(user["group"].toString()) ?? 1,
                        "isAktif": user["isAktif"] ?? "active",
                      }),
                    );

                    final responseData = json.decode(response.body);

                    if (response.statusCode == 200 && responseData['code'] == 200) {
                      Navigator.pop(context);
                      fetchUsers(); // refresh
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("User berhasil diperbarui")),
                        );
                      }
                    } else if (response.statusCode == 401) {
                      await clearToken();
                      Navigator.pop(context);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Session expired. Please login again.")),
                        );
                        Navigator.of(context).pushReplacementNamed('/login');
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Gagal update user: ${responseData['message'] ?? responseData['error'] ?? 'Unknown error'}")),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e")),
                      );
                    }
                  }
                },
                child: const Text("Simpan"),
              ),
            ],
          );
        },
      );
    },
  );
}

  /// Modal Hapus
  void showDeleteUserDialog(String username) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Konfirmasi Hapus"),
          content: Text("Apakah kamu yakin ingin menghapus user '$username'?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  final headers = await getHeaders();
                  
                  final response = await http.delete(
                    Uri.parse("${getBaseUrl()}/v1/users/$username"),
                    headers: headers,
                  );

                  final responseData = json.decode(response.body);

                  if (response.statusCode == 200 && responseData['code'] == 200) {
                    Navigator.pop(context);
                    setState(() {
                      users.removeWhere((user) => user["username"] == username);
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("User berhasil dihapus")),
                      );
                    }
                  } else if (response.statusCode == 401) {
                    await clearToken();
                    Navigator.pop(context);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Session expired. Please login again.")),
                      );
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Gagal menghapus user: ${responseData['error'] ?? 'Unknown error'}")),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $e")),
                    );
                  }
                }
              },
              child: const Text("Hapus"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users Management'),
        // ✅ Tombol refresh dan logout sudah dihapus dari actions
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : users.isEmpty 
          ? const Center(child: Text("Tidak ada user tersedia"))
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: user["isAktif"] == "active" ? Colors.green : Colors.red,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(user["username"] ?? ""),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Email: ${user["email"] ?? ""}"),
                        Text("Group: ${user["group"] ?? ""}"),
                        Text(
                          "Status: ${user["isAktif"] ?? ""}",
                          style: TextStyle(
                            color: user["isAktif"] == "active" ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue), 
                          onPressed: () => showEditUserDialog(user)
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red), 
                          onPressed: () => showDeleteUserDialog(user["username"])
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}