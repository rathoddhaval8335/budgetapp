// lib/Views/transaction_list_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Controllers/tranction_controller.dart';
import 'tranctiondetails.dart';

class TransactionListPage extends StatefulWidget {
  final String userId;
  final String selectedMonth;
  final String selectedYear;
  final VoidCallback? onDataRefresh;

  const TransactionListPage({
    super.key,
    required this.userId,
    required this.selectedMonth,
    required this.selectedYear,
    this.onDataRefresh,
  });

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  late TransactionController controller;

  @override
  void initState() {
    super.initState();
    // Initialize controller with Get.put
    controller = Get.put(
      TransactionController(
        userId: widget.userId,
        selectedMonth: widget.selectedMonth,
        selectedYear: widget.selectedYear,
      ),
      tag: '${widget.userId}_${widget.selectedMonth}_${widget.selectedYear}',
    );
  }

  @override
  void didUpdateWidget(TransactionListPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedMonth != widget.selectedMonth ||
        oldWidget.selectedYear != widget.selectedYear) {
      // Update controller with new month/year
      controller.updateMonthYear(widget.selectedMonth, widget.selectedYear);
    }
  }

  @override
  void dispose() {
    // Remove controller when page is disposed
    Get.delete<TransactionController>(
      tag: '${widget.userId}_${widget.selectedMonth}_${widget.selectedYear}',
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        if (controller.isLoading.value && controller.transactions.isEmpty) {
          return _buildLoadingState();
        }

        if (controller.transactions.isEmpty && !controller.isLoading.value) {
          return _buildEmptyState();
        }

        return _buildTransactionList();
      }),
    );
  }

  // Loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading transactions...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No transactions for ${widget.selectedMonth} ${widget.selectedYear}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => controller.fetchTransactions(refresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text(
                'Refresh',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Main transaction list
  Widget _buildTransactionList() {
    return RefreshIndicator(
      onRefresh: () async {
        await controller.fetchTransactions(refresh: true);
      },
      color: const Color(0xFF2196F3),
      backgroundColor: Colors.white,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Summary Sliver (Optional)
          _buildSummarySliver(),

          // Transactions Sliver
          _buildTransactionsSliver(),
        ],
      ),
    );
  }

  // Summary section
  SliverToBoxAdapter _buildSummarySliver() {
    return SliverToBoxAdapter(
      child: Obx(() {
        final stats = controller.getStatistics();
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.selectedMonth} ${widget.selectedYear}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${stats['totalTransactions']} transactions',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Income',
                      value: '₹${stats['totalIncome'].toStringAsFixed(2)}',
                      count: stats['incomeCount'],
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Expense',
                      value: '₹${stats['totalExpense'].toStringAsFixed(2)}',
                      count: stats['expenseCount'],
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  // Stat card widget
  Widget _buildStatCard({
    required String title,
    required String value,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count items',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // Transactions list sliver
  SliverList _buildTransactionsSliver() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final transaction = controller.transactions[index];
          final iconData = controller.getIconData(transaction);
          final bgColor = controller.getRandomColor();
          final displayAmount = controller.formatAmount(transaction);

          // Check if we need to show date header
          final bool showDateHeader = !controller.isSameDateAsPrevious(index);

          return Column(
            children: [
              // Date header
              if (showDateHeader)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.grey.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${transaction['date'] ?? ''} ${transaction['day'] ?? ''}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        '${transaction['type']}: ₹$displayAmount',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

              // Transaction item
              _buildTransactionItem(
                transaction: transaction,
                iconData: iconData,
                bgColor: bgColor,
                displayAmount: displayAmount,
                index: index,
              ),
            ],
          );
        },
        childCount: controller.transactions.length,
      ),
    );
  }

  // Transaction item widget
  Widget _buildTransactionItem({
    required dynamic transaction,
    required IconData iconData,
    required Color bgColor,
    required String displayAmount,
    required int index,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(transaction, iconData, displayAmount),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(iconData, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction['cat_name'] ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      transaction['type'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount
              Text(
                '₹$displayAmount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: transaction['type'] == 'Expense'
                      ? Colors.red.shade600
                      : Colors.green.shade600,
                ),
              ),

              // Arrow indicator
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Navigation to detail page
  void _navigateToDetail(dynamic transaction, IconData iconData, String displayAmount) {
    Get.to(
          () => TransactionDetailPage(
        categoryName: transaction['cat_name'] ?? '',
        iconData: iconData,
        type: transaction['type'],
        amount: displayAmount,
        date: transaction['date'] ?? '',
        id: transaction['id']?.toString() ?? '',
        income_id: transaction['income_id']?.toString() ?? '',
      ),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }
}