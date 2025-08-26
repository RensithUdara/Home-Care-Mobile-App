import 'package:flutter/material.dart';
import 'package:home_care/components/text_input_field.dart';

import 'package:intl/intl.dart';
import 'package:home_care/models/products.dart';
import 'package:home_care/services/firestore/firestore_services.dart';

class EditProductBottomSheet extends StatefulWidget {
  final Products product;
  final Function onProductEdited;

  const EditProductBottomSheet(
      {super.key, required this.product, required this.onProductEdited});

  @override
  State<EditProductBottomSheet> createState() => _EditProductBottomSheetState();
}

class _EditProductBottomSheetState extends State<EditProductBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _contactNumberController;

  DateTime? _selectedPurchaseDate;
  DateTime? _selectedWarrantyPeriod;
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with product's current values
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
    // Dispose controllers to avoid memory leaks
    _nameController.dispose();
    _locationController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  "Edit Product",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(
                  width: 10,
                ),
                Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                        color: Colors.blue, shape: BoxShape.circle),
                    child: const Icon(
                      Icons.edit,
                      size: 20,
                      color: Colors.white,
                    ))
              ],
            ),
            const SizedBox(
              height: 30,
            ),
            DropdownButton<Category>(
              focusColor: Theme.of(context).colorScheme.tertiary,
              padding: const EdgeInsets.all(5),
              hint: const Text(
                'Select Category',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              value: _selectedCategory,
              onChanged: (Category? newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
              items: Category.values.map((Category category) {
                return DropdownMenuItem<Category>(
                  value: category,
                  child: Text(category.toString().split('.').last),
                );
              }).toList(),
            ),
            const SizedBox(
              height: 10,
            ),
            TextInputField(
              icon: Icons.abc,
              controller: _nameController,
              labelText: 'Product Name',
            ),
            const SizedBox(
              height: 10,
            ),
            TextInputField(
              icon: Icons.location_city,
              controller: _locationController,
              labelText: 'Location ',
            ),
            const SizedBox(
              height: 10,
            ),
            TextInputField(
              icon: Icons.call,
              controller: _contactNumberController,
              labelText: 'Service Center Contact Number',
            ),
            const SizedBox(
              height: 10,
            ),
            ListTile(
              title: Text(_selectedPurchaseDate == null
                  ? 'Select Purchase Date'
                  : DateFormat('yyyy-MM-dd').format(_selectedPurchaseDate!)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  builder: (BuildContext context, Widget? child) {
                    return Theme(
                      data: ThemeData.light().copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Colors.blue,
                          onPrimary: Colors.white,
                          onSurface: Color.fromARGB(255, 1, 1, 1),
                        ),
                        textButtonTheme: const TextButtonThemeData(),
                      ),
                      child: child!,
                    );
                  },
                  context: context,
                  initialDate: _selectedPurchaseDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  setState(() {
                    _selectedPurchaseDate = DateTime(
                        pickedDate.year, pickedDate.month, pickedDate.day);
                  });
                }
              },
            ),
            ListTile(
              title: Text(_selectedWarrantyPeriod == null
                  ? 'Select Warranty Period'
                  : DateFormat('yyyy-MM-dd').format(_selectedWarrantyPeriod!)),
              trailing:const Icon(Icons.calendar_today),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  builder: (BuildContext context, Widget? child) {
                    return Theme(
                      data: ThemeData.light().copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Colors.blue,
                          onPrimary: Colors.white,
                          onSurface: Color.fromARGB(255, 1, 1, 1),
                        ),
                        textButtonTheme: const TextButtonThemeData(),
                      ),
                      child: child!,
                    );
                  },
                  context: context,
                  initialDate: _selectedWarrantyPeriod ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  setState(() {
                    _selectedWarrantyPeriod = DateTime(
                        pickedDate.year, pickedDate.month, pickedDate.day);
                  });
                }
              },
            ),
            GestureDetector(
              onTap: () async {
                if (_nameController.text.isEmpty ||
                    _locationController.text.isEmpty ||
                    _contactNumberController.text.isEmpty ||
                    _selectedPurchaseDate == null ||
                    _selectedWarrantyPeriod == null ||
                    _selectedCategory == null) {
                  showErrorDialog(context);
                  return;
                }

                // Create updated product object
                Products updatedProduct = Products(
                  id: widget.product.id, // Use the existing ID
                  uid: widget.product.uid, // Use the existing UID
                  name: _nameController.text,
                  location: _locationController.text,
                  purchasedDate: _selectedPurchaseDate!,
                  warrantyPeriod: _selectedWarrantyPeriod!,
                  contactNumber: int.parse(_contactNumberController.text),
                  type: _selectedCategory!,
                );

                // Call the FirestoreService to update the product
                await FirestoreService.editProduct(updatedProduct);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                widget.onProductEdited();
              },
              child: Container(
                padding: const EdgeInsets.all(15),
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(30)),
                child: const Center(
                    child: Text(
                  'Update Product',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                )),
              ),
            ),
            const SizedBox(
              height: 20,
            )
          ],
        ),
      ),
    );
  }

  Future<dynamic> showErrorDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text(
            'Please complete all required fields',
            style: TextStyle(fontSize: 18),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'OK',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
