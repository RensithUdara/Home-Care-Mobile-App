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
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
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
    _contactNumberController =
        TextEditingController(text: widget.product.contactNumber.toString());
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
      setState(() {
        _errorMessage = '';
      });
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.orange.shade50,
            Colors.white,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Compact Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Drag Handle
                Container(
                  width: 32,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Compact Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Edit Product',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Selection
                  _buildUltraCompactSection('Category', _buildCategoryDropdown()),
                  
                  const SizedBox(height: 12),
                  
                  // Product Information
                  _buildUltraCompactSection('Product Details', Column(
                    children: [
                      _buildCompactTextField(
                        controller: _nameController,
                        label: 'Product Name',
                        icon: Icons.inventory_2_rounded,
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
                        label: 'Service Contact',
                        icon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  )),
                  
                  const SizedBox(height: 12),
                  
                  // Dates
                  _buildUltraCompactSection('Dates', Column(
                    children: [
                      _buildCompactDateField(
                        label: 'Purchase Date',
                        icon: Icons.shopping_bag_rounded,
                        selectedDate: _selectedPurchaseDate,
                        onTap: () => _selectDate(context, true),
                      ),
                      const SizedBox(height: 8),
                      _buildCompactDateField(
                        label: 'Warranty End Date',
                        icon: Icons.verified_user_rounded,
                        selectedDate: _selectedWarrantyPeriod,
                        onTap: () => _selectDate(context, false),
                      ),
                    ],
                  )),
                  
                  const SizedBox(height: 12),
                  
                  // Error Display
                  if (_errorMessage.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_rounded, color: Colors.red.shade600, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Update Button
                  _buildActionButton(),
                  
                  // Bottom spacing
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUltraCompactSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.orange.shade700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildCompactSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: (_) => _clearError(),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.orange.shade600, size: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: Colors.orange.shade600, size: 20),
              const SizedBox(width: 12),
              Text(
                selectedDate == null ? label : DateFormat('MMM dd, yyyy').format(selectedDate),
                style: TextStyle(
                  fontSize: 14,
                  color: selectedDate == null ? Colors.grey.shade600 : Colors.grey.shade800,
                  fontWeight: selectedDate == null ? FontWeight.normal : FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(Icons.calendar_today, color: Colors.orange.shade600, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Category>(
          isExpanded: true,
          hint: Row(
            children: [
              Icon(Icons.category_rounded, color: Colors.orange.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Select category',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
          value: _selectedCategory,
          onChanged: (Category? newValue) {
            setState(() => _selectedCategory = newValue);
            _clearError();
          },
          items: Category.values.map((Category category) {
            return DropdownMenuItem<Category>(
              value: category,
              child: Row(
                children: [
                  Icon(_getCategoryIcon(category), color: Colors.orange.shade600, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _getCategoryName(category),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.orange.shade600,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isLoading ? null : _updateProduct,
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 6),
                      Text(
                        'Update Product',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(Category category) {
    switch (category) {
      case Category.AirConditioner:
        return Icons.ac_unit_rounded;
      case Category.Refrigerator:
        return Icons.kitchen_rounded;
      case Category.WashingMachine:
        return Icons.local_laundry_service_rounded;
      case Category.Television:
        return Icons.tv_rounded;
      case Category.Fan:
        return Icons.toys_rounded;
      case Category.Laptop:
        return Icons.laptop_rounded;
      case Category.Speaker:
        return Icons.speaker_rounded;
      case Category.VacuumCleaner:
        return Icons.cleaning_services_rounded;
      case Category.Other:
        return Icons.more_horiz_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  String _getCategoryName(Category category) {
    switch (category) {
      case Category.AirConditioner:
        return 'Air Conditioner';
      case Category.Refrigerator:
        return 'Refrigerator';
      case Category.WashingMachine:
        return 'Washing Machine';
      case Category.Television:
        return 'Television';
      case Category.Fan:
        return 'Fan';
      case Category.Laptop:
        return 'Laptop';
      case Category.Speaker:
        return 'Speaker';
      case Category.VacuumCleaner:
        return 'Vacuum Cleaner';
      case Category.Other:
        return 'Other';
      default:
        return category.toString().split('.').last;
    }
  }

  Future<void> _selectDate(BuildContext context, bool isPurchaseDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isPurchaseDate ? _selectedPurchaseDate : _selectedWarrantyPeriod) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.grey.shade800,
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
    _clearError();

    // Validate fields
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter a product name');
      return;
    }
    
    if (_locationController.text.trim().isEmpty) {
      _showError('Please enter a location');
      return;
    }
    
    if (_contactNumberController.text.trim().isEmpty) {
      _showError('Please enter a contact number');
      return;
    }
    
    if (_selectedCategory == null) {
      _showError('Please select a category');
      return;
    }
    
    if (_selectedPurchaseDate == null) {
      _showError('Please select a purchase date');
      return;
    }
    
    if (_selectedWarrantyPeriod == null) {
      _showError('Please select a warranty end date');
      return;
    }

    // Validate contact number
    final contactNumber = int.tryParse(_contactNumberController.text.trim());
    if (contactNumber == null) {
      _showError('Please enter a valid contact number');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create updated product object
      Products updatedProduct = Products(
        id: widget.product.id,
        uid: widget.product.uid,
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        purchasedDate: _selectedPurchaseDate!,
        warrantyPeriod: _selectedWarrantyPeriod!,
        contactNumber: contactNumber,
        type: _selectedCategory!,
      );

      // Call the FirestoreService to update the product
      await FirestoreService.editProduct(updatedProduct);
      
      // Close the bottom sheet
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        widget.onProductEdited();
      }
    } catch (e) {
      _showError('Failed to update product: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
