import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';

class OrdersList extends StatefulWidget {
  const OrdersList({super.key});
  @override
  State<OrdersList> createState() => _OrdersListState();
}

class _OrdersListState extends State<OrdersList> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFCC0000),
        foregroundColor: Colors.white,
        title: const Text(
          'Laundry Orders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20 
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFCC0000),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),   
        label: const Text('New Order'),
        onPressed: () => Navigator.pushNamed(context, '/add-order'), 
      ),

      body: Column(
        children: [
          _DashboardBanner(stats: provider.stats),
          _SearchBar(
            controller: _searchController,
            onChanged: (query) {
              context.read<OrderProvider>().searchOrders(query);
            },
            onClear: () {
              _searchController.clear();
              context.read<OrderProvider>().searchOrders('');   // resets search
            },
          ),
          _FilterChipRow(
            selected: provider.statusFilter,
            onSelected: (status) => context.read<OrderProvider>().filterByStatus(status),
          ),
          Expanded(
            child: _buildBody(provider, context),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(OrderProvider provider, BuildContext context) {
    if(provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    if(provider.orders.isEmpty) {
      return const _EmptyState();
    }
    
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: provider.orders.length,
      itemBuilder: (context, index) {
        final order = provider.orders[index];
        return _OrderCard(
          order: order,
          onTap: () => context.read<OrderProvider>().updateStatus(order.id!),
        );
      },
    );
  }
}

class _DashboardBanner extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _DashboardBanner({
    required this.stats
  });

  @override
  Widget build(BuildContext context) {
    final totalOrders = stats['totalOrders'] ?? 0;
    final totalRevenue = (stats['totalRevenue'] ?? 0.0) as double;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFCC0000), Color(0xFF8B0000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          _StatTile(
            icon: Icons.receipt_long_rounded,
            label: 'Total Orders',
            value: totalOrders.toString(),
          ),
          const SizedBox(width: 24),
          _StatTile(
            icon: Icons.attach_money_rounded,
            label: 'Total Revenue',
            value: 'KWD ${totalRevenue.toStringAsFixed(3)}',
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon, 
            color: Colors.white, 
            size: 22
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label, 
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search by name or order ID',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey[400],
          ),
          suffixIcon: controller.text.isNotEmpty
            ? IconButton(onPressed: onClear, icon: const Icon(Icons.clear, size: 18,))
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _FilterChipRow extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _FilterChipRow({
    required this.selected,
    required this.onSelected
  });

  static const _filters = [
    {'label': 'All', 'value': null},
    {'label': 'Received', 'value': 'Received'},
    {'label': 'Washing', 'value': 'Washing'},
    {'label': 'Ready', 'value': 'Ready'},
    {'label': 'Delivered', 'value': 'Delivered'},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8), 
        itemBuilder: (context, i) {
          final filter = _filters[i];
          final label = filter['label'] as String;
          final value = filter['value'] as String?;
          final isSelected = selected == value;

          return FilterChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onSelected(value),
            selectedColor: const Color(0xFFCC0000),
            checkmarkColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? const Color(0xFFCC0000) : Colors.grey[300]!,
                ),
            ),
          );
        }
      ),     
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '#${order.id?.toString().padLeft(4,'0') ?? '----'}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(
                    status: order.status,
                    color: statusColor
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order.customerName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 4),

              // service type and phone
              Row(
                children: [
                  Icon(
                    Icons.local_laundry_service_rounded,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order.serviceType,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.phone_outlined,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order.phoneNumber,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'KWD ${order.totalPrice.toStringAsFixed(3)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A73E8),
                    ),
                  ),
                  if(order.status != 'Delivered')
                  Row(
                    children: [
                      Text(
                        'Tap to advance',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ],
              ),
          
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch(status) {
      case 'Received': return Colors.blue;
      case 'Washing': return Colors.orange;
      case 'Ready': return Colors.green;
      case 'Delivered': return Colors.grey;
      default: return Colors.grey;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusChip({
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFFCC0000).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_laundry_service_rounded,
              size: 56,
              color: Color(0xFFCC0000),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No orders yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first order',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500]
            ),
          )
        ],
      ),
    );
  }
}
