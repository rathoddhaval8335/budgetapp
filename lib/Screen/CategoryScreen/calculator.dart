import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:math_expressions/math_expressions.dart'; // For calculation

class CalculatorDialog extends StatefulWidget {
  final String categoryName;
  final String userId;
  final String catIcon;
  final String apiUrl;
  final String type;

  const CalculatorDialog({super.key, required this.categoryName, required this.userId, required this.catIcon, required this.apiUrl, required this.type});

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  String amountInput = '';
  DateTime selectedDate = DateTime.now();
  TextEditingController noteController = TextEditingController();

  void onKeyPressed(String value) {
    setState(() {
      if (value == '⌫') {
        if (amountInput.isNotEmpty) {
          amountInput = amountInput.substring(0, amountInput.length - 1);
        }
      } else if (value == '=') {
        calculateResult();
      } else {
        amountInput += value;
      }
    });
  }

  void calculateResult() {
    try {
      Parser p = Parser();
      Expression exp = p.parse(amountInput.replaceAll('×', '*').replaceAll('÷', '/'));
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);
      amountInput = eval.toStringAsFixed(0); // remove decimals for simplicity
    } catch (e) {
      amountInput = 'Error';
    }
  }

  Widget buildKey(String value, {Color? color}) {
    return Expanded(
      child: InkWell(
        onTap: () => onKeyPressed(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 50,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color ?? Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void submitCalculator(String catIcon, String catName) async {
    try {
      var response = await http.post(
        Uri.parse(widget.apiUrl),
        body: {
          "user_id": widget.userId,
          "cat_icon": catIcon,
          "cat_name": catName,
          "amount": amountInput,
          "note": noteController.text,
          "date": DateFormat('yyyy-MM-dd').format(selectedDate),
        },
      );

      var result = jsonDecode(response.body);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Unknown error")),
      );

      if(result['status'] == 'success'){
        Navigator.pop(context); // close dialog
      }

    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        "Add ${widget.type}: ${widget.categoryName}",
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            // Amount display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.centerRight,
              child: Text(
                amountInput.isEmpty ? '0' : amountInput,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            // Calculator keys
            Column(
              children: [
                Row(children: [
                  buildKey('7'),
                  buildKey('8'),
                  buildKey('9'),
                  buildKey('+', color: Colors.orange.shade200),
                ]),
                Row(children: [
                  buildKey('4'),
                  buildKey('5'),
                  buildKey('6'),
                  buildKey('-', color: Colors.orange.shade200),
                ]),
                Row(children: [
                  buildKey('1'),
                  buildKey('2'),
                  buildKey('3'),
                  buildKey('⌫', color: Colors.red.shade200),
                ]),
                Row(children: [
                  buildKey('0'),
                  buildKey('.'),
                  buildKey('=', color: Colors.blue.shade400), // = button
                  Expanded(child: Container()),
                ]),
              ],
            ),
             SizedBox(height: 12),
            // Date picker
            InkWell(
              onTap: pickDate,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('d MMM yyyy').format(selectedDate),
                      style:  TextStyle(fontSize: 14),
                    ),
                     Icon(Icons.calendar_today, size: 18),
                  ],
                ),
              ),
            ),
             SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                hintText: 'Add a note',
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding:
                 EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              style:  TextStyle(fontSize: 14),
            ),
             SizedBox(height: 12),
            // ✔ submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  submitCalculator(widget.catIcon, widget.categoryName);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:  EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:  Text(
                  ' Submit',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
