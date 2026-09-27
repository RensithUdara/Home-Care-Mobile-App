import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_care/components/ui/common.dart';
import 'package:home_care/components/ui/depth.dart';
import 'package:home_care/models/products.dart';
import 'package:home_care/services/firestore/firestore_services.dart';
import 'package:home_care/themes/app_colors.dart';
import 'package:home_care/utils/product_utils.dart';
import 'package:intl/intl.dart';

/// One form for both adding and editing an appliance.
class ProductFormSheet extends StatefulWidget {
  final String uid;
  final Products? product;
  final VoidCallback onSaved;

  const ProductFormSheet({
    super.key,
    required this.uid,
    required this.onSaved,
    this.product,
  });

  bool get isEditing => product != null;

  static Future<void> show(
    BuildContext context, {
    required String uid,
    required VoidCallback onSaved,
    Products? product,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.92,
          ),
          child: ProductFormSheet(uid: uid, onSaved: onSaved, product: product),
        ),
      ),
    );
  }

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _location = TextEditingController();
  final _contact = TextEditingController();
  final _price = TextEditingController();
  final _serial = TextEditingController();
  final _notes = TextEditingController();

  Category? _category;
  DateTime? _purchase;
  DateTime? _warranty;
  int? _presetMonths;
  bool _saving = false;
  String _error = '';

  static const _presets = [6, 12, 24, 36, 60];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _name.text = p.name;
      _brand.text = p.brand ?? '';
      _location.text = p.location;
      _contact.text = p.contactNumber.toString();
      _price.text = p.price == null
          ? ''
          : (p.price! % 1 == 0
              ? p.price!.toInt().toString()
              : p.price!.toStringAsFixed(2));
      _serial.text = p.serialNumber ?? '';
      _notes.text = p.notes ?? '';
      _category = p.type;
      _purchase = p.purchasedDate;
      _warranty = p.warrantyPeriod;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _brand,
      _location,
      _contact,
      _price,
      _serial,
      _notes
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _clearError() {
    if (_error.isNotEmpty) setState(() => _error = '');
  }

  DateTime _addMonths(DateTime from, int months) {
    final target = DateTime(from.year, from.month + months, 1);
    final lastDay = DateTime(target.year, target.month + 1, 0).day;
    return DateTime(
        target.year, target.month, from.day > lastDay ? lastDay : from.day);
  }

  void _applyPreset(int months) {
    final base = _purchase ?? DateTime.now();
    setState(() {
      _purchase ??= base;
      _presetMonths = months;
      _warranty = _addMonths(base, months);
    });
    HapticFeedback.selectionClick();
    _clearError();
  }

  Future<void> _pickDate(bool purchase) async {
    final initial = (purchase ? _purchase : _warranty) ??
        (purchase ? DateTime.now() : (_purchase ?? DateTime.now()));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (purchase) {
        _purchase = picked;
        if (_presetMonths != null) {
          _warranty = _addMonths(picked, _presetMonths!);
        }
      } else {
        _warranty = picked;
        _presetMonths = null;
      }
    });
    _clearError();
  }

  Future<void> _save() async {
    _clearError();
    final contact =
        int.tryParse(_contact.text.replaceAll(RegExp(r'[\s\-()+]'), ''));
    final priceText = _price.text.trim().replaceAll(',', '');
    final price = priceText.isEmpty ? null : double.tryParse(priceText);

    String? problem;
    if (_category == null) {
      problem = 'Please choose a category';
    } else if (_name.text.trim().isEmpty) {
      problem = 'Please enter a product name';
    } else if (_location.text.trim().isEmpty) {
      problem = 'Please enter a location';
    } else if (_contact.text.trim().isEmpty) {
      problem = 'Please enter a support contact number';
    } else if (contact == null) {
      problem = 'Please enter a valid contact number';
    } else if (_purchase == null) {
      problem = 'Please select a purchase date';
    } else if (_warranty == null) {
      problem = 'Please select a warranty end date';
    } else if (_warranty!.isBefore(_purchase!)) {
      problem = 'Warranty end date must be after the purchase date';
    } else if (priceText.isNotEmpty && (price == null || price < 0)) {
      problem = 'Please enter a valid price';
    }
    if (problem != null) {
      setState(() => _error = problem!);
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() => _saving = true);
    final product = Products(
      id: widget.product?.id ?? '',
      uid: widget.product?.uid ?? widget.uid,
      name: _name.text.trim(),
      location: _location.text.trim(),
      purchasedDate: _purchase!,
      warrantyPeriod: _warranty!,
      contactNumber: contact!,
      type: _category!,
      brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
      serialNumber: _serial.text.trim().isEmpty ? null : _serial.text.trim(),
      price: price,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );

    try {
      if (widget.isEditing) {
        await FirestoreService.editProduct(product);
      } else {
        await FirestoreService.addProduct(product);
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      widget.onSaved();
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppColors.success,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Text(
          widget.isEditing
              ? '${product.name} updated'
              : '${product.name} added to your home',
          style:
              const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ));
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              'Could not save: ${e.toString().replaceFirst('Exception: ', '')}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      title: widget.isEditing ? 'Edit Appliance' : 'Add Appliance',
      subtitle: widget.isEditing
          ? 'Update the details below'
          : 'Track it and never miss a warranty',
      icon: widget.isEditing ? Icons.edit_rounded : Icons.add_home_work_rounded,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, 20 + MediaQuery.of(context).padding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Category'),
            _categoryGrid(),
            _label('Details'),
            _field(_name, 'Product name', Icons.inventory_2_rounded,
                capitalization: TextCapitalization.words),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field(_brand, 'Brand (optional)',
                      Icons.workspace_premium_rounded,
                      capitalization: TextCapitalization.words),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(_location, 'Location', Icons.place_rounded,
                      capitalization: TextCapitalization.words),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _field(
                _contact, 'Support contact number', Icons.support_agent_rounded,
                keyboard: TextInputType.phone),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field(
                      _price, 'Price (optional)', Icons.payments_rounded,
                      keyboard:
                          const TextInputType.numberWithOptions(decimal: true)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                      _serial, 'Serial no. (optional)', Icons.qr_code_rounded),
                ),
              ],
            ),
            _label('Warranty'),
            Row(
              children: [
                Expanded(
                  child: _dateTile('Purchased', _purchase,
                      Icons.shopping_bag_rounded, () => _pickDate(true)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dateTile('Warranty ends', _warranty,
                      Icons.verified_user_rounded, () => _pickDate(false)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in _presets) _presetChip(m),
              ],
            ),
            _label('Notes'),
            _field(_notes, 'Model, store, receipt location…',
                Icons.sticky_note_2_rounded,
                maxLines: 3),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_rounded,
                        color: AppColors.danger, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error,
                          style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            Button3D(
              label: widget.isEditing ? 'Save Changes' : 'Add Appliance',
              icon: widget.isEditing ? Icons.check_rounded : Icons.add_rounded,
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11.5,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            color: context.textMuted,
          ),
        ),
      );

  Widget _field(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    TextCapitalization capitalization = TextCapitalization.sentences,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      textCapitalization: capitalization,
      onChanged: (_) => _clearError(),
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: maxLines == 1 ? Icon(icon, size: 20) : null,
        isDense: true,
      ),
    );
  }

  Widget _categoryGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.25,
      children: [
        for (final c in Category.values) _categoryTile(c),
      ],
    );
  }

  Widget _categoryTile(Category c) {
    final selected = _category == c;
    final color = ProductUtils.colorOf(c);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _category = c);
        _clearError();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: selected ? AppColors.shade(color) : null,
          color: selected ? null : context.surface,
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.3)
                : context.outline,
          ),
          boxShadow: selected
              ? AppShadows.glow(color)
              : AppShadows.raised(context, depth: 0.3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ProductUtils.iconOf(c),
                color: selected ? Colors.white : color, size: 26),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                ProductUtils.categoryName(c),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : context.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateTile(
      String label, DateTime? date, IconData icon, VoidCallback onTap) {
    return DepthCard(
      onTap: onTap,
      tilt: false,
      depth: 0.4,
      radius: 16,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 11, color: context.textMuted)),
                const SizedBox(height: 2),
                Text(
                  date == null
                      ? 'Select'
                      : DateFormat('MMM d, yyyy').format(date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color:
                        date == null ? context.textMuted : context.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetChip(int months) {
    final selected = _presetMonths == months;
    final label = months < 12
        ? '$months months'
        : '${months ~/ 12} year${months >= 24 ? 's' : ''}';
    return GestureDetector(
      onTap: () => _applyPreset(months),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.brandGradient : null,
          color: selected ? null : context.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? AppShadows.glow(AppColors.primary, strength: 0.7)
              : null,
        ),
        child: Text(
          '+ $label',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : context.textPrimary,
          ),
        ),
      ),
    );
  }
}
