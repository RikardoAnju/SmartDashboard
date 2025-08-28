import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class KelolahKaryawanPage extends StatefulWidget {
  final String userEmail;
  final Map<String, dynamic>? userData;

  const KelolahKaryawanPage({
    super.key,
    required this.userEmail,
    this.userData,
  });

  @override
  State<KelolahKaryawanPage> createState() => _KelolahKaryawanPageState();
}

class _KelolahKaryawanPageState extends State<KelolahKaryawanPage> {
  List<dynamic> users = [];
  bool isLoading = true;
  String? accessToken;
  int totalKaryawan = 0;
  int karyawanAktif = 0;
  int karyawanNonAktif = 0;

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

  void _calculateStats() {
    totalKaryawan = users.length;
    karyawanAktif = users.where((user) => user["isAktif"] == "active").length;
    karyawanNonAktif = totalKaryawan - karyawanAktif;
  }

  Future<void> deleteInactiveEmployees() async {
    try {
      final headers = await getHeaders();
      final inactiveUsers = users.where((user) => user["isAktif"] != "active").toList();
      
      if (inactiveUsers.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Tidak ada karyawan non-aktif untuk dihapus")),
          );
        }
        return;
      }

      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              "Konfirmasi Hapus Karyawan Non-Aktif",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            content: Text(
              "Apakah Anda yakin ingin menghapus ${inactiveUsers.length} karyawan non-aktif?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                ),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Hapus Semua"),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      int deletedCount = 0;
      List<String> failedDeletions = [];

      for (final user in inactiveUsers) {
        try {
          final response = await http.delete(
            Uri.parse("${getBaseUrl()}/v1/users/${user["username"]}"),
            headers: headers,
          );

          final responseData = json.decode(response.body);

          if (response.statusCode == 200 && responseData['code'] == 200) {
            deletedCount++;
          } else {
            failedDeletions.add(user["username"]);
          }
        } catch (e) {
          failedDeletions.add(user["username"]);
        }
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Refresh data
      await fetchUsers();

      // Show result
      if (mounted) {
        if (failedDeletions.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Berhasil menghapus $deletedCount karyawan non-aktif")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Berhasil menghapus $deletedCount karyawan. Gagal menghapus: ${failedDeletions.join(', ')}"
              ),
            ),
          );
        }
      }

    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error menghapus karyawan non-aktif: $e")),
        );
      }
    }
  }

  Future<void> fetchUsers() async {
    setState(() => isLoading = true);

    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Token tidak ditemukan. Silakan login ulang.")),
          );
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
          final userData = responseData['user_data'] ?? responseData['data'];
          if (userData != null) {
            setState(() {
              users = userData;
              _calculateStats();
              isLoading = false;
            });
          } else {
            throw Exception('No user data found in response');
          }
        } else {
          throw Exception('Invalid response format: ${responseData['message'] ?? 'Unknown error'}');
        }
      } else if (response.statusCode == 401) {
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
            SnackBar(content: Text("Gagal mengambil data karyawan: ${errorBody['error'] ?? response.statusCode}")),
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

  void showEditUserDialog(Map<String, dynamic> user) {
    final usernameController = TextEditingController(text: user["username"]);
    final emailController = TextEditingController(text: user["email"]);
    final firstNameController = TextEditingController(text: user["firstName"] ?? "");
    final lastNameController = TextEditingController(text: user["lastName"] ?? "");
    final phoneController = TextEditingController(text: user["phone"] ?? "");
    final addressController = TextEditingController(text: user["address"] ?? "");
    final passwordController = TextEditingController();
    
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                "Edit Karyawan",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(usernameController, "Username", Icons.person),
                    const SizedBox(height: 16),
                    _buildTextField(firstNameController, "Nama Depan", Icons.badge),
                    const SizedBox(height: 16),
                    _buildTextField(lastNameController, "Nama Belakang", Icons.badge_outlined),
                    const SizedBox(height: 16),
                    _buildTextField(emailController, "Email", Icons.email),
                    const SizedBox(height: 16),
                    _buildTextField(phoneController, "Telepon", Icons.phone),
                    const SizedBox(height: 16),
                    _buildTextField(addressController, "Alamat", Icons.location_on),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Password *",
                        hintText: "Masukkan password baru",
                        prefixIcon: const Icon(Icons.lock, color: Color(0xFF64748B)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: const Color(0xFF64748B),
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
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
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                  ),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () async {
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
                          "address": addressController.text,
                          "password": passwordController.text,
                          "group": int.tryParse(user["group"].toString()) ?? 1,
                          "isAktif": user["isAktif"] ?? "active",
                        }),
                      );

                      final responseData = json.decode(response.body);

                      if (response.statusCode == 200 && responseData['code'] == 200) {
                        Navigator.pop(context);
                        fetchUsers();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Karyawan berhasil diperbarui")),
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
                            SnackBar(content: Text("Gagal update karyawan: ${responseData['message'] ?? responseData['error'] ?? 'Unknown error'}")),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6)),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  void showDeleteUserDialog(String username) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Konfirmasi Hapus",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          content: Text("Apakah Anda yakin ingin menghapus karyawan '$username'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
              ),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
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
                      _calculateStats();
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Karyawan berhasil dihapus")),
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
                        SnackBar(content: Text("Gagal menghapus karyawan: ${responseData['error'] ?? 'Unknown error'}")),
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

  Widget _buatKartuStat(
    String judul,
    int nilai,
    IconData ikon,
    Color warna,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: warna.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(ikon, color: warna, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            judul,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            nilai.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.group,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Manajemen Karyawan',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Kartu Statistik
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 800) {
                  return Column(
                    children: [
                      _buatKartuStat(
                        'Total Karyawan',
                        totalKaryawan,
                        Icons.people,
                        const Color(0xFF3B82F6),
                      ),
                      const SizedBox(height: 16),
                      _buatKartuStat(
                        'Karyawan Aktif',
                        karyawanAktif,
                        Icons.check_circle,
                        const Color(0xFF10B981),
                      ),
                      const SizedBox(height: 16),
                    
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(
                        child: _buatKartuStat(
                          'Total Karyawan',
                          totalKaryawan,
                          Icons.people,
                          const Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buatKartuStat(
                          'Karyawan Aktif',
                          karyawanAktif,
                          Icons.check_circle,
                          const Color(0xFF10B981),
                        ),
                      ),
                      
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 32),

            // Kontainer Daftar Karyawan
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DAFTAR KARYAWAN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      IconButton(
                        onPressed: isLoading ? null : fetchUsers,
                        icon: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(
                                Icons.refresh,
                                color: Color(0xFF64748B),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (isLoading)
                    const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Memuat data karyawan...',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    )
                  else if (users.isEmpty)
                    const Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: Color(0xFF64748B),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Tidak ada karyawan tersedia",
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: users.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final isActive = user["isAktif"] == "active";
                        
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.green : Colors.red,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user["username"] ?? "",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Email: ${user["email"] ?? ""}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    Text(
                                      "Group: ${user["group"] ?? ""}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isActive ? Colors.green.shade100 : Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        user["isAktif"] ?? "",
                                        style: TextStyle(
                                          color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                      onPressed: () => showEditUserDialog(user),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () => showDeleteUserDialog(user["username"]),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}