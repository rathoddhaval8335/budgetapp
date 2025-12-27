import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Controllers/incomecategorycontroller.dart';
import 'allcategory.dart';

class AddIncome extends StatefulWidget {
  final String userId;
  final GlobalKey<RefreshIndicatorState>? refreshKey;

  const AddIncome({super.key, required this.userId, this.refreshKey});

  @override
  State<AddIncome> createState() => _AddIncomeState();
}

class _AddIncomeState extends State<AddIncome> {
  late IncomeCategoryController controller;
  final GlobalKey<RefreshIndicatorState> _localRefreshKey =
  GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    // Get existing controller or create new one
    try {
      controller = Get.find<IncomeCategoryController>();
    } catch (e) {
      controller = Get.put(IncomeCategoryController(widget.userId));
    }

    // Initial data load
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.refreshData();
    });
  }

  Future<void> _handleRefresh() async {
    await controller.refreshData();
  }

  void _triggerRefresh() {
    (widget.refreshKey ?? _localRefreshKey).currentState?.show();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _triggerRefresh,
      child: GetBuilder<IncomeCategoryController>(
        builder: (controller) {
          return Stack(
            children: [
              RefreshIndicator(
                key: widget.refreshKey ?? _localRefreshKey,
                onRefresh: _handleRefresh,
                color: Colors.blue,
                backgroundColor: Colors.white,
                strokeWidth: 2.5,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.75,
                        child: controller.isLoading.value
                            ? const Center(
                          child: CircularProgressIndicator(
                            valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        )
                            : controller.categories.isEmpty
                            ? Center(
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
                                "Add categories by tapping the button below",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: _triggerRefresh,
                                icon: Icon(Icons.refresh),
                                label: Text("Refresh"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                            : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: controller.categories.length,
                          itemBuilder: (context, index) {
                            var cat = controller.categories[index];
                            String iconCode =
                                cat['cat_icon']?.toString() ?? '0';
                            String categoryName =
                                cat['cat_name']?.toString() ??
                                    'Unknown';
                            String id = cat['id']?.toString() ?? '';

                            IconData iconData = IconData(
                              int.tryParse(iconCode) ?? 0,
                              fontFamily: 'MaterialIcons',
                            );

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                  BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                      Colors.grey.withOpacity(0.1),
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  leading: IconButton(
                                    icon: Icon(Icons.remove_circle,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _showDeleteDialog(context, id),
                                  ),
                                  title: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                        Colors.blue.shade50,
                                        child: Icon(
                                          iconData,
                                          color: Colors.blue,
                                          size: 20,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          categoryName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                          ),
                                          overflow:
                                          TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing:
                                  Icon(Icons.menu, color: Colors.grey),
                                  onTap: () {
                                    // You can add onTap functionality here if needed
                                    print('Tapped: $categoryName');
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              var result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AllAddCatPage(
                                    userId: widget.userId,
                                    initialIndex: 1,
                                  ),
                                ),
                              );

                              if (result == true) {
                                // Refresh if category was added
                                await controller.refreshData();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                            icon: Icon(Icons.add, size: 20),
                            label: Text(
                              "Add Category",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Delete Loading Overlay
              Obx(() => controller.isDeleting.value
                  ? Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              )
                  : const SizedBox.shrink()),
            ],
          );
        },
      ),
    );
  }

  // Simple dialog without GetX
  Future<void> _showDeleteDialog(BuildContext context, String id) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Category"),
          content: const Text(
              "Are you sure you want to delete this Income category?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await controller.deleteCategory(id);
    }
  }
}