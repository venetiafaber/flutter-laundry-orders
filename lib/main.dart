import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/order_provider.dart';


void main() {
  runApp(const LaundryApp());
}

class LaundryApp extends StatelessWidget {
  const LaundryApp({super.key});

  // root widget of the application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(      // provider wrapper
      create: (_) => OrderProvider(), 
      child: MaterialApp(
        title: 'Laundry Order Management',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // theme of application
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
        home: const _ProviderBootstrapper(),
      ),
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

    context.read<OrderProvider>().loadOrders();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laundry Manager'),
        ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_laundry_service, size: 64, color: Colors.blueAccent),
            const SizedBox(height: 16),
            Text(
              'Provider ready',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Orders Loaded: ${provider.stats['count']}'),
            Text('Revenue: \$${(provider.stats['revenue'] as double).toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
  }
}
