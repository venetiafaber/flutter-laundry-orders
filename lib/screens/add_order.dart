import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';

class AddOrder extends StatefulWidget {
  const AddOrder({super.key});

  @override
  State<AddOrder> createState() => _AddOrderState();
}

class _AddOrderState extends State<AddOrder> {
  final _formKey = GlobalKey<FormState>();    // like useRef on form element, to handle validate and save on the whole form

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _itemsController = TextEditingController();
  final _priceController = TextEditingController();

  // local state
  String? _selectedService;   // dropdown selection
  double _totalPrice = 0.0;
  bool _isSubmitting = false;

  // service options for select
  static const List<String> _serviceTypes = [
    'Wash & Fold',
    'Dry Clean',
    'Iron Only',
    'Wash & Iron',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _itemsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _recalculateTotal() {
    final items = double.tryParse(_itemsController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    setState(() {
      _totalPrice = items * price;
    });
  }

  // handles submit
  Future<void> _submit() async {
    if(!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final order = Order(
      customerName: _nameController.text.trim(), 
      phoneNumber: _phoneController.text.trim(), 
      serviceType: _selectedService!, 
      numberOfItems: int.parse(_itemsController.text.trim()), 
      pricePerItem: double.parse(_priceController.text.trim()), 
      status: OrderStatus.received.value,
    );


    try {
      await context.read<OrderProvider>().addOrder(order);
      if(mounted) {
        Navigator.pop(context);
      }

    } catch (e) {
      if(mounted) {   
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

    } finally {
      if(mounted) {
         setState(() => _isSubmitting = false );
      }
    }
  }

  // build
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Order'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // section header
              const _SectionHeader(
                title: 'Customer Details', 
                icon: Icons.person,
              ),
              const SizedBox(height: 12),

              // customer name
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration(
                  label: 'Customer Name',
                  hint: 'Your Name',
                  icon: Icons.badge_outlined,
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if(value == null || value.trim().isEmpty) {
                    return 'Customer name is required';
                  }
                  if(value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // phone number
              TextFormField(
                controller: _phoneController,
                decoration: _inputDecoration(
                  label: 'Phone Number',
                  hint: '91234567',
                  icon: Icons.phone_outlined,
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],    // prevents non-digit characters from being typed
                validator: (value) {
                  if(value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  if(value.trim().length < 8) {
                    return 'Enter a valid phone number (min 8 digits)'; 
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // section heder
              const _SectionHeader(
                title: 'Service Details',
                icon: Icons.local_laundry_service,
              ),
              const SizedBox(height: 12),

              // service type dropdown 
              DropdownButtonFormField(
                value: _selectedService,
                decoration: _inputDecoration(
                  label: 'Service Type',
                  hint: 'Select a service',
                  icon: Icons.dry_cleaning_outlined,
                ),
                // dropdown menu items
                items: _serviceTypes.map((service) {
                  return DropdownMenuItem(
                    value: service,
                    child: Text(service), 
                  );
                }).toList(), 
                onChanged: (value) {
                  setState(() => _selectedService = value);
                },
                validator: (value) {
                  if (value == null) return 'Please select a service type';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // number of items + price per item
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _itemsController,
                      decoration: _inputDecoration(
                        label: 'No. of Items',
                        hint: 'e.g.: 5',
                        icon: Icons.format_list_numbered,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => _recalculateTotal(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final n = int.tryParse(value.trim());
                        if (n == null || n <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: _inputDecoration(
                        label: 'Price / Item (KD)',
                        hint: 'eg: 1500',
                        icon: Icons.attach_money,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        // allows digits and one decimal point only
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      onChanged: (_) => _recalculateTotal(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final n = double.tryParse(value.trim());
                        if (n == null || n <= 0 ) return 'Must be > 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // total price
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  )
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Total Price',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        )
                      ],
                    ),
                    Text(
                      'KD ${_totalPrice.toStringAsFixed(3)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // submit button
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Icon(Icons.add_task),
                label: Text(
                  _isSubmitting ? 'Saving...' : 'Place Order',
                  style: const TextStyle(fontSize: 16),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  )
                ),
              ),
              const SizedBox(height: 16),

              // cancel button
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  )
                ),
                child: const Text('Cancel', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // helper InputDecoration
  InputDecoration _inputDecoration({
    required String label, 
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({ 
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon, 
          size: 18, 
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
        ),
      ],
    );
  }
}