import 'package:budgetapp/Service/apiservice.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BudgetUpdateDialog extends StatefulWidget {
  final int id; // Budget ID
  final String title; // Category Name
  final double currentBudget;
  final String userId;// Current budget value
  final String month;

  const BudgetUpdateDialog({
    super.key,
    required this.id,
    required this.title,
    required this.currentBudget, required this.userId, required this.month,
  });

  @override
  State<BudgetUpdateDialog> createState() => _BudgetUpdateDialogState();
}

class _BudgetUpdateDialogState extends State<BudgetUpdateDialog> {
  late TextEditingController _budgetController;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _budgetController = TextEditingController(text: widget.currentBudget.toStringAsFixed(0));
  }

  Future<void> updateBudget() async {
    final newBudget = _budgetController.text.trim();
    if (newBudget.isEmpty) return;

    setState(() => isLoading = true);

    //final url = Uri.parse('http://192.168.43.192/BUDGET_APP/fd_budget_update.php');
    final url = Uri.parse(ApiService.getUrl("fd_budget_update.php"));
    try {
      final response = await http.post(url, body: {
        "id": widget.id.toString(),
        "budget": newBudget,
      });

      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Budget updated successfully")),
        );
        Navigator.pop(context, true); // Close dialog and return success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonData['message'] ?? "Failed to update budget")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error updating budget")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Update ${widget.title}"),
      content: TextField(
        controller: _budgetController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: "New Budget",
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : updateBudget,
          child: isLoading
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
              : const Text("Update"),
        ),
      ],
    );
  }
}
