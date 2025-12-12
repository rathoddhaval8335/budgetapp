import 'package:flutter/material.dart';

import 'monthtab.dart';
import 'yeartab.dart';


class ChartMainpage extends StatefulWidget {
  final String userId;
  const ChartMainpage({super.key, required this.userId});

  @override
  State<ChartMainpage> createState() => _ChartMainpageState();
}

class _ChartMainpageState extends State<ChartMainpage> {
  int selectedIndex = 0;
  List<String> _expenseitem=["Expense","Income"];
  String _selectedItem ="Expense";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
        title: DropdownButton(
            value: _selectedItem,
            items: _expenseitem.map((String item){
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item,style: TextStyle(color:Colors.black,fontWeight: FontWeight.w900,fontSize: 15),),
              );
            }).toList(),
            onChanged: (String? val){
              setState(() {
                _selectedItem=val!;
              });
            }
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 60),
            height: 32,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIndex = 0;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: selectedIndex == 0
                            ? Colors.black
                            : Colors.transparent,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "Month",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: selectedIndex == 0
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Accounts button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIndex = 1;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: selectedIndex == 1
                            ? Colors.black
                            : Colors.transparent,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "Year",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: selectedIndex == 1
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: selectedIndex == 0
          ?  MonthTabDemo(userId:widget.userId, selectedType:_selectedItem)
          :  YearTab(userId: widget.userId, selectedType:_selectedItem),
    );
  }
}
