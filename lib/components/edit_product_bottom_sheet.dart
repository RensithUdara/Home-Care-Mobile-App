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
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Modern Header with glassmorphism effect
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFF6B6B).withOpacity(0.1),
                  const Color(0xFFFF8E53).withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                children: [
                  // Elegant Drag Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF6B6B),
                          const Color(0xFFFF8E53),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Beautiful Header with Icon and Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFFF6B6B),
                              const Color(0xFFFF8E53),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B6B).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Edit Product',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            Text(
                              'Update your appliance information',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Modern Scrollable Content with Cards
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Selection Card
                  _buildModernCard(
                    title: 'Product Category',
                    icon: Icons.category_rounded,
                    child: _buildModernCategoryDropdown(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Product Information Card
                  _buildModernCard(
                    title: 'Product Information',
                    icon: Icons.info_rounded,
                    child: Column(
                      children: [
                        _buildModernTextField(
                          controller: _nameController,
                          label: 'Product Name',
                          hint: 'e.g., Samsung Smart TV',
                          icon: Icons.inventory_2_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildModernTextField(
                          controller: _locationController,
                          label: 'Location',
                          hint: 'e.g., Living Room',
                          icon: Icons.location_on_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildModernTextField(
                          controller: _contactNumberController,
                          label: 'Service Contact',
                          hint: 'Customer service number',
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Dates Card
                  _buildModernCard(
                    title: 'Important Dates',
                    icon: Icons.schedule_rounded,
                    child: Column(
                      children: [
                        _buildModernDateField(
                          label: 'Purchase Date',
                          hint: 'When did you buy this?',
                          icon: Icons.shopping_cart_rounded,
                          selectedDate: _selectedPurchaseDate,
                          onTap: () => _selectDate(context, true),
                        ),
                        const SizedBox(height: 16),
                        _buildModernDateField(
                          label: 'Warranty End Date',
                          hint: 'When does warranty expire?',
                          icon: Icons.verified_user_rounded,
                          selectedDate: _selectedWarrantyPeriod,
                          onTap: () => _selectDate(context, false),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Error Display with improved design
                  if (_errorMessage.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.error_outline_rounded,
                              color: Colors.red.shade600,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Modern Action Button
                  _buildModernActionButton(),
                  
                  // Bottom safe area
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFFFF6B6B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: (_) => _clearError(),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A1A),
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFF6B6B),
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildModernDateField({
    required String label,
    required String hint,
    required IconData icon,
    required DateTime? selectedDate,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFFF6B6B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedDate == null 
                          ? hint
                          : DateFormat('EEEE, MMM dd, yyyy').format(selectedDate),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: selectedDate == null 
                            ? Colors.grey.shade400
                            : const Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.calendar_today_rounded,
                color: const Color(0xFFFF6B6B),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernCategoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Category>(
          isExpanded: true,
          hint: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.category_rounded,
                  color: const Color(0xFFFF6B6B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product Category',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Select the appliance type',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          value: _selectedCategory,
          onChanged: (Category? newValue) {
            setState(() => _selectedCategory = newValue);
            _clearError();
          },
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
          items: Category.values.map((Category category) {
            return DropdownMenuItem<Category>(
              value: category,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: const Color(0xFFFF6B6B),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getCategoryName(category),
                    style: const TextStyle(
                      fontSize: 15,
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

  Widget _buildModernActionButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF6B6B),
            const Color(0xFFFF8E53),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B6B).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isLoading ? null : _updateProduct,
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.save_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Update Product',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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
              primary: const Color(0xFFFF6B6B),
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
