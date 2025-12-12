import 'package:flutter/material.dart';

class ExInTabpage extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTabChanged;

  const ExInTabpage({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  State<ExInTabpage> createState() => _ExInTabpageState();
}

class _ExInTabpageState extends State<ExInTabpage> {

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  widget.onTabChanged(0);
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: widget.selectedIndex == 0
                      ? Colors.black
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: Center(
                  child: Text(
                    "Expense",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color:  widget.selectedIndex == 0
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
                widget.onTabChanged(1);
              },
              child: Container(
                decoration: BoxDecoration(
                  color:  widget.selectedIndex == 1
                      ? Colors.black
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Center(
                  child: Text(
                    "Income",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color:  widget.selectedIndex == 1
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
    );
  }
}
