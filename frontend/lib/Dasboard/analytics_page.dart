// lib/Dashboard/analytics_page.dart - Fixed version
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AnalyticsPage extends StatefulWidget {
  final String userEmail;
  final Map<String, dynamic>? userData;

  const AnalyticsPage({super.key, required this.userEmail, this.userData});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  List<DataPenggunaBulanan> dataBulanan = [];
  bool sedangMemuat = true;
  String? kesalahan;
  int totalUsers = 0;
  int currentMonthUsers = 0;
  double growthRate = 0.0;
  String? token;

  @override
  void initState() {
    super.initState();
    _initializeToken();
  }

  Future<void> _initializeToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('accessToken');
      print('Retrieved token: ${token?.substring(0, 20)}...');
      
      // Mulai mengambil data setelah token diinisialisasi
      ambilDataPendaftaranPengguna();
    } catch (e) {
      print('Error getting token: $e');
      // Jika gagal mendapatkan token, tetap coba ambil data
      ambilDataPendaftaranPengguna();
    }
  }

  Future<void> ambilDataPendaftaranPengguna() async {
    try {
      setState(() {
        sedangMemuat = true;
        kesalahan = null;
      });

      print('Fetching analytics data with token: ${token?.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse('http://localhost:8080/v1/analytics/user-registrations'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('Analytics response status: ${response.statusCode}');
      print('Analytics response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Periksa struktur response
        if (responseData is Map<String, dynamic>) {
          // Jika response mengikuti format standar dengan success flag
          if (responseData.containsKey('success') && responseData['success'] == true) {
            final data = responseData['data'];
            _parseAnalyticsData(data);
          }
          // Jika response langsung berisi data analytics
          else if (responseData.containsKey('monthly_registrations') || 
                   responseData.containsKey('data')) {
            _parseAnalyticsData(responseData.containsKey('data') ? responseData['data'] : responseData);
          }
          // Jika response berisi code dan message
          else if (responseData.containsKey('code')) {
            if (responseData['code'] == 200) {
              _parseAnalyticsData(responseData);
            } else {
              throw Exception('API Error: ${responseData['message'] ?? 'Unknown error'}');
            }
          }
          else {
            // Fallback: coba parse langsung sebagai data
            _parseAnalyticsData(responseData);
          }
        } else {
          throw Exception('Invalid response format: expected Map<String, dynamic>');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Analytics endpoint not found - Please check backend configuration');
      } else {
        final errorBody = json.decode(response.body);
        throw Exception('Server error (${response.statusCode}): ${errorBody['message'] ?? errorBody['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Error loading analytics data: $e');
      setState(() {
        kesalahan = e.toString();
        sedangMemuat = false;
        
        // Gunakan data contoh untuk development/testing
        if (_shouldUseDummyData(e.toString())) {
          print('Using dummy data for development');
          dataBulanan = buatDataContoh();
          totalUsers = dataBulanan.fold<int>(0, (sum, data) => sum + data.pengguna);
          currentMonthUsers = dataBulanan.isNotEmpty ? dataBulanan.last.pengguna : 0;
          growthRate = dataBulanan.length >= 2 ? dataBulanan.last.pertumbuhan : 0.0;
        }
      });
    }
  }

  void _parseAnalyticsData(dynamic data) {
    setState(() {
      if (data != null && data is Map<String, dynamic>) {
        // Parse monthly registrations
        if (data.containsKey('monthly_registrations')) {
          dataBulanan = (data['monthly_registrations'] as List)
              .map((item) => DataPenggunaBulanan.fromJson(item))
              .toList();
        } else {
          // Jika tidak ada monthly_registrations, gunakan data contoh
          dataBulanan = buatDataContoh();
        }
        
        // Parse additional statistics
        totalUsers = _parseIntValue(data['total_users']);
        currentMonthUsers = _parseIntValue(data['current_month_users']);
        growthRate = _parseDoubleValue(data['growth_rate']);
        
        // Jika statistik kosong, hitung dari data bulanan
        if (totalUsers == 0 && dataBulanan.isNotEmpty) {
          totalUsers = dataBulanan.fold<int>(0, (sum, data) => sum + data.pengguna);
        }
        if (currentMonthUsers == 0 && dataBulanan.isNotEmpty) {
          currentMonthUsers = dataBulanan.last.pengguna;
        }
        if (growthRate == 0.0 && dataBulanan.length >= 2) {
          growthRate = dataBulanan.last.pertumbuhan;
        }
      } else {
        // Jika data tidak valid, gunakan data contoh
        dataBulanan = buatDataContoh();
        totalUsers = dataBulanan.fold<int>(0, (sum, data) => sum + data.pengguna);
        currentMonthUsers = dataBulanan.isNotEmpty ? dataBulanan.last.pengguna : 0;
        growthRate = dataBulanan.length >= 2 ? dataBulanan.last.pertumbuhan : 0.0;
      }
      
      sedangMemuat = false;
    });
  }

  int _parseIntValue(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _parseDoubleValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  bool _shouldUseDummyData(String error) {
    return error.contains('Connection refused') ||
           error.contains('SocketException') ||
           error.contains('Network is unreachable') ||
           error.contains('Failed host lookup');
  }

  List<DataPenggunaBulanan> buatDataContoh() {
    return [
      DataPenggunaBulanan(bulan: 'Jan', pengguna: 15, pertumbuhan: 0),
      DataPenggunaBulanan(bulan: 'Feb', pengguna: 25, pertumbuhan: 66.7),
      DataPenggunaBulanan(bulan: 'Mar', pengguna: 32, pertumbuhan: 28.0),
      DataPenggunaBulanan(bulan: 'Apr', pengguna: 28, pertumbuhan: -12.5),
      DataPenggunaBulanan(bulan: 'Mei', pengguna: 45, pertumbuhan: 60.7),
      DataPenggunaBulanan(bulan: 'Jun', pengguna: 38, pertumbuhan: -15.6),
      DataPenggunaBulanan(bulan: 'Jul', pengguna: 52, pertumbuhan: 36.8),
      DataPenggunaBulanan(bulan: 'Agu', pengguna: 48, pertumbuhan: -7.7),
      DataPenggunaBulanan(bulan: 'Sep', pengguna: 41, pertumbuhan: -14.6),
      DataPenggunaBulanan(bulan: 'Okt', pengguna: 35, pertumbuhan: -14.6),
      DataPenggunaBulanan(bulan: 'Nov', pengguna: 42, pertumbuhan: 20.0),
      DataPenggunaBulanan(bulan: 'Des', pengguna: 39, pertumbuhan: -7.1),
    ];
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
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Analasis Pengguna',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Kartu Statistik - Layout Responsif
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 800) {
                  return Column(
                    children: [
                      _buatKartuStat(
                        'Total Pengguna',
                        totalUsers,
                        Icons.people,
                        const Color(0xFF3B82F6),
                      ),
                      const SizedBox(height: 16),
                      _buatKartuStat(
                        'Bulan Ini',
                        currentMonthUsers,
                        Icons.person_add,
                        const Color(0xFF10B981),
                      ),
                      const SizedBox(height: 16),
                      _buatKartuStat(
                        'Tingkat Pertumbuhan',
                        growthRate,
                        Icons.trending_up,
                        const Color(0xFF8B5CF6),
                        adalahPersentase: true,
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(
                        child: _buatKartuStat(
                          'Total Pengguna',
                          totalUsers,
                          Icons.people,
                          const Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buatKartuStat(
                          'Bulan Ini',
                          currentMonthUsers,
                          Icons.person_add,
                          const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buatKartuStat(
                          'Tingkat Pertumbuhan',
                          growthRate,
                          Icons.trending_up,
                          const Color(0xFF8B5CF6),
                          adalahPersentase: true,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 32),

            // Kontainer Grafik
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
                      const Expanded(
                        child: Text(
                          'LAPORAN PENDAFTARAN PENGGUNA 12 BULAN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: sedangMemuat ? null : ambilDataPendaftaranPengguna,
                        icon: sedangMemuat
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

                  if (sedangMemuat)
                    const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Memuat data dari server...',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    )
                  else if (kesalahan != null)
                    _buildErrorWidget()
                  else
                    _buatGrafik(),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(height: 8),
          Text(
            _getErrorMessage(),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: ambilDataPendaftaranPengguna,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
          ),
          if (_shouldUseDummyData(kesalahan!))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Menampilkan data contoh',
                style: TextStyle(
                  color: Colors.orange[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getErrorMessage() {
    if (kesalahan!.contains('Connection refused')) {
      return 'Server tidak dapat dijangkau\nPastikan backend berjalan di port 8080';
    } else if (kesalahan!.contains('Unauthorized')) {
      return 'Sesi Anda telah berakhir\nSilakan login kembali';
    } else if (kesalahan!.contains('Analytics endpoint not found')) {
      return 'Endpoint analytics tidak ditemukan\nPastikan backend memiliki endpoint yang benar';
    } else {
      return 'Kesalahan memuat data\n${kesalahan!}';
    }
  }



  

  Widget _buatKartuStat(
    String judul,
    dynamic nilai,
    IconData ikon,
    Color warna, {
    bool adalahPersentase = false,
  }) {
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
              const Spacer(),
              if (adalahPersentase && nilai > 0)
                const Icon(
                  Icons.trending_up,
                  color: Color(0xFF10B981),
                  size: 16,
                )
              else if (adalahPersentase && nilai < 0)
                const Icon(
                  Icons.trending_down,
                  color: Color(0xFFEF4444),
                  size: 16,
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
            adalahPersentase
                ? '${nilai.toStringAsFixed(1)}%'
                : nilai.toString(),
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

  Widget _buatGrafik() {
    if (dataBulanan.isEmpty) {
      return const Center(
        child: Column(
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: Color(0xFF64748B),
            ),
            SizedBox(height: 8),
            Text(
              'Tidak ada data untuk ditampilkan',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 350,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 10,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 10,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < dataBulanan.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        dataBulanan[value.toInt()].bulan,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: dataBulanan.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.pengguna.toDouble());
              }).toList(),
              isCurved: true,
              color: const Color(0xFF3B82F6),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: const Color(0xFF3B82F6),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF3B82F6).withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => const Color(0xFF1E293B),
              tooltipBorder: BorderSide.none,
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  if (index >= 0 && index < dataBulanan.length) {
                    final data = dataBulanan[index];
                    return LineTooltipItem(
                      '${data.bulan}\n${data.pengguna} pengguna',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                  return null;
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Model class untuk data pengguna bulanan
class DataPenggunaBulanan {
  final String bulan;
  final int pengguna;
  final double pertumbuhan;

  DataPenggunaBulanan({
    required this.bulan,
    required this.pengguna,
    required this.pertumbuhan,
  });

  factory DataPenggunaBulanan.fromJson(Map<String, dynamic> json) {
    return DataPenggunaBulanan(
      bulan: json['month'] ?? json['bulan'] ?? '',
      pengguna: _parseIntValue(json['users'] ?? json['pengguna']),
      pertumbuhan: _parseDoubleValue(json['growth_rate'] ?? json['pertumbuhan']),
    );
  }

  static int _parseIntValue(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDoubleValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'bulan': bulan,
      'pengguna': pengguna,
      'pertumbuhan': pertumbuhan,
    };
  }
}