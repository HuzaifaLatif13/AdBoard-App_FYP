import 'package:flutter/material.dart';
import 'package:adboard/modals/filter_model.dart';
import 'package:intl/intl.dart';

class FilterDialog extends StatefulWidget {
  final FilterModel currentFilters;
  final List<String> categories;
  final List<String> sizes;

  const FilterDialog({
    Key? key,
    required this.currentFilters,
    required this.categories,
    required this.sizes,
  }) : super(key: key);

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late FilterModel _filters;
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  DateTime? _postedAfter;
  DateTime? _postedBefore;

  // List of major Pakistani cities
  final List<String> pakistaniCities = [
    'Karachi',
    'Lahore',
    'Islamabad',
    'Rawalpindi',
    'Faisalabad',
    'Multan',
    'Peshawar',
    'Quetta',
    'Sialkot',
    'Gujranwala',
    'Hyderabad',
    'Abbottabad',
    'Sargodha',
    'Bahawalpur',
    'Sukkur'
  ];

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters;
    _minPriceController.text = _filters.minPrice?.toString() ?? '';
    _maxPriceController.text = _filters.maxPrice?.toString() ?? '';
    _postedAfter = _filters.postedAfter;
    _postedBefore = _filters.postedBefore;
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isAfter) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isAfter
          ? _postedAfter ?? DateTime.now()
          : _postedBefore ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isAfter) {
          _postedAfter = picked;
        } else {
          _postedBefore = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filters = _filters.clear();
                      _minPriceController.clear();
                      _maxPriceController.clear();
                      _postedAfter = null;
                      _postedBefore = null;
                    });
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Location Filter
            DropdownButtonFormField<String>(
              value: _filters.location,
              decoration: const InputDecoration(
                labelText: 'City',
                prefixIcon: Icon(Icons.location_city),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Cities'),
                ),
                ...pakistaniCities.map((city) {
                  return DropdownMenuItem(
                    value: city,
                    child: Text(city),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _filters = _filters.copyWith(location: value);
                });
              },
            ),
            const SizedBox(height: 16),

            // Price Range Filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Min Price',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _maxPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max Price',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category Filter
            DropdownButtonFormField<String>(
              value: _filters.category,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Categories'),
                ),
                ...widget.categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _filters = _filters.copyWith(category: value);
                });
              },
            ),
            const SizedBox(height: 16),

            // Size Filter
            DropdownButtonFormField<String>(
              value: _filters.size,
              decoration: const InputDecoration(
                labelText: 'Size',
                prefixIcon: Icon(Icons.aspect_ratio),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Sizes'),
                ),
                ...widget.sizes.map((size) {
                  return DropdownMenuItem(
                    value: size,
                    child: Text(size),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _filters = _filters.copyWith(size: value);
                });
              },
            ),
            const SizedBox(height: 16),

            // Availability Filter
            SwitchListTile(
              title: const Text('Available Only'),
              value: _filters.isAvailable ?? false,
              onChanged: (value) {
                setState(() {
                  _filters = _filters.copyWith(isAvailable: value);
                });
              },
            ),
            const SizedBox(height: 16),

            // Date Range Filter
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, true),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _postedAfter != null
                          ? DateFormat('MMM d, y').format(_postedAfter!)
                          : 'Posted After',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, false),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _postedBefore != null
                          ? DateFormat('MMM d, y').format(_postedBefore!)
                          : 'Posted Before',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Apply Button
            ElevatedButton(
              onPressed: () {
                final updatedFilters = _filters.copyWith(
                  minPrice: _minPriceController.text.isEmpty
                      ? null
                      : double.tryParse(_minPriceController.text),
                  maxPrice: _maxPriceController.text.isEmpty
                      ? null
                      : double.tryParse(_maxPriceController.text),
                  postedAfter: _postedAfter,
                  postedBefore: _postedBefore,
                );
                Navigator.of(context).pop(updatedFilters);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Apply Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
