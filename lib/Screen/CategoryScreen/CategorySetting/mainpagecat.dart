import 'package:flutter/material.dart';
import '../maintabcategory.dart';
import 'addexpensecat.dart';
import 'addincomecat.dart';

class MainPageCat extends StatefulWidget {
  final int initialIndex;
  final String userId;

  const MainPageCat({super.key, this.initialIndex = 0, required this.userId});

  @override
  State<MainPageCat> createState() => _AddcatgoryState();
}

class _AddcatgoryState extends State<MainPageCat> {
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
        title: Text("Category Setting",style: TextStyle(fontSize: 20,color: Colors.black,fontWeight: FontWeight.bold),),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
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
          ?  Addexpensecategory(userId: widget.userId,)
          :  AddIncome(userId: widget.userId,),
    );
  }
}
