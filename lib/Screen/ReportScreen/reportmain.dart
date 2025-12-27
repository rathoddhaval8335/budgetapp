import 'package:flutter/material.dart';
import 'Analytics/analytics.dart';

class ReportMainpage extends StatefulWidget {
  final String userId;
  const ReportMainpage({super.key, required this.userId});

  @override
  State<ReportMainpage> createState() => _ReportMainpageState();
}

class _ReportMainpageState extends State<ReportMainpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Reports",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
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
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  "Analytics",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: AnalyticsPage(userId: widget.userId),
    );
  }
}