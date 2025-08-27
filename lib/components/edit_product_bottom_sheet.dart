import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:home_care/models/products.dart';
import 'package:home_care/services/firestore/firestore_services.dart';

class EditProductBottomSheet extends StatefulWidget {
  final Products product;
  final Function onProductEdited;

  const EditProductBottomSheet({
    super.key,
    required this.product,
    required this.onProductEdited,
  });

  @override
  State<EditProductBottomSheet> createState() => _EditProductBottomSheetState();

  static void show(
    BuildContext context, {
    required Products product,
    required Function onProductEdited,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.35,
        minChildSize: 0.25,
        maxChildSize: 0.4,
        builder: (context, scrollController) => EditProductBottomSheet(
          product: product,
          onProductEdited: onProductEdited,
        ),
      ),
    );
  }
}

class _EditProductBottomSheetState extends State<EditProductBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _contactNumberController;

  DateTime? _selectedPurchaseDate;
  DateTime? _selectedWarrantyPeriod;
  Category? _selectedCategory;
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _locationController = TextEditingController(text: widget.product.location);
    _contactNumberController = TextEditingController(text: widget.product.contactNumber.toString());
    _selectedPurchaseDate = widget.product.purchasedDate;
    _selectedWarrantyPeriod = widget.product.warrantyPeriod;
    _selectedCategory = widget.product.type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage.isNotEmpty) {
      setState(() => _errorMessage = '');
    }
  }

  Future<void> _selectDate(BuildContext context, bool isPurchaseDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF6B6B),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isPurchaseDate) {
          _selectedPurchaseDate = picked;
        } else {
          _selectedWarrantyPeriod = picked;
        }
      });
      _clearError();
    }
  }

  Future<void> _updateProduct() async {
    if (_nameController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _contactNumberController.text.isEmpty ||
        _selectedCategory == null ||
        _selectedPurchaseDate == null ||
        _selectedWarrantyPeriod == null) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    // Validate contact number
    int? contactNumber = int.tryParse(_contactNumberController.text.trim());
    if (contactNumber == null) {
      setState(() => _errorMessage = 'Please enter a valid contact number');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedProduct = Products(
        id: widget.product.id,
        uid: widget.product.uid,
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        contactNumber: contactNumber,
        type: _selectedCategory!,
        purchasedDate: _selectedPurchaseDate!,
        warrantyPeriod: _selectedWarrantyPeriod!,
      );

      await FirestoreService.editProduct(updatedProduct);
      
      widget.onProductEdited();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Product updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update product: $e';
        _isLoading = false;
      });
    }
  }

  IconData _getCategoryIcon(Category category) {
    switch (category) {
      case Category.Laptop:
        return Icons.laptop_mac_rounded;
      case Category.Television:
        return Icons.tv_rounded;
      case Category.Fan:
        return Icons.toys_rounded;
      case Category.Refrigerator:
        return Icons.kitchen_rounded;
      case Category.WashingMachine:
        return Icons.local_laundry_service_rounded;
      case Category.AirConditioner:
        return Icons.ac_unit_rounded;
      case Category.Speaker:
        return Icons.speaker_rounded;
      case Category.VacuumCleaner:
        return Icons.cleaning_services_rounded;
      case Category.Other:
        return Icons.category_rounded;
    }
  }

  String _getCategoryName(Category category) {
    switch (category) {
      case Category.Laptop:
        return 'Laptop';
      case Category.Television:
        return 'Television';
      case Category.Fan:
        return 'Fan';
      case Category.Refrigerator:
        return 'Refrigerator';
      case Category.WashingMachine:
        return 'Washing Machine';
      case Category.AirConditioner:
        return 'Air Conditioner';
      case Category.Speaker:
        return 'Speaker';
      case Category.VacuumCleaner:
        return 'Vacuum Cleaner';
      case Category.Other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFF6B6B),
            Color(0xFFFF8E53),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Edit Product',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_errorMessage.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: Colors.red.shade600,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    _buildUltraCompactCard(
                      child: Column(
                        children: [
                          _buildCompactTextField(
                            controller: _nameController,
                            label: 'Product Name',
                            icon: Icons.shopping_bag_rounded,
                          ),
                          const SizedBox(height: 8),
                          _buildCompactTextField(
                            controller: _locationController,
                            label: 'Location',
                            icon: Icons.location_on_rounded,
                          ),
                          const SizedBox(height: 8),
                          _buildCompactTextField(
                            controller: _contactNumberController,
                            label: 'Contact Number',
                            icon: Icons.phone_rounded,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 8),
                          _buildInlineCategoryDropdown(),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCompactDateField(
                                  label: 'Purchase Date',
                                  icon: Icons.calendar_today_rounded,
                                  selectedDate: _selectedPurchaseDate,
                                  onTap: () => _selectDate(context, true),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildCompactDateField(
                                  label: 'Warranty End',
                                  icon: Icons.shield_rounded,
                                  selectedDate: _selectedWarrantyPeriod,
                                  onTap: () => _selectDate(context, false),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildCompactActionButton(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUltraCompactCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: (_) => _clearError(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A1A),
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFFFF6B6B), size: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactDateField({
    required String label,
    required IconData icon,
    required DateTime? selectedDate,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFFF6B6B), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selectedDate == null 
                      ? label
                      : DateFormat('MMM dd, yyyy').format(selectedDate),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selectedDate == null 
                        ? Colors.grey.shade600
                        : const Color(0xFF1A1A1A),
                  ),
                ),
              ),
              Icon(
                Icons.calendar_today_rounded,
                color: const Color(0xFFFF6B6B),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInlineCategoryDropdown() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Category>(
          isExpanded: true,
          hint: Row(
            children: [
              Icon(
                Icons.category_rounded,
                color: const Color(0xFFFF6B6B),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Select Category',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          value: _selectedCategory,
          onChanged: (Category? newValue) {
            setState(() => _selectedCategory = newValue);
            _clearError();
          },
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
          items: Category.values.map((Category category) {
            return DropdownMenuItem<Category>(
              value: category,
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    color: const Color(0xFFFF6B6B),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getCategoryName(category),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCompactActionButton() {
    return Container(
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF6B6B),
            const Color(0xFFFF8E53),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B6B).withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _isLoading ? null : _updateProduct,
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Update Product',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
