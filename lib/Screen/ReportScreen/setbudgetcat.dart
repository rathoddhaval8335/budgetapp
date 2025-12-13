import 'dart:convert';
import 'package:budgetapp/Service/apiservice.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'budgetinputdailog.dart';


class Setbudgetcat extends StatefulWidget {
  final String userId;
  final String selectedMonth;
  const Setbudgetcat({super.key, required this.userId, required this.selectedMonth});

  @override
  State<Setbudgetcat> createState() => _SetbudgetcatState();
}

class _SetbudgetcatState extends State<Setbudgetcat> {
  List<dynamic> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    //String apiUrl = "http://192.168.43.192/BUDGET_APP/fd_view_exp.php";
    String apiUrl = ApiService.getUrl("fd_view_exp.php");


    try {
      var response = await http.post(Uri.parse(apiUrl), body: {
        "userid": widget.userId,
      });

      var jsonData = jsonDecode(response.body);

      if (jsonData['status'] == "success") {
        setState(() {
          categories = jsonData['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          categories = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }
  Future<void> deleteBudget(String catName) async {
    //String apiUrl = "http://192.168.43.192/BUDGET_APP/fd_budget_delete.php";
    String apiUrl = ApiService.getUrl("fd_budget_delete.php");

    try {
      var response = await http.post(Uri.parse(apiUrl), body: {
        "cat_name": catName,
      });

      var jsonData = jsonDecode(response.body);
      if (jsonData['status'] == "success") {
        setState(() {
          categories.removeWhere((cat) => cat['cat_name'] == catName);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Category deleted successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonData['message'] ?? "Failed to delete")),
        );
      }
    } catch (e) {
      print("Error deleting category: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error deleting category")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Budget Setting"),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.remove_circle, color: Colors.red), // optional
                        title: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.grey.shade300,
                              child: const Icon(Icons.account_balance_wallet, color: Colors.black),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Monthly Budget",
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                            ),
                          ],
                        ),
                        trailing: const Text("20,000"),
                        onTap: (){
                          showDialog(
                            context: context,
                            builder: (context) => BudgetInputDialog(
                              categoryName: "Monthly Budget",
                              categoryIcon: 0, // no icon
                              categoryId: "monthly", // special id
                              userId: widget.userId,
                              month: widget.selectedMonth,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                } else {
                  // Dynamic categories from API
                  var cat = categories[index - 1]; // shift index by -1
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => confirmDelete(cat['cat_name']),
                        ),
                        title: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.grey.shade300,
                              child: Icon(
                                IconData(
                                  int.tryParse(cat['cat_icon'].toString()) ?? 0,
                                  fontFamily: 'MaterialIcons',
                                ),
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              cat['cat_name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.menu, color: Colors.grey),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => BudgetInputDialog(
                              categoryName: cat['cat_name'],
                              categoryIcon:
                              int.tryParse(cat['cat_icon'].toString()) ?? 0,
                              categoryId: cat['id'].toString(),
                              userId: widget.userId,
                              month: widget.selectedMonth,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }
              },
            ),
          ),

        ],
      ),
    );
  }

  void confirmDelete(String catName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Category"),
        content: const Text("Are you sure you want to delete this category?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await deleteBudget(catName);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
