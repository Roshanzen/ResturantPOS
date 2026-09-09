import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/table.dart';
import '../providers/pos_provider.dart';
import '../theme/pos_theme.dart';
import '../widgets/common.dart';

class NewTableScreen extends StatefulWidget {
  final RestaurantTable? table;

  const NewTableScreen({super.key, this.table});

  @override
  State<NewTableScreen> createState() => _NewTableScreenState();
}

class _NewTableScreenState extends State<NewTableScreen> {
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController(text: '4');
  String _location = 'Indoor';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.table != null) {
      _nameController.text = widget.table!.name;
      _capacityController.text = widget.table!.capacity.toString();
      _location = widget.table!.location;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.table != null;
    return Scaffold(
      backgroundColor: PosTheme.backgroundColor,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit table' : 'Add table'),
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
                  labelText: 'Table name / number',
                  hintText: 'e.g. Table 11',
                ),
              ),
              const SizedBox(height: PosTheme.spacingMedium),
              TextField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                style:
                    const TextStyle(color: PosTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Seating capacity',
                  hintText: 'e.g. 4',
                ),
              ),
              const SizedBox(height: PosTheme.spacingMedium),
              DropdownButtonFormField<String>(
                initialValue: _location,
                dropdownColor: PosTheme.surfaceColor,
                style:
                    const TextStyle(color: PosTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: PosTheme.inputBackground,
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(PosTheme.borderRadiusSmall),
                      borderSide: BorderSide.none),
                  labelText: 'Location / Section',
                ),
                items: const [
                  DropdownMenuItem(value: 'Indoor', child: Text('Indoor')),
                  DropdownMenuItem(value: 'Outdoor', child: Text('Outdoor')),
                  DropdownMenuItem(value: 'Patio', child: Text('Patio')),
                  DropdownMenuItem(value: 'Bar', child: Text('Bar')),
                  DropdownMenuItem(value: 'Window', child: Text('Window')),
                  DropdownMenuItem(value: 'Booth', child: Text('Booth')),
                ],
                onChanged: (v) => setState(() => _location = v ?? _location),
              ),
              const SizedBox(height: PosTheme.spacingLarge),
              SizedBox(
                width: double.infinity,
                child: PosButton(
                  label: _isLoading
                      ? (isEditing ? 'Saving...' : 'Saving...')
                      : (isEditing ? 'Save changes' : 'Add table'),
                  onPressed: _isLoading
                      ? null
                      : () {
                          final name = _nameController.text.trim();
                          final capacity =
                              int.tryParse(_capacityController.text);
                          if (name.isEmpty ||
                              capacity == null ||
                              capacity <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Please enter a valid table name and capacity.'),
                                backgroundColor: PosTheme.errorColor,
                              ),
                            );
                            return;
                          }

                          if (isEditing) {
                            context
                                .read<POSProvider>()
                                .updateTable(
                                  widget.table!.id,
                                  name: name,
                                  location: _location,
                                  capacity: capacity,
                                );
                            Navigator.pop(context, true);
                          } else {
                            final table = RestaurantTable(
                              id:
                                  'table_${DateTime.now().millisecondsSinceEpoch}',
                              name: name,
                              location: _location,
                              capacity: capacity,
                              status: 'free',
                              orderCount: 0,
                              runningTotal: 0.0,
                            );

                            context.read<POSProvider>().addTable(table);
                            Navigator.pop(context, true);
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }
}
