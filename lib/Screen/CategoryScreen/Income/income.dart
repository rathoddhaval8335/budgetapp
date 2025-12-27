import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Controllers/Incomecontroller.dart';
import '../../../Service/apiservice.dart';
import '../CategorySetting/mainpagecat.dart';
import '../calculator.dart';

class IncomePage extends StatefulWidget {
  final String userId;
  const IncomePage({super.key, required this.userId});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  late IncomeController controller;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    controller = Get.put(IncomeController(widget.userId));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshIndicatorKey.currentState?.show();
    });
  }

  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          MainPageCat(initialIndex: 0, userId: widget.userId),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.ease;
        final tween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  Future<void> _handleRefresh() async {
    await controller.refreshData();
  }

  void _triggerRefresh() {
    _refreshIndicatorKey.currentState?.show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _triggerRefresh,
        child: Obx(
              () => RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _handleRefresh,
            color: Colors.blue,
            backgroundColor: Colors.white,
            strokeWidth: 2.5,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                padding: const EdgeInsets.only(bottom: 80), // FAB के लिए space
                child: SizedBox(
                  // Height fixed ना रखें
                  child: controller.isLoading.value
                      ? SizedBox(
                    height: MediaQuery.of(context).size.height - 100,
                    child: const Center(
                        child: CircularProgressIndicator()),
                  )
                      : controller.incomeCategories.isEmpty
                      ? SizedBox(
                    height: MediaQuery.of(context).size.height - 100,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "No Income Categories Found",
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Add categories by tapping the + button below",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                      : Padding(
                    padding: const EdgeInsets.all(10),
                    child: GridView.builder(
                      shrinkWrap: true, // Important
                      physics: const NeverScrollableScrollPhysics(), // Important
                      itemCount: controller.incomeCategories.length,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.85,
                      ),
                      itemBuilder: (context, index) {
                        var cat = controller.incomeCategories[index];

                        String id = cat['id'].toString();
                        String iconCode = cat['cat_icon'].toString();
                        String name = cat['cat_name'].toString();

                        IconData iconData = IconData(
                          int.tryParse(iconCode) ?? 0,
                          fontFamily: 'MaterialIcons',
                        );

                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            var result = await showDialog(
                              context: context,
                              builder: (context) => CalculatorDialog(
                                categoryName: name,
                                userId: widget.userId,
                                catIcon: iconCode,
                                apiUrl: ApiService.getUrl(
                                    "fd_income_amount.php"),
                                type: "Income",
                              ),
                            );
                            if (result != null) {
                              print("Income added: $result");
                              controller.fetchIncomeCategories();
                            }
                          },
                          child: Column(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey,
                                child: Icon(
                                  iconData,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      // FAB को proper position में रखें
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade700,
        onPressed: () {
          Navigator.of(context).push(_createRoute());
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}