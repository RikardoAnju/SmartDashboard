
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardPage extends StatefulWidget {
  final String userEmail;
  final Map<String, dynamic>? userData;

  const DashboardPage({super.key, required this.userEmail, this.userData});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String selectedMonth = 'January';
  String selectedYear = '2021';
  
  final List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  
  final List<String> years = ['2020', '2021', '2022', '2023', '2024', '2025'];

  // Data dummy untuk dashboard
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

  // Data untuk grafik transaksi penjualan (qty)
  final List<TransactionData> salesData = [
    TransactionData('Jan', 25, 20, 15, 10),
    TransactionData('Feb', 30, 25, 20, 15),
    TransactionData('Mar', 35, 30, 25, 20),
    TransactionData('Apr', 40, 35, 30, 25),
    TransactionData('Mei', 45, 40, 35, 30),
    TransactionData('Jun', 50, 45, 40, 35),
  ];

  // Data untuk grafik transaksi keuangan (nominal)
  final List<FinancialData> financialData = [
    FinancialData('Jan', 800000, 600000, 500000),
    FinancialData('Feb', 900000, 700000, 600000),
    FinancialData('Mar', 1000000, 800000, 700000),
    FinancialData('Apr', 1100000, 900000, 800000),
    FinancialData('Mei', 1200000, 1000000, 900000),
    FinancialData('Jun', 1300000, 1100000, 1000000),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan dropdown
            _buildHeader(),
            const SizedBox(height: 24),
            
            // Info banner
            _buildInfoBanner(),
            const SizedBox(height: 24),
            
            // Stats cards
            _buildStatsGrid(),
            const SizedBox(height: 24),
            
            // Charts section
            _buildChartsSection(),
          ],
        ),
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
                // Month dropdown
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedMonth,
                        isExpanded: true,
                        items: months.map((month) {
                          return DropdownMenuItem(value: month, child: Text(month));
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedMonth = value!);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Year dropdown
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedYear,
                        isExpanded: true,
                        items: years.map((year) {
                          return DropdownMenuItem(value: year, child: Text(year));
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedYear = value!);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Outlet dropdown
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Semua Outlet',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
              style: TextStyle(
                color: Color(0xFF8B4513),
                fontSize: 13,
              ),
            ),
          ),
          Icon(Icons.close, color: Colors.orange.shade700, size: 18),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard('Omset', dashboardData['omset'], Colors.orange, Icons.trending_up)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Uang Masuk', dashboardData['uangMasuk'], Colors.brown, Icons.account_balance_wallet)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Pengeluaran', dashboardData['pengeluaran'], Colors.blue, Icons.receipt_long)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Piutang Pelanggan', dashboardData['piutangPelanggan'], Colors.teal, Icons.account_circle)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Pendapatan Bersih', dashboardData['pendapatanBersih'], Colors.orange, Icons.monetization_on)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Transaksi', dashboardData['transaksi'], Colors.grey, Icons.receipt, isNumber: true)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Pembatalan', dashboardData['pembatalan'], Colors.red, Icons.cancel, isNumber: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Pelanggan Baru', dashboardData['pelangganBaru'], Colors.blue, Icons.person_add, isNumber: true)),
                ],
              ),
            ],
          );
        } else {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard('Omset', dashboardData['omset'], Colors.orange, Icons.trending_up)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Uang Masuk', dashboardData['uangMasuk'], Colors.brown, Icons.account_balance_wallet)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Pengeluaran', dashboardData['pengeluaran'], Colors.blue, Icons.receipt_long)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Piutang Pelanggan', dashboardData['piutangPelanggan'], Colors.teal, Icons.account_circle)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Pendapatan Bersih', dashboardData['pendapatanBersih'], Colors.orange, Icons.monetization_on)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Transaksi', dashboardData['transaksi'], Colors.grey, Icons.receipt, isNumber: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Pembatalan', dashboardData['pembatalan'], Colors.red, Icons.cancel, isNumber: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Pelanggan Baru', dashboardData['pelangganBaru'], Colors.blue, Icons.person_add, isNumber: true)),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatCard(String title, dynamic value, Color color, IconData icon, {bool isNumber = false}) {
    String formattedValue;
    if (isNumber) {
      formattedValue = value.toString();
    } else {
      formattedValue = _formatCurrency(value);
    }

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
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF718096),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (!isNumber)
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

  Widget _buildChartsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1000) {
          return Column(
            children: [
              _buildSalesChart(),
              const SizedBox(height: 24),
              _buildFinancialChart(),
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(child: _buildSalesChart()),
              const SizedBox(width: 24),
              Expanded(child: _buildFinancialChart()),
            ],
          );
        }
      },
    );
  }

  Widget _buildSalesChart() {
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
          const Text(
            'Transaksi Penjualan (Qty)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(['Penjualan', 'Voucher', 'Retur', 'Lainnya'], 
                     [Colors.green, Colors.blue, Colors.red, Colors.grey]),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < salesData.length) {
                          return Text(
                            salesData[index].month,
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  _createLineChartBarData(Colors.green, salesData.map((e) => e.sales).toList()),
                  _createLineChartBarData(Colors.blue, salesData.map((e) => e.voucher).toList()),
                  _createLineChartBarData(Colors.red, salesData.map((e) => e.returns).toList()),
                  _createLineChartBarData(Colors.grey, salesData.map((e) => e.others).toList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialChart() {
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
          const Text(
            'Transaksi Keuangan (Nominal)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(['Pendapatan', 'Voucher', 'Retur'], 
                     [Colors.green, Colors.blue, Colors.red]),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < financialData.length) {
                          return Text(
                            financialData[index].month,
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  _createLineChartBarData(Colors.green, financialData.map((e) => e.income.toDouble()).toList()),
                  _createLineChartBarData(Colors.blue, financialData.map((e) => e.voucher.toDouble()).toList()),
                  _createLineChartBarData(Colors.red, financialData.map((e) => e.returns.toDouble()).toList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _createLineChartBarData(Color color, List<double> values) {
    return LineChartBarData(
      spots: values.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value);
      }).toList(),
      isCurved: true,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
    );
  }

  Widget _buildLegend(List<String> labels, List<Color> colors) {
    return Wrap(
      children: labels.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 3,
                color: colors[entry.key],
              ),
              const SizedBox(width: 6),
              Text(
                entry.value,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF718096),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );
  }
}

// Model classes
class TransactionData {
  final String month;
  final double sales;
  final double voucher;
  final double returns;
  final double others;

  TransactionData(this.month, this.sales, this.voucher, this.returns, this.others);
}

class FinancialData {
  final String month;
  final int income;
  final int voucher;
  final int returns;

  FinancialData(this.month, this.income, this.voucher, this.returns);
}