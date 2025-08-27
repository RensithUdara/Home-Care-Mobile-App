import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:home_care/models/products.dart';
import 'package:home_care/services/firestore/firestore_services.dart';

class AddProductBottomSheet extends StatefulWidget {
  final Function onProductAdded;
  final String uid;

  const AddProductBottomSheet({
    super.key, 
    required this.onProductAdded, 
    required this.uid
  });

  @override
  AddProductBottomSheetState createState() => AddProductBottomSheetState();

  static void show(BuildContext context, {required Function onProductAdded, required String uid}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => AddProductBottomSheet(
          onProductAdded: onProductAdded,
          uid: uid,
        ),
      ),
    );
  }
}

class AddProductBottomSheetState extends State<AddProductBottomSheet> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactNumberController = TextEditingController();

  DateTime? _selectedPurchaseDate;
  DateTime? _selectedWarrantyPeriod;
  Category? _selectedCategory;
  String _errorMessage = '';
  bool _isLoading = false;

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
        color: Theme.of(context).colorScheme.surface,
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
          // Drag Handle and Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              children: [
                // Drag Handle
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade600, Colors.blue.shade700],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade200,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_box_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Product',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Add your appliance details',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Selection
                  _buildSection(
                    title: 'Category',
                    icon: Icons.category_rounded,
                    child: _buildCategoryDropdown(),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Product Information
                  _buildSection(
                    title: 'Product Information',
                    icon: Icons.info_rounded,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: 'Product Name',
                          icon: Icons.inventory_2_rounded,
                          hint: 'Enter product name',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _locationController,
                          label: 'Location',
                          icon: Icons.location_on_rounded,
                          hint: 'Where is it located?',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _contactNumberController,
                          label: 'Service Contact',
                          icon: Icons.phone_rounded,
                          hint: 'Service center number',
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Dates
                  _buildSection(
                    title: 'Important Dates',
                    icon: Icons.event_rounded,
                    child: Column(
                      children: [
                        _buildDateField(
                          label: 'Purchase Date',
                          icon: Icons.shopping_bag_rounded,
                          selectedDate: _selectedPurchaseDate,
                          onTap: () => _selectDate(context, true),
                        ),
                        const SizedBox(height: 16),
                        _buildDateField(
                          label: 'Warranty End Date',
                          icon: Icons.verified_user_rounded,
                          selectedDate: _selectedWarrantyPeriod,
                          onTap: () => _selectDate(context, false),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Error Display
                  if (_errorMessage.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_rounded, color: Colors.red.shade600, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Add Button
                  _buildActionButton(),
                  
                  // Bottom spacing for safe area
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.blue.shade600, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
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
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.blue.shade600),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          labelStyle: TextStyle(color: Colors.grey.shade600),
          hintStyle: TextStyle(color: Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(icon, color: Colors.blue.shade600),
        title: Text(
          selectedDate == null ? label : DateFormat('MMM dd, yyyy').format(selectedDate),
          style: TextStyle(
            fontSize: 16,
            color: selectedDate == null ? Colors.grey.shade600 : Colors.grey.shade800,
            fontWeight: selectedDate == null ? FontWeight.normal : FontWeight.w500,
          ),
        ),
        trailing: Icon(Icons.calendar_month_rounded, color: Colors.blue.shade600),
        onTap: onTap,
      ),
    );
  }

  Widget _buildCategoryDropdown() {
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
              Icon(Icons.category_rounded, color: Colors.blue.shade600),
              const SizedBox(width: 12),
              Text(
                'Select a category',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
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
                  Icon(_getCategoryIcon(category), color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _getCategoryName(category),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade700],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isLoading ? null : _addProduct,
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Add Product',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
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
              primary: Colors.blue.shade600,
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

  Future<void> _addProduct() async {
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
      // Create product object
      Products newProduct = Products(
        id: '',
        uid: widget.uid,
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        purchasedDate: _selectedPurchaseDate!,
        warrantyPeriod: _selectedWarrantyPeriod!,
        contactNumber: contactNumber,
        type: _selectedCategory!,
      );

      // Call the FirestoreService to add the product
      await FirestoreService.addProduct(newProduct);
      
      // Close the bottom sheet
      if (mounted) {
        Navigator.of(context).pop();
        widget.onProductAdded();
      }
    } catch (e) {
      _showError('Failed to add product: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
