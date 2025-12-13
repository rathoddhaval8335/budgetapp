import 'dart:convert';
import 'package:budgetapp/Service/apiservice.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class BudgetInputDialog extends StatefulWidget {
  final String categoryName;
  final int categoryIcon;
  final String categoryId;
  final String userId;
  final String month;

  const BudgetInputDialog({
    Key? key,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryId,
    required this.userId,
    required this.month,
  }) : super(key: key);

  @override
  State<BudgetInputDialog> createState() => _BudgetInputDialogState();
}

class _BudgetInputDialogState extends State<BudgetInputDialog> {
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;

  Future<void> submitBudget() async {
    String amount = _amountController.text.trim();
    if (amount.isEmpty) return;

    setState(() { _isLoading = true; });

    try {
      final response = await http.post(
       // Uri.parse("http://192.168.43.192/BUDGET_APP/fd_bud_insert.php"),
        Uri.parse(ApiService.getUrl("fd_bud_insert.php")),
        body: {
          "user_id": widget.userId,
          "cat_id": widget.categoryId,
          "cat_name": widget.categoryName,
          "cat_icon": widget.categoryIcon.toString(),
          "budget": amount,
          "month": widget.month, // Add month to the request
        },
      );

      setState(() { _isLoading = false; });

      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Something went wrong'))
      );

      if (data['status'] == 'success') {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Set Budget for: ${widget.categoryName}"),
          SizedBox(height: 4),
          Text(
            "Month: ${widget.month}",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text("Monthly Budget", style: TextStyle(fontWeight: FontWeight.w500)),
              Spacer(),
              CircleAvatar(
                backgroundColor: Colors.grey[300],
                child: Icon(
                  IconData(widget.categoryIcon, fontFamily: 'MaterialIcons'),
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Enter Amount",
              border: OutlineInputBorder(),
              prefixText: "₹ ",
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : submitBudget,
          child: _isLoading
              ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(color: Colors.white),
          )
              : Text("Submit"),
        ),
      ],
    );
  }
}