import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'allcategory.dart';

class AddIncome extends StatefulWidget {
  final String userId;
  const AddIncome({super.key, required this.userId});

  @override
  State<AddIncome> createState() => _AddIncomeState();
}

class _AddIncomeState extends State<AddIncome> {

  List<dynamic> categories = [];
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    fetchCategories();
  }
  Future<void> fetchCategories() async {
    String apiUrl = "http://192.168.43.192/BUDGET_APP/fd_view_income.php";

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
  Future<void> deleteCategory(String id) async {
    String apiUrl = "http://192.168.43.192/BUDGET_APP/fd_delete_income.php";

    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        body: {
          "id": id.toString(),
          "userid": widget.userId.toString(),
        },
      );


      var jsonData = jsonDecode(response.body);
      print("Delete Response: $jsonData"); // for debugging

      if (jsonData['status'] == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Category deleted successfully")),
        );
        fetchCategories(); // refresh after delete
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonData['message'] ?? "Delete failed")),
        );
      }
    } catch (e) {
      print("Delete error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error connecting to server")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ?  Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                var cat = categories[index];
                return Padding(
                  padding:  EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading:IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => confirmDelete(cat['id'].toString()),
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


                      trailing:
                      Icon(Icons.menu, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
          ),


          Padding(
            padding:  EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>AllAddCatPage(userId: widget.userId,initialIndex: 1,)));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(Icons.add),
                label:Text(
                    "Add Category",
                    style: TextStyle(fontSize: 16)
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Category"),
        content: const Text("Are you sure you want to delete this category?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(onPressed: () async {
            Navigator.pop(ctx);
            await deleteCategory(id);
          }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

}