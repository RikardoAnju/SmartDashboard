import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OutletListPage extends StatefulWidget {
  final String userEmail;
  final Map<String, dynamic>? userData;

  const OutletListPage({
    super.key,
    required this.userEmail,
    required this.userData,
  });

  @override
  State<OutletListPage> createState() => _OutletListPageState();
}

class _OutletListPageState extends State<OutletListPage> {
  List<Map<String, dynamic>> _outlets = [];
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const String baseUrl = 'http://localhost:8080/v1/outlets';
  
  String? get _token => widget.userData?['accessToken'] ?? widget.userData?['token'];

  @override
  void initState() {
    super.initState();
    _loadOutlets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<void> _loadOutlets() async {
    if (_token == null) {
      _showSnackBar('Token tidak ditemukan. Silakan login ulang.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('Attempting to connect to: $baseUrl');
      print('Headers: $_headers');
      
      final response = await http.get(Uri.parse(baseUrl), headers: _headers);
      
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _outlets = _parseOutletData(data);
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        _showSnackBar('Sesi Anda telah berakhir. Silakan login ulang.');
        setState(() => _isLoading = false);
      } else {
        throw Exception('Gagal memuat data outlet');
      }
    } catch (e) {
      print('Error: $e');
      setState(() => _isLoading = false);
      
      // Handle different error types
      if (e.toString().contains('Failed to fetch') || e.toString().contains('CORS')) {
        _showSnackBar('Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
      } else {
        _showSnackBar('Terjadi kesalahan saat memuat data outlet.');
      }
    }
  }

  List<Map<String, dynamic>> _parseOutletData(dynamic data) {
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    } else if (data is Map) {
      if (data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else if (data['outlets'] != null) {
        return List<Map<String, dynamic>>.from(data['outlets']);
      }
    }
    return [];
  }

  Future<void> _createOutlet(Map<String, dynamic> outletData) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: _headers,
        body: jsonEncode(outletData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await _loadOutlets();
        _showSnackBar('Outlet berhasil ditambahkan');
      } else {
        throw Exception('Gagal menambah outlet');
      }
    } catch (e) {
      _showSnackBar('Gagal menambah outlet. Coba lagi.');
    }
  }

  Future<void> _updateOutlet(String id, Map<String, dynamic> outletData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: _headers,
        body: jsonEncode(outletData),
      );

      if (response.statusCode == 200) {
        await _loadOutlets();
        _showSnackBar('Outlet berhasil diperbarui');
      } else {
        throw Exception('Gagal memperbarui outlet');
      }
    } catch (e) {
      _showSnackBar('Gagal memperbarui outlet. Coba lagi.');
    }
  }

  Future<void> _deleteOutlet(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await _loadOutlets();
        _showSnackBar('Outlet berhasil dihapus');
      } else {
        throw Exception('Gagal menghapus outlet');
      }
    } catch (e) {
      _showSnackBar('Gagal menghapus outlet. Coba lagi.');
    }
  }

  List<Map<String, dynamic>> get _filteredOutlets {
    if (_searchQuery.isEmpty) return _outlets;
    
    return _outlets.where((outlet) {
      final searchFields = [
        outlet['name'] ?? '',
        outlet['address'] ?? '',
        outlet['manager'] ?? ''
      ].join(' ').toLowerCase();
      
      return searchFields.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  void _showOutletDialog({Map<String, dynamic>? outlet}) {
    showDialog(
      context: context,
      builder: (context) => OutletFormDialog(
        outlet: outlet,
        onSave: (outletData) {
          if (outlet == null) {
            _createOutlet(outletData);
          } else {
            final id = outlet['id']?.toString() ?? 
                      outlet['_id']?.toString() ?? 
                      outlet['outletId']?.toString();
            if (id != null) {
              _updateOutlet(id, outletData);
            }
          }
        },
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> outlet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Outlet'),
        content: Text('Yakin ingin menghapus ${outlet['name'] ?? 'outlet ini'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final id = outlet['id']?.toString() ?? 
                        outlet['_id']?.toString() ?? 
                        outlet['outletId']?.toString();
              if (id != null) _deleteOutlet(id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Daftar Outlet'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOutlets,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _buildOutletList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showOutletDialog(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Cari outlet...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildOutletList() {
    final filteredOutlets = _filteredOutlets;

    if (filteredOutlets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'Belum ada outlet' : 'Outlet tidak ditemukan',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty 
                  ? 'Tekan tombol + untuk menambah outlet' 
                  : 'Coba kata kunci lain',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredOutlets.length,
      itemBuilder: (context, index) {
        final outlet = filteredOutlets[index];
        return _buildOutletCard(outlet);
      },
    );
  }

  Widget _buildOutletCard(Map<String, dynamic> outlet) {
    final isActive = outlet['status']?.toString().toLowerCase() == 'active';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showOutletDialog(outlet: outlet),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      outlet['name'] ?? 'Nama tidak tersedia',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Aktif' : 'Tidak Aktif',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showOutletDialog(outlet: outlet);
                      } else if (value == 'delete') {
                        _confirmDelete(outlet);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.location_on, outlet['address'] ?? 'Alamat tidak tersedia'),
              _buildInfoRow(Icons.person, outlet['manager'] ?? 'Manager tidak tersedia'),
              _buildInfoRow(Icons.phone, outlet['phone'] ?? 'Telepon tidak tersedia'),
              _buildInfoRow(Icons.access_time, 'Jam: ${outlet['openHours'] ?? 'Tidak tersedia'}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}

class OutletFormDialog extends StatefulWidget {
  final Map<String, dynamic>? outlet;
  final Function(Map<String, dynamic>) onSave;

  const OutletFormDialog({
    super.key,
    this.outlet,
    required this.onSave,
  });

  @override
  State<OutletFormDialog> createState() => _OutletFormDialogState();
}

class _OutletFormDialogState extends State<OutletFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _managerController;
  late final TextEditingController _openHoursController;
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    final outlet = widget.outlet;
    _nameController = TextEditingController(text: outlet?['name'] ?? '');
    _addressController = TextEditingController(text: outlet?['address'] ?? '');
    _phoneController = TextEditingController(text: outlet?['phone'] ?? '');
    _managerController = TextEditingController(text: outlet?['manager'] ?? '');
    _openHoursController = TextEditingController(text: outlet?['openHours'] ?? '');
    _status = outlet?['status'] ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _managerController.dispose();
    _openHoursController.dispose();
    super.dispose();
  }

  void _saveOutlet() {
    if (_formKey.currentState!.validate()) {
      final outletData = {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'manager': _managerController.text.trim(),
        'openHours': _openHoursController.text.trim(),
        'status': _status,
      };
      
      widget.onSave(outletData);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.outlet == null ? 'Tambah Outlet' : 'Edit Outlet'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Outlet',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.trim().isEmpty == true 
                      ? 'Nama outlet tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Alamat',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) => value?.trim().isEmpty == true 
                      ? 'Alamat tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value?.trim().isEmpty == true 
                      ? 'Nomor telepon tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _managerController,
                  decoration: const InputDecoration(
                    labelText: 'Manager',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.trim().isEmpty == true 
                      ? 'Nama manager tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _openHoursController,
                  decoration: const InputDecoration(
                    labelText: 'Jam Buka (contoh: 08:00 - 22:00)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.trim().isEmpty == true 
                      ? 'Jam buka tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Aktif')),
                    DropdownMenuItem(value: 'inactive', child: Text('Tidak Aktif')),
                  ],
                  onChanged: (value) => setState(() => _status = value!),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _saveOutlet,
          child: Text(widget.outlet == null ? 'Tambah' : 'Perbarui'),
        ),
      ],
    );
  }
}