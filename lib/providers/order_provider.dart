import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../db/database_helper.dart';

class OrderProvider with ChangeNotifier {
  
  final DatabaseHelper _db = DatabaseHelper();

  List<Order>_orders = [];    // orders list from db
  List<Order> _filtered = []; // order list after filter using searchquery is applied
  String _searchQuery = '';   // what the user types in the search box
  String? _statusFilter;      // which status tab is active
  bool _isLoading = false;    // variable to show loading spinner while DB is in fetching 
  String? _error;             

  // public getters (exposed to widgets)
  List<Order> get orders => _filtered;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get statusFilter => _statusFilter;
  String get searchQuery => _searchQuery;

  // dashboard stats getting
  Map<String, dynamic> get stats {
    final total = _orders.fold<double>(
      0, (sum, o) => sum + o.totalPrice,
    );
    return {
      'totalOrders': _orders.length,
      'totalRevenue': total,
      'byStatus': {
        for (final status in OrderStatus.values)
          status.value: _orders.where((o) => o.status == status.value).length,
      },
    };
  }

  // load orders at startup (like useEffect)
  Future<void> loadOrders() async {
    _setLoading(true);
    try {
      _orders = await _db.getAllOrders();
      print('Loaded ${_orders.length} orders: $_orders');   // debug
      _applyFilters();      //pushes the order data into _filtered and call notifyListeners(): _applyFilters does both these
    } catch (e) {
      print('loadOrders errors: $e');   // debug 
      _error = e.toString();
      notifyListeners();    // like setState(), every widget that calls OrderProvider context with re-render
    } finally {
      _setLoading(false);
    }
  }

  // insert orders
  Future<void> addOrder(Order order) async {
    try {
      final id = await _db.insertOrder(order);
      print('Inserted order with id: $id'); // debug 
      // attaches the db generated if before adding to local state
      _orders.insert(0, order.copyWith(id: id));    // index 0 - front of the list
      _applyFilters();    
    } catch (e) {
      print('addOrders errors: $e');   // debug 
      _error = e.toString();
      notifyListeners();
    } 
  }

  // update status
  Future<void> updateStatus(int orderId) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;    // -1: no match 

    final current = _orders[index];   // the order to be updated
    final nextStatus = _nextStatus(current.status);
    if (nextStatus == null) return;
    
    final updated = current.copyWith(status: nextStatus);
    try {
     await _db.updateOrderStatus(orderId, nextStatus);
     _orders[index] = updated;
     _applyFilters();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // delete order
  Future<void> deleteOrder(int orderId) async {
    try {
      await _db.deleteOrder(orderId);
      _orders.removeWhere((o) => o.id == orderId);
      _applyFilters();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // searches - explain
  void searchOrders(String query) {
    _searchQuery = query.trim().toLowerCase();
    _applyFilters();
  }

  // filters by status
  void filterByStatus(String? status) {
    _statusFilter = status;
    _applyFilters();
  }

  // clears error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // private helper functions
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();              // notifies all widgets that call context.watch
  }

  void _applyFilters () {           
    _filtered = _orders.where((order) {
      final matchesSearch = _searchQuery.isEmpty || 
        order.customerName.toLowerCase().contains(_searchQuery) ||
        order.id.toString().contains(_searchQuery);

      final matchesStatus = _statusFilter == null ||
        order.status == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();

    notifyListeners();    // re-renders
  }

  String? _nextStatus(String current) {
    const flow = [
      OrderStatus.received,
      OrderStatus.washing,
      OrderStatus.ready,
      OrderStatus.delivered,
    ];
    final idx = flow.indexWhere((s) => s.value == current);
    if (idx == -1 || idx == flow.length -1 ) return null;
    return flow[idx + 1].value;
  }

}

enum OrderStatus {
  received('Received'),
  washing('Washing'),
  ready('Ready'),
  delivered('Delivered');

  const OrderStatus(this.value);
  final String value;     

  // human-friendly label with an emoji
  String get label {
    switch (this) {
      case OrderStatus.received: return 'Received';
      case OrderStatus.washing: return 'Washing';
      case OrderStatus.ready: return 'Ready';
      case OrderStatus.delivered: return 'Delivered';
    }
  }

  static OrderStatus fromValue(String value) =>
    OrderStatus.values.firstWhere((s) => s.value == value);
}