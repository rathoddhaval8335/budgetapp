import 'dart:convert';
import 'package:budgetapp/Service/apiservice.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../maintabcategory.dart';

class AllAddCatPage extends StatefulWidget {
  final String userId;
  final int initialIndex;
  const AllAddCatPage(
      {super.key, required this.userId, required this.initialIndex});

  @override
  State<AllAddCatPage> createState() => _AllAddCatPageState();
}

class _AllAddCatPageState extends State<AllAddCatPage> {
  int selectedIndex = 0;
  int selectedTabIndex = 0;
  final TextEditingController _controller = TextEditingController();

  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    selectedTabIndex = widget.initialIndex;
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    String apiUrl = ApiService.getUrl("fd_view_category.php");
    try {
      final response = await http.post(Uri.parse(apiUrl));
      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        setState(() {
          categories = List<Map<String, dynamic>>.from(data['data']);
          isLoading = false;
        });
      } else {
        setState(() {
          categories = [];
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "No categories found")),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> insertCategory() async {
    if (_controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter category name")),
      );
      return;
    }

    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No categories available")),
      );
      return;
    }

    String apiUrl = selectedTabIndex == 0
        ? ApiService.getUrl("fd_insert_exp.php")
        : ApiService.getUrl("fd_insert_income.php");

    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        body: {
          "userid": widget.userId,
          "cat_icon": categories[selectedIndex]['cat_icon'].toString(),
          "cat_name": _controller.text,
        },
      );

      var data = jsonDecode(response.body);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? "Unknown error")),
      );

      if (data['status'] == "success") {
        // Refresh data before navigating back
        await refreshParentPage();
        Navigator.pop(context, true); // Pass true to indicate refresh needed
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // Function to refresh the parent page (ExpensePage or IncomePage)
  Future<void> refreshParentPage() async {
    // This will trigger refresh in the parent page when we pop back
    // You can also use GetX controllers if you have them
    print("Category added successfully, parent page should refresh");
  }

  Future<void> _handleRefresh() async {
    setState(() {
      isLoading = true;
    });
    await fetchCategories();
  }

  // Function to manually refresh categories
  void _triggerRefresh() {
    _refreshIndicatorKey.currentState?.show();
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
        title: Text(
          "Add category",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isLargeScreen ? 22 : 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.cancel,
            size: isLargeScreen ? 28 : 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Refresh button
          IconButton(
            icon: Icon(Icons.refresh, size: isLargeScreen ? 24 : 20),
            onPressed: () {
              _triggerRefresh();
            },
            tooltip: 'Refresh Categories',
          ),
          // Check (Save) button
          IconButton(
            icon: Icon(Icons.check, size: isLargeScreen ? 28 : 24),
            onPressed: insertCategory,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isLargeScreen ? 48 : 36),
          child: ExInTabpage(
            selectedIndex: selectedTabIndex,
            onTabChanged: (index) {
              setState(() {
                selectedTabIndex = index;
              });
            },
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _handleRefresh,
            color: Colors.blue.shade600,
            backgroundColor: Colors.white,
            strokeWidth: 2.5,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: isLargeScreen ? 24 : 16,
                    right: isLargeScreen ? 24 : 16,
                    top: isLargeScreen ? 24 : 16,
                    bottom: 16, // Reduced bottom padding
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon + TextField
                      Row(
                        children: [
                          CircleAvatar(
                            radius: isLargeScreen ? 24 : 18,
                            backgroundColor: Colors.amber.shade600,
                            child: Icon(
                              categories.isNotEmpty
                                  ? IconData(
                                int.tryParse(categories[selectedIndex]
                                ['cat_icon']
                                    .toString()) ??
                                    0,
                                fontFamily: 'MaterialIcons',
                              )
                                  : Icons.category,
                              color: Colors.white,
                              size: isLargeScreen ? 24 : 20,
                            ),
                          ),
                          SizedBox(width: isLargeScreen ? 16 : 12),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: InputDecoration(
                                hintText: "Please enter the category name",
                                filled: true,
                                fillColor: Colors.grey.shade200,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isLargeScreen ? 20 : 16,
                                  vertical: isLargeScreen ? 18 : 14,
                                ),
                              ),
                              style: TextStyle(fontSize: isLargeScreen ? 18 : 16),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isLargeScreen ? 20 : 16),

                      // GridView Section with fixed height
                      Container(
                        height: constraints.maxHeight * 0.5, // Reduced height
                        child: isLoading
                            ? const Center(
                          child: CircularProgressIndicator(),
                        )
                            : categories.isEmpty
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.category_outlined,
                                size: isLargeScreen ? 64 : 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: isLargeScreen ? 16 : 12),
                              Text(
                                "No Categories Available",
                                style: TextStyle(
                                  fontSize: isLargeScreen ? 18 : 14,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: isLargeScreen ? 8 : 6),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: isLargeScreen ? 32 : 24),
                                child: Text(
                                  "Pull down to refresh or try again later",
                                  style: TextStyle(
                                    fontSize: isLargeScreen ? 14 : 12,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        )
                            : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: categories.length,
                          gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isLargeScreen ? 6 : 4,
                            crossAxisSpacing: isLargeScreen ? 12 : 8,
                            mainAxisSpacing: isLargeScreen ? 12 : 8,
                            childAspectRatio: isLargeScreen ? 0.9 : 0.8,
                          ),
                          itemBuilder: (context, index) {
                            final isSelected = selectedIndex == index;
                            final iconCode = int.tryParse(
                                categories[index]['cat_icon']
                                    .toString()) ??
                                0;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedIndex = index;
                                });
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: isLargeScreen ? 28 : 22,
                                    backgroundColor: isSelected
                                        ? Colors.blue.shade600
                                        : Colors.grey.shade200,
                                    child: Icon(
                                      IconData(iconCode,
                                          fontFamily: 'MaterialIcons'),
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey,
                                      size: isLargeScreen ? 28 : 22,
                                    ),
                                  ),
                                  SizedBox(height: isLargeScreen ? 6 : 4),
                                  Text(
                                    categories[index]['cat_name'] ?? '',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: isLargeScreen ? 13 : 11,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // Spacer to push content up
                      SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}