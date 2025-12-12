import 'package:flutter/material.dart';

import '../Screen/CategoryScreen/addcatgory.dart';
import '../Screen/ChartScreen/chart.dart';
import '../Screen/ProfileScreen/profile.dart';
import '../Screen/RecordScreen/record.dart';
import '../Screen/ReportScreen/Analytics/analytics.dart';
import '../Screen/ReportScreen/reportmain.dart';

class BottomNav extends StatefulWidget {
  final String userId;
  const BottomNav({super.key, required this.userId});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {

  int _SelectedIndex=0;
  late List<Widget> _Pages;

  @override
  void initState() {
    super.initState();
    _Pages = [
      RecordPage(userId: widget.userId),
      ChartMainpage(userId: widget.userId),
      ReportMainpage(userId: widget.userId),
      ProfilePage(userId: widget.userId),
    ];
  }

  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>  Addcatgory(userId: widget.userId),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    print("User ID: ${widget.userId}");
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.blue[700],
          onPressed: () {
            Navigator.of(context).push(_createRoute());
          },
          child: const Icon(Icons.add, color: Colors.black),
        ),


    body: _Pages[_SelectedIndex],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon:  Icon(Icons.event_note,
                  color: _SelectedIndex == 0 ? Colors.blue:Colors.grey),
              onPressed: () {
                  setState(() {
                    _SelectedIndex =0;
                  });
              },
            ),
            IconButton(
              icon:  Icon(Icons.bar_chart, color: _SelectedIndex==1 ? Colors.blue:Colors.grey),
              onPressed: () {
                setState(() {
                  _SelectedIndex=1;
                });

              },
            ),
            const SizedBox(width: 40),
            IconButton(
              icon:  Icon(Icons.task, color: _SelectedIndex==2?Colors.blue:Colors.grey),
              onPressed: () {
                setState(() {
                  _SelectedIndex=2;
                });

              },
            ),
            IconButton(
              icon:  Icon(Icons.person, color:_SelectedIndex==3?Colors.blue:Colors.grey),
              onPressed: () {
                setState(() {
                  _SelectedIndex=3;
                });
              },
            ),
          ],
        ),
      ),
    );

  }
}
