import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TransactionDetailPage extends StatelessWidget {
  final String id;
  final String income_id;
  final String categoryName;
  final IconData iconData;
  final String type;
  final String amount;
  final String date;

  const TransactionDetailPage({
    super.key,
    required this.id,
    required this.income_id,
    required this.categoryName,
    required this.iconData,
    required this.type,
    required this.amount,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    String formattedDate = "";
    if (date.isNotEmpty) {
      final parts = date.split(" ");
      formattedDate =
      parts.length >= 3 ? parts.sublist(0, 3).join(" ") : parts.join(" ");
    }

    TextEditingController amountController = TextEditingController(text: amount);
    TextEditingController dateController = TextEditingController(text: date);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Details"),
        backgroundColor: Colors.blue.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + Category Name
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.yellow.shade700,
                  child: Icon(iconData, color: Colors.black, size: 30),
                ),
                const SizedBox(width: 15),
                Text(
                  categoryName,
                  style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Type
            Row(
              children: [
                const SizedBox(width: 5),
                const Text(
                  "Type",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(width: 20),
                Text(
                  type,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 15),
            // Amount
            Row(
              children: [
                const SizedBox(width: 5),
                const Text(
                  "Amount",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(width: 20),
                Text(
                  amount,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 15),
            // Date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 5),
                const Text(
                  "Date",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "( Add $date )",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                )
              ],
            ),
            const Spacer(),
            Row(
              children: [
                // Edit Button
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.yellow.shade700,
                                child: Icon(iconData, color: Colors.black),
                              ),
                              const SizedBox(width: 10),
                              Text(categoryName),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: amountController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Amount",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 15),
                              TextField(
                                controller: dateController,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: "Date",
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                onTap: () async {
                                  DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.tryParse(
                                        dateController.text) ??
                                        DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (pickedDate != null) {
                                    String formattedDate =
                                        "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                                    dateController.text = formattedDate;
                                  }
                                },
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel")),
                            ElevatedButton(
                              onPressed: () async {
                                String newAmount = amountController.text;
                                String newDate = dateController.text;

                                if (newAmount.isEmpty || newDate.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                        Text("All fields are required")),
                                  );
                                  return;
                                }

                                String apiUrl = type == "Expense"
                                    ? "http://192.168.43.192/BUDGET_APP/fd_update_expense.php"
                                    : "http://192.168.43.192/BUDGET_APP/fd_upincome_tranction.php";

                                var response = await http.post(
                                  Uri.parse(apiUrl),
                                  body: type == "Expense"
                                      ? {
                                    "id": id,
                                    "amount": newAmount,
                                    "date": newDate,
                                  }
                                      : {
                                    "income_id": income_id,
                                    "amount": newAmount,
                                    "date": newDate,
                                  },
                                );


                                if (response.statusCode == 200) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                        Text("Transaction updated!")),
                                  );
                                  Navigator.pop(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            "Error: ${response.statusCode}")),
                                  );
                                }
                              },
                              child: const Text("Save"),
                            ),
                          ],
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                      shape: const RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text("Edit"),
                  ),
                ),
                const SizedBox(width: 10),
                // Delete Button
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      bool confirm = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Confirm Delete"),
                          content: Text(
                              "Are you sure you want to delete $categoryName?"),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                      ) ??
                          false;

                      if (!confirm) return;

                      String deleteApi = type == "Expense"
                          ? "http://192.168.43.192/BUDGET_APP/fd_delete_expense.php"
                          : "http://192.168.43.192/BUDGET_APP/fd_delete_intraction.php";

                      var response = await http.post(
                        Uri.parse(deleteApi),
                        body: type == "Expense"
                            ? {"id": id}
                            : {"income_id": income_id}, // Income id
                      );


                      if (response.statusCode == 200) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Transaction deleted!")),
                        );
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                              Text("Error: ${response.statusCode}")),
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      shape: const RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text("Delete"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
