import 'dart:convert';
import 'package:budgetapp/Service/apiservice.dart';
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
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();

    int startYear = 2000;
    int currentYear = DateTime.now().year;

    years = [for (int i = startYear; i <= currentYear; i++) "$i"];

    _tabController = TabController(length: years.length, vsync: this);

    // Listen to tab changes BEFORE fetching data
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    // Set initial tab position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tabController.animateTo(years.length - 1);
    });

    // Fetch data for all years
    for (String year in years) {
      _fetchYearData(year);
    }
  }

  Future<void> _fetchYearData(String year) async {
    setState(() {
      loadingStates[year] = true;
    });

    try {
      var response = await http.post(
        Uri.parse(ApiService.getUrl("yearly_chart_data.php")),
        body: {
          "user_id": widget.userId,
          "year": year,
          "type": widget.selectedType.toLowerCase(),
        },
      );

      print("=== Yearly Data Request ===");
      print("Year: $year");
      print("User ID: ${widget.userId}");
      print("Type: ${widget.selectedType.toLowerCase()}");
      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'success') {
          List<dynamic> data = jsonResponse['data'] ?? [];
          double total = double.tryParse(jsonResponse['total_amount']?.toString() ?? '0') ?? 0.0;

          print("Total Amount for $year: $total");
          print("Data Count: ${data.length}");

          List<Map<String, dynamic>> formattedData = data.map((item) {
            double amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
            return {
              "category": item['category']?.toString() ?? 'Unknown',
              "amount": amount,
              "color": _getCategoryColor(item['category']?.toString() ?? 'Unknown'),
            };
          }).toList();

          setState(() {
            yearlyData[year] = formattedData;
            yearlyTotals[year] = total;
            loadingStates[year] = false;
            _isInitialLoad = false;
          });

          print("Successfully loaded data for $year: ${formattedData.length} categories");
        } else {
          print("API returned error status: ${jsonResponse['message'] ?? 'Unknown error'}");
          setState(() {
            yearlyData[year] = [];
            yearlyTotals[year] = 0.0;
            loadingStates[year] = false;
            _isInitialLoad = false;
          });
        }
      } else {
        print("HTTP Error: ${response.statusCode}");
        setState(() {
          yearlyData[year] = [];
          yearlyTotals[year] = 0.0;
          loadingStates[year] = false;
          _isInitialLoad = false;
        });
      }
    } catch (e, stackTrace) {
      print("Error fetching data for $year: $e");
      print("Stack Trace: $stackTrace");
      setState(() {
        yearlyData[year] = [];
        yearlyTotals[year] = 0.0;
        loadingStates[year] = false;
        _isInitialLoad = false;
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
      Colors.brown,
      Colors.cyan,
      Colors.deepPurple,
      Colors.lime,
    ];

    int index = category.hashCode.abs() % colors.length;
    return colors[index];
  }

  List<PieChartSectionData> _buildPieChartSections(String year) {
    final data = yearlyData[year] ?? [];
    final total = yearlyTotals[year] ?? 1.0;

    print("Building chart for $year: ${data.length} items, total: $total");

    if (data.isEmpty || total == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey[300],
          value: 1,
          title: 'No Data',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
          showTitle: true,
        )
      ];
    }

    return data.map((item) {
      final percentage = total > 0 ? ((item['amount'] / total) * 100) : 0;
      return PieChartSectionData(
        color: item['color'],
        value: item['amount'],
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        showTitle: percentage > 3, // Only show title if percentage > 3%
      );
    }).toList();
  }

  Widget _buildLegend(String year) {
    final data = yearlyData[year] ?? [];
    final total = yearlyTotals[year] ?? 0.0;

    print("Building legend for $year: ${data.length} items");

    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              "No data available for this year",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Add ${widget.selectedType.toLowerCase()} entries to see the chart",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        final percentage = total > 0 ? ((item['amount'] / total) * 100) : 0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: item['color'],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['category'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${percentage.toStringAsFixed(1)}% of total',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "₹${item['amount'].toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void didUpdateWidget(YearTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedType != widget.selectedType ||
        oldWidget.userId != widget.userId) {
      // Clear all data and refresh
      setState(() {
        yearlyData.clear();
        yearlyTotals.clear();
        loadingStates.clear();
        _isInitialLoad = true;
      });

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

    return Scaffold(
      body: Column(
        children: [
          // Year Tabs Header
          Container(
            color: Colors.white,
            child: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  controller: _tabController,
                  indicatorColor: Colors.blue,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  indicatorWeight: 3,
                  tabs: years.map((y) => Tab(text: y)).toList(),
                ),
              ],
            ),
          ),

          // Total Amount Card
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(
                    "Total ${widget.selectedType} for $currentYear",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "₹${yearlyTotals[currentYear]?.toStringAsFixed(2) ?? '0.00'}",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content Area
          Expanded(
            child: _isInitialLoad
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    "Loading yearly data...",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
                : TabBarView(
              controller: _tabController,
              children: years.map((year) {
                final isLoading = loadingStates[year] ?? true;
                final data = yearlyData[year] ?? [];
                final hasData = data.isNotEmpty;

                if (isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          "Loading data for year...",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Pie Chart Container
                      Expanded(
                        flex: hasData ? 2 : 1,
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Text(
                                  "${widget.selectedType} Distribution",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Expanded(
                                  child: PieChart(
                                    PieChartData(
                                      sections: _buildPieChartSections(year),
                                      centerSpaceRadius: 50,
                                      sectionsSpace: 2,
                                      startDegreeOffset: -90,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Legend Container
                      Expanded(
                        flex: hasData ? 3 : 2,
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Category Breakdown",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: _buildLegend(year),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}