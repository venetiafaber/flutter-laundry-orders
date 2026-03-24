class Order {
  final int? id;
  final String customerName;
  final String phoneNumber;
  final String serviceType;
  final int numberOfItems;
  final double pricePerItem;
  final double totalPrice;    // autocalculated: numberOfItems * pricePerItem
  final String status;

  // constructor
  Order({
    this.id,
    required this.customerName,
    required this.phoneNumber,
    required this.serviceType,
    required this.numberOfItems,
    required this.pricePerItem,
    double? totalPrice,
    this.status = 'Received',   // default value
  })
  : totalPrice = totalPrice ?? (numberOfItems * pricePerItem);

  // toMap() to raw data / SQLite does not understand Dart ojects, 
  // convert to map, id excluded as SQLite auto-generates it
  Map<String, dynamic> toMap() {
    return {
      'customerName': customerName,
      'phoneNumber': phoneNumber,
      'serviceType' : serviceType,
      'numberOfItems': numberOfItems,
      'pricePerItem': pricePerItem,
      'totalPrice': totalPrice,
      'status': status,
    };
  }

  // fromMap to object
  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as int?,
      customerName: map['customerName'] as String,
      phoneNumber: map['phoneNumber'] as String,
      serviceType: map['serviceType'] as String,
      numberOfItems: map['numberOfItems'] as int,
      pricePerItem: (map['pricePerItem'] as num).toDouble(),
      totalPrice: (map['totalPrice'] as num).toDouble(),
      status: map['status'] as String,
    );
  }

  Order copyWith({
    int? id,
    String? customerName,
    String? phoneNumber,
    String? serviceType,
    int? numberOfItems,
    double? pricePerItem,
    double? totalPrice,
    String? status,
  }) {
    return Order(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      serviceType: serviceType ?? this.serviceType,
      numberOfItems: numberOfItems ?? this.numberOfItems,
      pricePerItem: pricePerItem ?? this.pricePerItem,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
    );
  }
}