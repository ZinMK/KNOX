import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:knox/FirebaseFunctions/DatabaseFunctions/db.dart';
import 'package:knox/screens/DataModels/appointmentModel.dart';
import 'package:knox/screens/RateCards.dart';

class SalesAnalytics extends StatefulWidget {
  const SalesAnalytics({super.key});

  @override
  State<SalesAnalytics> createState() => _SalesAnalyticsState();
}

class _SalesAnalyticsState extends State<SalesAnalytics> {
  final FireStoreMethods _db = FireStoreMethods();
  bool _isSalesLoading = true;
  bool _isRatesLoading = true;
  String _selectedView = 'monthly'; // 'today', 'monthly'
  Map<String, double> _todaySales = {};
  Map<String, double> _monthlySales = {};
  double _todayRevenue = 0.0;
  double _monthlyRevenue = 0.0;
  DateTime _selectedDate = DateTime.now();

  // New fields for rates
  double _todaySuccessRate = 0.0;
  double _todayLeadRate = 0.0;
  double _monthlySuccessRate = 0.0;
  double _monthlyLeadRate = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSalesData();
    _loadRates();
  }

  Future<void> _loadSalesData() async {
    setState(() {
      _isSalesLoading = true;
    });
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final today = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(today);

      List<AppointmentModel> todayAppointments = await _db
          .getAppointmentsByOwner(
            userId,
            startDate: todayStr,
            endDate: todayStr,
          );
      _todaySales = {};
      for (var appt in todayAppointments) {
        if (appt.recordType == 'Sale' && appt.jobPrice.isNotEmpty) {
          String hour = DateFormat('H').format(DateTime.parse(appt.date));
          double price = double.tryParse(appt.jobPrice) ?? 0.0;
          _todaySales[hour] = (_todaySales[hour] ?? 0.0) + price;
        }
      }
      _todayRevenue = _todaySales.values.fold(0.0, (a, b) => a + b);

      // Monthly
      DateTime startOfMonth = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        1,
      );
      DateTime endOfMonth = DateTime(
        _selectedDate.year,
        _selectedDate.month + 1,
        0,
      );
      String startMonthStr = DateFormat('yyyy-MM-dd').format(startOfMonth);
      String endMonthStr = DateFormat('yyyy-MM-dd').format(endOfMonth);
      List<AppointmentModel> monthAppointments = await _db
          .getAppointmentsByOwner(
            userId,
            startDate: startMonthStr,
            endDate: endMonthStr,
          );
      _monthlySales = {};
      for (var appt in monthAppointments) {
        if (appt.recordType == 'Sale' && appt.jobPrice.isNotEmpty) {
          String day = DateFormat('d').format(DateTime.parse(appt.date));
          double price = double.tryParse(appt.jobPrice) ?? 0.0;
          _monthlySales[day] = (_monthlySales[day] ?? 0.0) + price;
        }
      }
      _monthlyRevenue = _monthlySales.values.fold(0.0, (a, b) => a + b);

      setState(() {
        _isSalesLoading = false;
      });
    } catch (e) {
      setState(() {
        _isSalesLoading = false;
      });
      print(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading sales data: $e')));
    }
  }

  Future<void> _loadRates() async {
    setState(() {
      _isRatesLoading = true;
    });
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final today = DateTime.now();

      // --- For Today ---
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(Duration(days: 1));
      final allTodayMarkers =
          await FirebaseFirestore.instance
              .collection('Markers')
              .where('ownerID', isEqualTo: userId)
              .where('timestamp', isGreaterThanOrEqualTo: todayStart)
              .where('timestamp', isLessThan: todayEnd)
              .get();

      int todayMarkerCount = allTodayMarkers.docs.length;
      int todaySalesCount =
          allTodayMarkers.docs.where((doc) => doc['type'] == 'sale').length;
      int todayLeadsCount =
          allTodayMarkers.docs.where((doc) => doc['type'] == 'lead').length;
      _todaySuccessRate =
          todayMarkerCount > 0
              ? (todaySalesCount / todayMarkerCount) * 100
              : 0.0;
      _todayLeadRate =
          todayMarkerCount > 0
              ? (todayLeadsCount / todayMarkerCount) * 100
              : 0.0;

      // --- For Month ---
      final monthStart = DateTime(_selectedDate.year, _selectedDate.month, 1);
      final monthEnd = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
      final allMonthMarkers =
          await FirebaseFirestore.instance
              .collection('Markers')
              .where('ownerID', isEqualTo: userId)
              .where('timestamp', isGreaterThanOrEqualTo: monthStart)
              .where('timestamp', isLessThan: monthEnd)
              .get();

      int monthMarkerCount = allMonthMarkers.docs.length;
      int monthSalesCount =
          allMonthMarkers.docs.where((doc) => doc['type'] == 'sale').length;
      int monthLeadsCount =
          allMonthMarkers.docs.where((doc) => doc['type'] == 'lead').length;
      _monthlySuccessRate =
          monthMarkerCount > 0
              ? (monthSalesCount / monthMarkerCount) * 100
              : 0.0;
      _monthlyLeadRate =
          monthMarkerCount > 0
              ? (monthLeadsCount / monthMarkerCount) * 100
              : 0.0;

      setState(() {
        _isRatesLoading = false;
      });
    } catch (e) {
      setState(() {
        _isRatesLoading = false;
      });
      print(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading rates: $e')));
    }
  }

  Widget _buildRevenueCard(
    String label,
    String value,
    String viewKey,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedView == viewKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedView = viewKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.white,
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _isSalesLoading
                ? Center(
                  child: SizedBox(
                    height: 10,
                    width: 10,
                    child: CircularProgressIndicator(color: Colors.orange),
                  ),
                )
                : Text(
                  value,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: color,
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    if (_selectedView == 'today') {
      if (_todaySales.isEmpty) {
        return const Center(child: Text('No sales for today'));
      }
      return BarChart(
        BarChartData(
          groupsSpace: 2,
          maxY:
              (_todaySales.values.isEmpty
                  ? 0
                  : _todaySales.values.reduce((a, b) => a > b ? a : b)) +
              10,
          barGroups:
              _todaySales.entries.map((entry) {
                return BarChartGroupData(
                  x: int.parse(entry.key),
                  barRods: [
                    BarChartRodData(
                      toY: entry.value,
                      width: 16,
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }).toList(),

          gridData: FlGridData(show: true, drawVerticalLine: false),
        ),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    } else if (_selectedView == 'monthly') {
      if (_monthlySales.isEmpty) {
        return const Center(child: Text('No sales for this month'));
      }
      return BarChart(
        BarChartData(
          groupsSpace: 2,
          maxY:
              (_monthlySales.values.isEmpty
                  ? 0
                  : _monthlySales.values.reduce((a, b) => a > b ? a : b)) +
              10,
          barGroups:
              _monthlySales.entries.map((entry) {
                return BarChartGroupData(
                  x: int.parse(entry.key),
                  barRods: [
                    BarChartRodData(
                      toY: entry.value,
                      width: 16,
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }).toList(),
          titlesData: FlTitlesData(
            show: false,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}');
                },
                reservedSize: 24,
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false, drawVerticalLine: true),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String day = _monthlySales.keys.elementAt(groupIndex);

                return BarTooltipItem(
                  '$day\n\$${rod.toY.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Sales Analytics',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (picked != null && picked != _selectedDate) {
                setState(() {
                  _selectedDate = DateTime(picked.year, picked.month, 1);
                });
                _loadSalesData();
                _loadRates();
              }
            },
            icon: const Icon(Icons.calendar_month),
            label: Text(
              DateFormat('MMMM yyyy').format(_selectedDate),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildRevenueCard(
                    'Today',
                    '\$${_todayRevenue.toStringAsFixed(2)}',
                    'today',
                    Icons.flash_on,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildRevenueCard(
                    'Monthly',
                    '\$${_monthlyRevenue.toStringAsFixed(2)}',
                    'monthly',
                    Icons.calendar_month,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                color: const Color.fromARGB(255, 255, 255, 255),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child:
                      _isSalesLoading
                          ? Center(
                            child: SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                color: Colors.orange,
                              ),
                            ),
                          )
                          : _buildBarChart(),
                ),
              ),
            ),
          ),
          _isRatesLoading
              ? Center(child: CircularProgressIndicator())
              : RateCards(
                successRate:
                    _selectedView == 'today'
                        ? _todaySuccessRate
                        : _monthlySuccessRate,
                leadRate:
                    _selectedView == 'today'
                        ? _todayLeadRate
                        : _monthlyLeadRate,
                view: _selectedView,
              ),
        ],
      ),
    );
  }
}

// New widget for rate cards
