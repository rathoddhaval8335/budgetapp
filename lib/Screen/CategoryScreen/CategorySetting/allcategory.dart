import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../maintabcategory.dart';

class AllAddCatPage extends StatefulWidget {
  final String userId;
  final int initialIndex;
  const AllAddCatPage({super.key, required this.userId, required this.initialIndex});

  @override
  State<AllAddCatPage> createState() => _AllAddCatPageState();
}

class _AllAddCatPageState extends State<AllAddCatPage> {
  int selectedIndex = 0;
  int selectedTabIndex = 0;
  final TextEditingController _controller = TextEditingController();

  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    selectedTabIndex = widget.initialIndex;
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    const apiUrl = "http://192.168.43.192/BUDGET_APP/fd_view_category.php";
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

    // Choose API URL based on selected tab
    String apiUrl = selectedTabIndex == 0
        ? "http://192.168.43.192/BUDGET_APP/fd_insert_exp.php"
        : "http://192.168.43.192/BUDGET_APP/fd_insert_income.php";

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
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
        title: const Text(
          "Add category",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.cancel),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: insertCategory,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Icon + TextField
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.amber.shade600,
                  child: Icon(
                    IconData(
                      int.tryParse(categories[selectedIndex]['cat_icon'].toString()) ?? 0,
                      fontFamily: 'MaterialIcons',
                    ),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Please enter the category name",
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemBuilder: (context, index) {
                  final isSelected = selectedIndex == index;
                  final iconCode = int.tryParse(categories[index]['cat_icon'].toString()) ?? 0;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: isSelected ? Colors.blue.shade600 : Colors.grey.shade200,
                          child: Icon(
                            IconData(iconCode, fontFamily: 'MaterialIcons'),
                            color: isSelected ? Colors.white : Colors.grey,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          categories[index]['cat_name'] ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
