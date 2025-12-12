import 'package:flutter/material.dart';

import 'Expense/expense.dart';
import 'Income/income.dart';
import 'maintabcategory.dart';

class Addcatgory extends StatefulWidget {
  final String userId;
  const Addcatgory({super.key, required this.userId});

  @override
  State<Addcatgory> createState() => _AddcatgoryState();
}

class _AddcatgoryState extends State<Addcatgory> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
        title:  Text(
          "Add",
          style: TextStyle(
              fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize:  Size.fromHeight(36),
          child: ExInTabpage(
            selectedIndex: selectedIndex,
            onTabChanged: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
          ),
        ),
      ),
      body: selectedIndex == 0
          ? ExpensePage(userId: widget.userId)
          : IncomePage(userId: widget.userId),
    );
  }
}