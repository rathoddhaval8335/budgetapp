import 'dart:convert';
import 'package:budgetapp/Service/apiservice.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../CategorySetting/mainpagecat.dart';
import '../calculator.dart';

class IncomePage extends StatefulWidget {
  final String userId;
  const IncomePage({super.key, required this.userId});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  List<dynamic> expenseCategories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchIncomeCategories();
  }

  Future<void> fetchIncomeCategories() async {
    try {
      var response = await http.post(
        //Uri.parse("http://192.168.43.192/BUDGET_APP/fd_view_income.php"),
        Uri.parse(ApiService.getUrl("fd_view_income.php")),
        body: {"userid": widget.userId},
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'success') {
          setState(() {
            expenseCategories = jsonResponse['data'] ?? [];
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching data: $e")),
      );
    }
  }

  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          MainPageCat(initialIndex: 0, userId: widget.userId),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.ease;
        final tween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : expenseCategories.isEmpty
          ? const Center(
        child: Text(
          "No Expense Categories Found",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : Padding(
        padding:  EdgeInsets.all(10),
        child: GridView.builder(
          itemCount: expenseCategories.length,
          gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            var cat = expenseCategories[index];

            // ID fetched but not shown
            String id = cat['id'].toString();
            String iconCode = cat['cat_icon'].toString();
            String name = cat['cat_name'].toString();

            IconData iconData = IconData(
              int.tryParse(iconCode) ?? 0,
              fontFamily: 'MaterialIcons',
            );

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async{
                var result = await showDialog(
                  context: context,
                  builder: (context) => CalculatorDialog(
                    categoryName: name,
                    userId: widget.userId,
                    catIcon: iconCode,
                    //apiUrl:"http://192.168.43.192/BUDGET_APP/fd_income_amount.php",
                    apiUrl:ApiService.getUrl("fd_income_amount.php"),
                    type: "Income",
                  ),
                );
                if(result != null){
                  print("Income added: $result");
                  fetchIncomeCategories(); // optional: refresh list
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey,
                    child: Icon(
                      iconData,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade700,
        onPressed: () {
          Navigator.of(context).push(_createRoute());
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
