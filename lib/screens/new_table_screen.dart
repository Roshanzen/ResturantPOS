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
  String _status = 'free';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.table != null) {
      _nameController.text = widget.table!.name;
      _capacityController.text = widget.table!.capacity.toString();
      _location = widget.table!.location;
      _status = widget.table!.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.table != null;
    return Scaffold(
      backgroundColor: PosTheme.backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit table' : 'Add table'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(
            horizontal: PosTheme.spacingMedium,
            vertical: PosTheme.spacingMedium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                style:
                    const TextStyle(color: PosTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Table name *',
                  hintText: 'e.g. Table 11',
                  filled: true,
                  fillColor: PosTheme.inputBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(PosTheme.borderRadiusSmall),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: PosTheme.spacingMedium),
              TextField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                style:
                    const TextStyle(color: PosTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Capacity *',
                  hintText: 'e.g. 4',
                  filled: true,
                  fillColor: PosTheme.inputBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(PosTheme.borderRadiusSmall),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: PosTheme.spacingMedium),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _location,
                dropdownColor: PosTheme.surfaceColor,
                icon: const Icon(Icons.arrow_drop_down_rounded,
                    color: PosTheme.textSecondary),
                style:
                    const TextStyle(color: PosTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Location',
                  filled: true,
                  fillColor: PosTheme.inputBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(PosTheme.borderRadiusSmall),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Indoor', child: Text('Indoor')),
                  DropdownMenuItem(value: 'Outdoor', child: Text('Outdoor')),
                  DropdownMenuItem(value: 'Patio', child: Text('Patio')),
                  DropdownMenuItem(value: 'Bar', child: Text('Bar')),
                  DropdownMenuItem(value: 'Window', child: Text('Window')),
                  DropdownMenuItem(value: 'Booth', child: Text('Booth')),
                  DropdownMenuItem(value: 'Rooftop', child: Text('Rooftop')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _location = v);
                  }
                },
              ),
              const SizedBox(height: PosTheme.spacingMedium),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: (_status == 'active' || _status == 'reserved' || _status == 'free')
                    ? _status
                    : 'free',
                dropdownColor: PosTheme.surfaceColor,
                icon: const Icon(Icons.arrow_drop_down_rounded,
                    color: PosTheme.textSecondary),
                style:
                    const TextStyle(color: PosTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Status',
                  filled: true,
                  fillColor: PosTheme.inputBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(PosTheme.borderRadiusSmall),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'free', child: Text('Available')),
                  DropdownMenuItem(value: 'active', child: Text('Occupied')),
                  DropdownMenuItem(value: 'reserved', child: Text('Reserved')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _status = v);
                  }
                },
              ),
              const SizedBox(height: PosTheme.spacingLarge),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: PosButton(
                  label: _isLoading
                      ? 'Saving...'
                      : (isEditing ? 'Save changes' : 'Save table'),
                  onPressed: _isLoading ? null : _saveTable,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveTable() async {
    final name = _nameController.text.trim();
    final capacity = int.tryParse(_capacityController.text.trim());

    if (name.isEmpty) {
      _showError('Please enter a table name.');
      return;
    }

    if (capacity == null || capacity <= 0) {
      _showError('Please enter a valid seating capacity (at least 1).');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isEditing = widget.table != null;
      if (isEditing) {
        await context.read<POSProvider>().updateTable(
              widget.table!.id,
              name: name,
              location: _location,
              capacity: capacity,
              status: _status,
            );
      } else {
        final table = RestaurantTable(
          id: 'table_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          location: _location,
          capacity: capacity,
          status: _status,
          orderCount: 0,
          runningTotal: 0.0,
        );
        await context.read<POSProvider>().addTable(table);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to save table: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: PosTheme.errorColor,
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
