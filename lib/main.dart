import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/order_provider.dart';
import 'screens/orders_list.dart';
import 'screens/add_order.dart';


void main() {
  runApp(
    // wrapping in a provider like react context
    ChangeNotifierProvider(
      create: (_) => OrderProvider(),
      child: const LaundryApp(),
    ),
  );
  
}

class LaundryApp extends StatelessWidget {
  const LaundryApp({super.key});

  // root widget of the application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Laundry Order Management',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // theme of application
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFCC0000),
            primary: const Color(0xFFCC0000),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
        
        // routes
        initialRoute: '/',
        routes: {
          '/': (context) => const _ProviderBootstrapper(),
          '/add-order': (context) => const AddOrder(),
          //'/dashboard': (context) => Dashboard(),
        },
      );
  }
}

// loads orders from DB at load (useEffect)
class _ProviderBootstrapper extends StatefulWidget {
  const _ProviderBootstrapper();

  @override 
  State<_ProviderBootstrapper> createState() => _ProviderBootstrapperState();

}

class _ProviderBootstrapperState extends State<_ProviderBootstrapper> {
@override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {    //explain compared to react
      context.read<OrderProvider>().loadOrders();
    });
  }

@override
Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();

    if(provider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // placeholder for OrdersListScreen
    return const OrdersList();
  }
}
