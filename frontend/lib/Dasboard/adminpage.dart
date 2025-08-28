import 'package:flutter/material.dart';
import 'package:frontend/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_user_page.dart';
import 'KelolahKaryawan.dart';
import 'analytics_page.dart';
import 'profile_page.dart';
import 'list_outlet.dart';
import 'dashboard.dart';

class Adminpage extends StatefulWidget {
  final String userEmail;
  final Map<String, dynamic>? userData;

  const Adminpage({super.key, required this.userEmail, this.userData});

  @override
  State<Adminpage> createState() => _AdminPageState();
}

class _AdminPageState extends State<Adminpage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isExpanded = true;
  late AnimationController _animationController;

  late final List<Widget> _pages;
  late final List<NavigationItem> _navigationItems;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pages = [
      DashboardPage(userEmail: widget.userEmail, userData: widget.userData),
      AddUserPage(userEmail: widget.userEmail, userData: widget.userData),
      KelolahKaryawanPage(
        userEmail: widget.userEmail,
        userData: widget.userData,
      ),
      AnalyticsPage(userEmail: widget.userEmail, userData: widget.userData),
      OutletListPage(userEmail: widget.userEmail, userData: widget.userData),
      ProfilePage(userEmail: widget.userEmail, userData: widget.userData),
    ];

    _navigationItems = [
      NavigationItem(icon: Icons.dashboard, label: 'Dashboard', index: 0),
      NavigationItem(
        icon: Icons.person_add,
        label: 'Tambah Karyawan',
        index: 1,
      ),
      NavigationItem(
        icon: Icons.group,
        label: 'Pengelolahan Karyawan',
        index: 2,
      ),
      NavigationItem(icon: Icons.analytics, label: 'Analytics', index: 3),
      NavigationItem(icon: Icons.store, label: 'Inventory', index: 4),
      NavigationItem(icon: Icons.work, label: 'Workshop', index: 5),
      NavigationItem(icon: Icons.confirmation_num, label: 'Voucer', index: 6),
      NavigationItem(icon: Icons.local_offer, label: 'Promo', index: 7),
      NavigationItem(icon: Icons.attach_money, label: 'Penggajian', index: 8),
      NavigationItem(icon: Icons.person, label: 'Pelanggan', index: 9),
      NavigationItem(icon: Icons.receipt_long, label: 'Transaksi', index: 10),
      NavigationItem(icon: Icons.description, label: 'Invoice', index: 11),
      NavigationItem(
        icon: Icons.menu_book,
        label: 'Cara Penggunaan',
        index: 12,
      ),
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleSidebar() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    });
  }

  // 🔧 FUNGSI LOGOUT YANG DIPERBAIKI
  void _handleLogout() async {
    showDialog(
      context: context,
      barrierDismissible: false, // Mencegah dialog ditutup secara tidak sengaja
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Tutup dialog terlebih dahulu
                
                // Tampilkan loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                );

                try {
                  final prefs = await SharedPreferences.getInstance();

                  // Debug: Print token sebelum dihapus
                  print("AccessToken sebelum logout: ${prefs.getString("accessToken")}");
                  print("RefreshToken sebelum logout: ${prefs.getString("refreshToken")}");
                  print("UserId sebelum logout: ${prefs.getString("userId")}");

                  // Hapus semua token dan data sesi pengguna
                  final List<String> keysToRemove = [
                    "accessToken",
                    "refreshToken", 
                    "userId",
                    "userEmail",
                    "userName",
                    "userRole",
                    "isLoggedIn",
                    "userData",
                    "loginTime",
                    "lastActivity",
                    "deviceId",
                  ];

                  // Hapus satu per satu untuk memastikan
                  for (String key in keysToRemove) {
                    if (prefs.containsKey(key)) {
                      await prefs.remove(key);
                      print("✅ Removed key: $key");
                    }
                  }

                  // Verifikasi token sudah terhapus
                  print("AccessToken setelah logout: ${prefs.getString("accessToken")}");
                  print("RefreshToken setelah logout: ${prefs.getString("refreshToken")}");
                  print("UserId setelah logout: ${prefs.getString("userId")}");

                  // Tutup loading dialog
                  if (mounted) Navigator.of(context).pop();

                  // Navigasi ke halaman login dan hapus semua rute sebelumnya
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (Route<dynamic> route) => false, // Hapus semua rute
                    );
                  }

                  // Tampilkan pesan berhasil logout
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Berhasil logout'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }

                } catch (e) {
                  // Tutup loading dialog jika error
                  if (mounted) Navigator.of(context).pop();
                  
                  // Tampilkan error message
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error saat logout: ${e.toString()}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                  
                  // Tetap navigasi ke login meskipun ada error
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (Route<dynamic> route) => false,
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // 🔧 FUNGSI HELPER UNTUK MEMBERSIHKAN DATA USER
  Future<void> _clearAllUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Daftar lengkap key yang mungkin disimpan
      final List<String> userDataKeys = [
        "accessToken",
        "refreshToken", 
        "userId",
        "userEmail",
        "userName",
        "userRole",
        "isLoggedIn",
        "userData",
        "loginTime",
        "lastActivity",
        "deviceId",
        // Tambahkan key lain sesuai kebutuhan aplikasi
      ];

      // Hapus semua key terkait user
      for (String key in userDataKeys) {
        if (prefs.containsKey(key)) {
          await prefs.remove(key);
          print("Removed key: $key");
        }
      }

      // Verifikasi pembersihan berhasil
      bool allCleared = true;
      for (String key in userDataKeys) {
        if (prefs.containsKey(key)) {
          allCleared = false;
          print("Warning: Key '$key' masih ada setelah pembersihan");
        }
      }

      if (allCleared) {
        print("✅ Semua data user berhasil dibersihkan");
      } else {
        print("⚠️  Beberapa data mungkin belum terhapus sepenuhnya");
      }

    } catch (e) {
      print("❌ Error saat membersihkan data user: $e");
      throw e;
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 17) return 'Selamat Siang';
    return 'Selamat Malam';
  }

  String _getUserName() {
    if (widget.userData != null && widget.userData!['name'] != null) {
      return widget.userData!['name'];
    }
    return widget.userEmail.split('@')[0];
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header dengan logo dan title
          if (_isExpanded)
            Row(
              children: [
                // Logo
                Image.asset(
                  'assets/img/logo.png',
                  height: 32,
                  width: 32,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                // Title
                const Expanded(
                  child: Text(
                    'Piposmart',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
                // Toggle button
                IconButton(
                  onPressed: _toggleSidebar,
                  icon: const Icon(Icons.menu_open, color: Color(0xFF6B7280)),
                ),
              ],
            )
          else
            // Collapsed state - hanya toggle button
            IconButton(
              onPressed: _toggleSidebar,
              icon: const Icon(Icons.menu, color: Color(0xFF6B7280)),
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem(NavigationItem item) {
    final isSelected = _selectedIndex == item.index;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: _isExpanded ? 8 : 4,
        vertical: 2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_isExpanded ? 12 : 8),
          onTap: () => _onItemTapped(item.index),
          child: Container(
            height: 48,
            padding: EdgeInsets.symmetric(
              horizontal: _isExpanded ? 16 : 0,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_isExpanded ? 12 : 8),
              color: isSelected
                  ? const Color(0xFF3B82F6).withOpacity(0.1)
                  : Colors.transparent,
            ),
            child: _isExpanded
                ? Row(
                    children: [
                      Icon(
                        item.icon,
                        color: isSelected
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF6B7280),
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF374151),
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Icon(
                      item.icon,
                      color: isSelected
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF6B7280),
                      size: 20,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: _isExpanded ? 280 : 72,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x0F000000),
                  offset: Offset(2, 0),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSidebarHeader(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: _navigationItems.length,
                    itemBuilder: (context, index) {
                      return _buildNavigationItem(_navigationItems[index]);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // App Bar
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 235, 19, 4),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0F000000),
                        offset: Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_getGreeting()}, ${_getUserName()}!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'profile':
                              setState(
                                () => _selectedIndex = 5,
                              ); // Profile index
                              break;
                            case 'logout':
                              _handleLogout(); // 🔧 Menggunakan fungsi logout yang diperbaiki
                              break;
                            case 'settings':
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Settings feature coming soon!',
                                  ),
                                ),
                              );
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'profile',
                            child: ListTile(
                              leading: Icon(Icons.person),
                              title: Text('Profile'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'settings',
                            child: ListTile(
                              leading: Icon(Icons.settings),
                              title: Text('Settings'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'logout',
                            child: ListTile(
                              leading: Icon(
                                Icons.logout,
                                color: Color(0xFFEF4444),
                              ),
                              title: Text(
                                'Logout',
                                style: TextStyle(color: Color(0xFFEF4444)),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Page Content
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: _pages[_selectedIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final int index;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}

// Dashboard Content Page - konten dari document pertama
class DashboardContentPage extends StatefulWidget {
  final String userEmail;
  final Map<String, dynamic>? userData;

  const DashboardContentPage({
    super.key,
    required this.userEmail,
    this.userData,
  });

  @override
  State<DashboardContentPage> createState() => _DashboardContentPageState();
}

class _DashboardContentPageState extends State<DashboardContentPage> {
  String selectedMonth = 'January';
  String selectedYear = '2021';

  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final List<String> years = ['2020', '2021', '2022', '2023', '2024', '2025'];

  // Sample dashboard data
  final Map<String, dynamic> dashboardData = {
    'omset': 2821000,
    'uangMasuk': 1678000,
    'pengeluaran': 10000,
    'piutangPelanggan': 1493000,
    'pendapatanBersih': 1668000,
    'transaksi': 21,
    'pembatalan': 1,
    'pelangganBaru': 18,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildInfoBanner(),
          const SizedBox(height: 24),
          _buildStatsGrid(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
      child: Row(
        children: [
          const Text(
            'Laporan\nBulan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
              height: 1.3,
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    selectedMonth,
                    months,
                    (value) => setState(() => selectedMonth = value!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    selectedYear,
                    years,
                    (value) => setState(() => selectedYear = value!),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Semua Outlet',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFEBB8)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Masa aktif aplikasi anda akan habis dalam 9 hari pada tanggal 04 February 2021. Segera lakukan pembayaran sebelum tanggal jatuh tempo.',
              style: TextStyle(color: Color(0xFF8B4513), fontSize: 13),
            ),
          ),
          Icon(Icons.close, color: Colors.orange.shade700, size: 18),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      StatItem(
        'Omset',
        dashboardData['omset'],
        Colors.orange,
        Icons.trending_up,
      ),
      StatItem(
        'Uang Masuk',
        dashboardData['uangMasuk'],
        Colors.brown,
        Icons.account_balance_wallet,
      ),
      StatItem(
        'Pengeluaran',
        dashboardData['pengeluaran'],
        Colors.blue,
        Icons.receipt_long,
      ),
      StatItem(
        'Piutang Pelanggan',
        dashboardData['piutangPelanggan'],
        Colors.teal,
        Icons.account_circle,
      ),
      StatItem(
        'Pendapatan Bersih',
        dashboardData['pendapatanBersih'],
        Colors.orange,
        Icons.monetization_on,
      ),
      StatItem(
        'Transaksi',
        dashboardData['transaksi'],
        Colors.grey,
        Icons.receipt,
        isNumber: true,
      ),
      StatItem(
        'Pembatalan',
        dashboardData['pembatalan'],
        Colors.red,
        Icons.cancel,
        isNumber: true,
      ),
      StatItem(
        'Pelanggan Baru',
        dashboardData['pelangganBaru'],
        Colors.blue,
        Icons.person_add,
        isNumber: true,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth < 800 ? 2 : 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) => _buildStatCard(stats[index]),
        );
      },
    );
  }

  Widget _buildStatCard(StatItem item) {
    String formattedValue = item.isNumber
        ? item.value.toString()
        : _formatCurrency(item.value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
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
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Icon(item.icon, size: 16, color: item.color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF718096),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (!item.isNumber)
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    size: 8,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formattedValue,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}

class StatItem {
  final String title;
  final dynamic value;
  final Color color;
  final IconData icon;
  final bool isNumber;

  StatItem(
    this.title,
    this.value,
    this.color,
    this.icon, {
    this.isNumber = false,
  });
}