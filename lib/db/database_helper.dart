import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/order.dart';

//singleton pattern - ensures only one db connection exists app-wide

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if(_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();     // finds the correct local storage path on the device

    final path = join(dbPath, 'laundry_orders.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,  // runns only on first install
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE orders (
        ID            INTEGER PRIMARY KEY AUTOINCREMENT,
        customerName  TEXT    NOT NULL,
        phoneNumber   TEXT    NOT NULL,
        serviceType   TEXT    NOT NULL,
        numberOfItems INTEGER NOT NULL,
        pricePerItem  REAL    NOT NULL,
        totalPrice    REAL    NOT NULL,
        status        TEXT    NOT NULL DEFAULT 'Received'     
      )
    '''
    );
  }

  // CRUD operations 

  // creates order
  Future<int> insertOrder(Order order) async {
    final db = await database;
    return await db.insert(
      'orders',       // table name
      order.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // returns all orders
  Future<List<Order>> getAllOrders() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      orderBy: 'id DESC', 
    );

    return List.generate(maps.length, (i) => Order.fromMap(maps[i]));
  }

  // updates order status
  Future<int> updateOrderStatus(int id, String newStatus) async {
    final db = await database;
    return await db.update(
      'orders', 
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [id],
    );

  }

  // returns an order(s) / search an order(s)
  Future<List<Order>> searchOrder(String query) async {
    final db = await database;

    final String likeQuery = '%$query%';

    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'customerName LIKE ? OR phoneNumber LIKE ?',
      whereArgs: [likeQuery, likeQuery],
      orderBy: 'id DESC',
    );

    return List.generate(maps.length, (i) => Order.fromMap(maps[i]));
  }

  // deletes an order
  Future<int> deleteOrder(int id) async {
    final db = await database;

    return await db.delete(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

}