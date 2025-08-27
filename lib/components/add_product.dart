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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
          left: 24,
          right: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Header Section
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.add_box,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Add New Appliance",
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 22,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                      Text(
                        "Fill in the details below",
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Error Message Display
              if (_errorMessage.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Category Selection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.category_outlined, color: Colors.purple.shade600),
                        const SizedBox(width: 8),
                        Text(
                          "Product Category",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Category>(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                        ),
                        prefixIcon: Icon(Icons.devices, color: Colors.grey.shade600),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      hint: Text(
                        'Select appliance type',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      value: _selectedCategory,
                      onChanged: (Category? newValue) {
                        _clearError();
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      },
                      items: Category.values.map((Category category) {
                        String displayName = category.toString().split('.').last;
                        // Add spaces before capital letters
                        displayName = displayName.replaceAllMapped(
                          RegExp(r'([A-Z])'), 
                          (match) => ' ${match.group(0)}',
                        ).trim();
                        
                        return DropdownMenuItem<Category>(
                          value: category,
                          child: Text(displayName),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Product Details Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Text(
                          "Product Details",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStyledTextField(
                      controller: _nameController,
                      label: 'Product Name',
                      icon: Icons.devices,
                      hint: 'e.g., Samsung Smart TV',
                    ),
                    const SizedBox(height: 16),
                    _buildStyledTextField(
                      controller: _locationController,
                      label: 'Location',
                      icon: Icons.location_on_outlined,
                      hint: 'e.g., Living Room',
                    ),
                    const SizedBox(height: 16),
                    _buildStyledTextField(
                      controller: _contactNumberController,
                      label: 'Service Contact',
                      icon: Icons.phone_outlined,
                      hint: 'Support phone number',
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Date Selection Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.date_range, color: Colors.green.shade600),
                        const SizedBox(width: 8),
                        Text(
                          "Important Dates",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Purchase Date
                    _buildDateSelector(
                      title: 'Purchase Date',
                      icon: Icons.shopping_cart_outlined,
                      selectedDate: _selectedPurchaseDate,
                      color: Colors.blue.shade600,
                      onTap: () async {
                        _clearError();
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _selectedPurchaseDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          builder: (BuildContext context, Widget? child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Colors.blue.shade600,
                                  onPrimary: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (pickedDate != null) {
                          setState(() {
                            _selectedPurchaseDate = DateTime(
                              pickedDate.year, 
                              pickedDate.month, 
                              pickedDate.day
                            );
                          });
                        }
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Warranty Period
                    _buildDateSelector(
                      title: 'Warranty End Date',
                      icon: Icons.shield_outlined,
                      selectedDate: _selectedWarrantyPeriod,
                      color: Colors.green.shade600,
                      onTap: () async {
                        _clearError();
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _selectedWarrantyPeriod ?? DateTime.now().add(const Duration(days: 365)),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          builder: (BuildContext context, Widget? child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Colors.green.shade600,
                                  onPrimary: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (pickedDate != null) {
                          setState(() {
                            _selectedWarrantyPeriod = DateTime(
                              pickedDate.year, 
                              pickedDate.month, 
                              pickedDate.day
                            );
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Add Button
              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _addProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_circle_outline, color: Colors.white),
                            const SizedBox(width: 8),
                            const Text(
                              'Add Appliance',
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: (_) => _clearError(),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey.shade600),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector({
    required String title,
    required IconData icon,
    required DateTime? selectedDate,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selectedDate != null ? color.withOpacity(0.5) : Colors.grey.shade300
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: selectedDate != null ? color : Colors.grey.shade600),
                const SizedBox(width: 12),
                Text(
                  selectedDate == null
                      ? 'Select $title'
                      : DateFormat('MMM dd, yyyy').format(selectedDate),
                  style: TextStyle(
                    fontSize: 16,
                    color: selectedDate == null 
                        ? Colors.grey.shade600
                        : Theme.of(context).colorScheme.inversePrimary,
                    fontWeight: selectedDate != null ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.calendar_today, 
                  color: selectedDate != null ? color : Colors.grey.shade400, 
                  size: 20
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addProduct() async {
    _clearError();
    
    if (_selectedCategory == null) {
      _showError('Please select a product category');
      return;
    }
    
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter the product name');
      return;
    }
    
    if (_locationController.text.trim().isEmpty) {
      _showError('Please enter the location');
      return;
    }
    
    if (_contactNumberController.text.trim().isEmpty) {
      _showError('Please enter the service contact number');
      return;
    }
    
    if (_selectedPurchaseDate == null) {
      _showError('Please select the purchase date');
      return;
    }
    
    if (_selectedWarrantyPeriod == null) {
      _showError('Please select the warranty end date');
      return;
    }

    // Validate contact number
    if (int.tryParse(_contactNumberController.text.trim()) == null) {
      _showError('Please enter a valid phone number');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      Products newProduct = Products(
        id: '',
        uid: widget.uid,
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        purchasedDate: _selectedPurchaseDate!,
        warrantyPeriod: _selectedWarrantyPeriod!,
        contactNumber: int.parse(_contactNumberController.text.trim()),
        type: _selectedCategory!,
      );

      await FirestoreService.addProduct(newProduct);
      widget.onProductAdded();
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError('Failed to add product: ${e.toString()}');
    }
  }
}
