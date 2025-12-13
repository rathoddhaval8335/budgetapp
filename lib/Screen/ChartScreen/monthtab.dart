import 'dart:convert';
import 'package:budgetapp/Service/apiservice.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class MonthTabDemo extends StatefulWidget {
  final String userId;
  final String selectedType;

  const MonthTabDemo({
    super.key,
    required this.userId,
    required this.selectedType,
  });

  @override
  State<MonthTabDemo> createState() => _MonthTabDemoState();
}

class _MonthTabDemoState extends State<MonthTabDemo>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<String> monthNames;
  Map<String, List<Map<String, dynamic>>> monthlyData = {};
  Map<String, bool> loadingStates = {};
  Map<String, double> monthlyTotals = {};

  @override
  void initState() {
    super.initState();

    int currentYear = DateTime.now().year;
    int currentMonth = DateTime.now().month;
    List<String> months = [];

    for (int i = 1; i <= currentMonth; i++) {
      String month = DateFormat('MMM').format(DateTime(currentYear, i));
      months.add("$month $currentYear");
    }

    monthNames = months;

    _tabController = TabController(length: monthNames.length, vsync: this);
    _tabController.animateTo(monthNames.length - 1);

    // Fetch data for all months
    for (String month in monthNames) {
      _fetchMonthData(month);
    }

    // Listen to tab changes
    _tabController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _fetchMonthData(String monthYear) async {
    setState(() {
      loadingStates[monthYear] = true;
    });

    try {
      final parts = monthYear.split(' ');
      final month = parts[0];
      final year = parts[1];

      // Convert month name to month number
      final date = DateFormat('MMM yyyy').parse(monthYear);
      final monthNumber = date.month;
      final yearNumber = date.year;

      var response = await http.post(
        //Uri.parse("http://192.168.43.192/BUDGET_APP/monthly_chart_data.php"),
        Uri.parse(ApiService.getUrl("monthly_chart_data.php")),
        body: {
          "user_id": widget.userId,
          "month": monthNumber.toString(),
          "year": yearNumber.toString(),
          "type": widget.selectedType.toLowerCase(),
        },
      );

      var jsonResponse = jsonDecode(response.body);

      if (jsonResponse['status'] == 'success') {
        List<dynamic> data = jsonResponse['data'];
        double total = 0.0;

        List<Map<String, dynamic>> formattedData = data.map((item) {
          double amount = double.parse(item['amount'].toString());
          total += amount;
          return {
            "category": item['category'],
            "amount": amount,
            "color": _getCategoryColor(item['category']),
          };
        }).toList();

        setState(() {
          monthlyData[monthYear] = formattedData;
          monthlyTotals[monthYear] = total;
          loadingStates[monthYear] = false;
        });
      } else {
        setState(() {
          monthlyData[monthYear] = [];
          monthlyTotals[monthYear] = 0.0;
          loadingStates[monthYear] = false;
        });
      }
    } catch (e) {
      print("Error fetching data for $monthYear: $e");
      setState(() {
        monthlyData[monthYear] = [];
        monthlyTotals[monthYear] = 0.0;
        loadingStates[monthYear] = false;
      });
    }
  }

  Color _getCategoryColor(String category) {
    // Generate consistent colors based on category name
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.deepOrange,
      Colors.lightBlue,
      Colors.lightGreen,
      Colors.pink,
      Colors.indigo,
    ];

    int index = category.hashCode % colors.length;
    return colors[index];
  }

  List<PieChartSectionData> _buildPieChartSections(String monthYear) {
    final data = monthlyData[monthYear] ?? [];
    final total = monthlyTotals[monthYear] ?? 1.0;

    if (data.isEmpty) {
      return [
        PieChartSectionData(
          color: Colors.grey[300],
          value: 1,
          title: 'No Data',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        )
      ];
    }

    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final percentage = ((item['amount'] / total) * 100).toStringAsFixed(1);

      return PieChartSectionData(
        color: item['color'],
        value: item['amount'],
        title: '$percentage%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend(String monthYear) {
    final data = monthlyData[monthYear] ?? [];
    final total = monthlyTotals[monthYear] ?? 0.0;

    if (data.isEmpty) {
      return const Center(
        child: Text(
          "No data available",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Column(
      children: data.map((item) {
        final percentage = total > 0 ? ((item['amount'] / total) * 100) : 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: item['color'],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item['category'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                "₹${item['amount'].toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "(${percentage.toStringAsFixed(1)}%)",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  void didUpdateWidget(MonthTabDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedType != widget.selectedType) {
      // Refresh all data when type changes
      monthlyData.clear();
      monthlyTotals.clear();
      for (String month in monthNames) {
        _fetchMonthData(month);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = monthNames[_tabController.index];

    return Column(
      children: [
        // Month Tabs
        TabBar(
          isScrollable: true,
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorWeight: 3,
          tabs: monthNames.map((m) => Tab(text: m)).toList(),
        ),

        // Total Amount
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                "Total ${widget.selectedType}",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "₹${monthlyTotals[currentMonth]?.toStringAsFixed(0) ?? '0'}",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),

        // TabBarView
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: monthNames.map((monthYear) {
              final isLoading = loadingStates[monthYear] ?? true;

              if (isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Pie Chart
                    Expanded(
                      flex: 2,
                      child: PieChart(
                        PieChartData(
                          sections: _buildPieChartSections(monthYear),
                          centerSpaceRadius: 40,
                          sectionsSpace: 4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Legend
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        child: _buildLegend(monthYear),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}