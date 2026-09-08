import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../providers/pos_provider.dart';
import '../theme/pos_theme.dart';
import '../widgets/common.dart';

class NewCustomerScreen extends StatefulWidget {
  const NewCustomerScreen({super.key});

  @override
  State<NewCustomerScreen> createState() => _NewCustomerScreenState();
}

class _NewCustomerScreenState extends State<NewCustomerScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PosTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('New customer'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PosTheme.spacingMedium),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                style:
                    const TextStyle(color: PosTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                    labelText: 'Name', hintText: 'Enter full name'),
              ),
              const SizedBox(height: PosTheme.spacingMedium),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style:
                    const TextStyle(color: PosTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                    labelText: 'Phone', hintText: 'e.g. 9801234567'),
              ),
              const SizedBox(height: PosTheme.spacingMedium),
              TextField(
                controller: _addressController,
                style:
                    const TextStyle(color: PosTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                    labelText: 'Address', hintText: 'City / Area'),
              ),
              const SizedBox(height: PosTheme.spacingLarge),
              SizedBox(
                width: double.infinity,
                child: PosButton(
                  label: _isLoading ? 'Saving...' : 'Save customer',
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_nameController.text.isEmpty ||
                              _phoneController.text.isEmpty ||
                              _addressController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please fill all fields'),
                                  backgroundColor: PosTheme.errorColor),
                            );
                            return;
                          }
                          final name = _nameController.text.trim();
                          final initials = name
                              .split(' ')
                              .map((w) => w.isNotEmpty ? w[0] : '')
                              .take(2)
                              .join()
                              .toUpperCase();
                          final customer = Customer(
                            id: 'CUST-${DateTime.now().millisecondsSinceEpoch % 10000}',
                            name: name,
                            phone: _phoneController.text.trim(),
                            address: _addressController.text.trim(),
                            initials: initials,
                          );
                          context.read<POSProvider>().addCustomer(customer);
                          Navigator.pop(context, true);
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
