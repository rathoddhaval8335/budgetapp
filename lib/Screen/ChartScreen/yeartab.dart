import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class YearTab extends StatefulWidget {
  final String userId;
  final String selectedType;
  const YearTab({super.key, required this.userId, required this.selectedType});

  @override
  State<YearTab> createState() => _YearTabState();
}

class _YearTabState extends State<YearTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<String> years;
  Map<String, List<Map<String, dynamic>>> yearlyData = {};
  Map<String, bool> loadingStates = {};
  Map<String, double> yearlyTotals = {};

  @override
  void initState() {
    super.initState();

    int startYear = 2000;
    int currentYear = DateTime.now().year;

    years = [for (int i = startYear; i <= currentYear; i++) "$i"];

    _tabController = TabController(length: years.length, vsync: this);
    _tabController.animateTo(years.length - 1);

    // Fetch data for all years
    for (String year in years) {
      _fetchYearData(year);
    }

    // Listen to tab changes
    _tabController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _fetchYearData(String year) async {
    setState(() {
      loadingStates[year] = true;
    });

    try {
      var response = await http.post(
        Uri.parse("http://192.168.43.192/BUDGET_APP/yearly_chart_data.php"),
        body: {
          "user_id": widget.userId,
          "year": year,
          "type": widget.selectedType.toLowerCase(),
        },
      );

      print("Response for $year: ${response.statusCode}");
      print("Response body: ${response.body}");

      var jsonResponse = jsonDecode(response.body);

      if (jsonResponse['status'] == 'success') {
        List<dynamic> data = jsonResponse['data'];
        double total = jsonResponse['total_amount'] ?? 0.0;

        List<Map<String, dynamic>> formattedData = data.map((item) {
          double amount = double.parse(item['amount'].toString());
          return {
            "category": item['category'],
            "amount": amount,
            "color": _getCategoryColor(item['category']),
          };
        }).toList();

        setState(() {
          yearlyData[year] = formattedData;
          yearlyTotals[year] = total;
          loadingStates[year] = false;
        });
      } else {
        print("Error response: $jsonResponse");
        setState(() {
          yearlyData[year] = [];
          yearlyTotals[year] = 0.0;
          loadingStates[year] = false;
        });
      }
    } catch (e) {
      print("Error fetching data for $year: $e");
      setState(() {
        yearlyData[year] = [];
        yearlyTotals[year] = 0.0;
        loadingStates[year] = false;
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

  List<PieChartSectionData> _buildPieChartSections(String year) {
    final data = yearlyData[year] ?? [];
    final total = yearlyTotals[year] ?? 1.0;

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

  Widget _buildLegend(String year) {
    final data = yearlyData[year] ?? [];
    final total = yearlyTotals[year] ?? 0.0;

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
  void didUpdateWidget(YearTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedType != widget.selectedType) {
      // Refresh all data when type changes
      yearlyData.clear();
      yearlyTotals.clear();
      for (String year in years) {
        _fetchYearData(year);
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
    final currentYear = years[_tabController.index];

    return Column(
      children: [
        // Year Tabs
        TabBar(
          isScrollable: true,
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorWeight: 3,
          tabs: years.map((y) => Tab(text: y)).toList(),
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
                "₹${yearlyTotals[currentYear]?.toStringAsFixed(0) ?? '0'}",
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
            children: years.map((year) {
              final isLoading = loadingStates[year] ?? true;

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
                          sections: _buildPieChartSections(year),
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
                        child: _buildLegend(year),
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