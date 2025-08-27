import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:home_care/components/edit_product_bottom_sheet.dart';
import 'package:home_care/models/products.dart';
import 'package:home_care/utils/product_utils.dart';
import 'package:intl/intl.dart';

class ProductPage extends StatefulWidget {
  final Products product;
  final Function(String) onDelete;
  final Function onProductEdited;
  const ProductPage(
      {super.key,
      required this.product,
      required this.onDelete,
      required this.onProductEdited});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _callSupport(String phoneNumber) async {
    try {
      await FlutterPhoneDirectCaller.callNumber(phoneNumber);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not make call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditProductBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => EditProductBottomSheet(
        product: widget.product,
        onProductEdited: () {
          widget.onProductEdited();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Product?'),
          content: Text('Are you sure you want to delete "${widget.product.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                widget.onDelete(widget.product.id);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final typeString = ProductUtils.getTypeName(widget.product.type.toString());
    final imgPath = ProductUtils.getImagePath(typeString);
    final purchasedDate = DateFormat.yMMMd().format(widget.product.purchasedDate);
    final warranty = DateFormat.yMMMd().format(widget.product.warrantyPeriod);
    final contactNumber = widget.product.contactNumber.toString();
    final primaryColor = ProductUtils.getColor(typeString);

    bool checkWarrantyExpiration(DateTime warrantyPeriod) {
      DateTime currentDate = DateTime.now();
      return currentDate.isAfter(warrantyPeriod);
    }

    bool isExpired = checkWarrantyExpiration(widget.product.warrantyPeriod);
    int daysUntilExpiry = widget.product.warrantyPeriod.difference(DateTime.now()).inDays;
    bool isExpiringSoon = daysUntilExpiry <= 30 && daysUntilExpiry > 0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0B) : const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark 
          ? Colors.black.withOpacity(0.7) 
          : Colors.white.withOpacity(0.95),
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark 
          ? SystemUiOverlayStyle.light 
          : SystemUiOverlayStyle.dark,
        leading: _buildActionButton(
          Icons.arrow_back_ios_new,
          () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          isDark,
          isDestructive: false,
        ),
        actions: [
          _buildActionButton(
            Icons.edit_outlined,
            () {
              HapticFeedback.lightImpact();
              _showEditProductBottomSheet(context);
            },
            isDark,
            isDestructive: false,
          ),
          _buildActionButton(
            Icons.delete_outline,
            () {
              HapticFeedback.mediumImpact();
              _showDeleteConfirmation();
            },
            isDark,
            isDestructive: true,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero Section
          SliverToBoxAdapter(
            child: Container(
              height: 320,
              margin: const EdgeInsets.fromLTRB(20, 100, 20, 20),
              decoration: BoxDecoration(
                color: isDark 
                  ? const Color(0xFF1A1A1B) 
                  : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark 
                    ? primaryColor.withOpacity(0.3) 
                    : primaryColor.withOpacity(0.15),
                  width: isDark ? 1 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.4)
                        : primaryColor.withOpacity(0.12),
                    blurRadius: isDark ? 25 : 20,
                    offset: const Offset(0, 10),
                    spreadRadius: isDark ? 0 : 2,
                  ),
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Product Image
                  Hero(
                    tag: 'product_${widget.product.id}',
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: isDark
                            ? primaryColor.withOpacity(0.15)
                            : primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: primaryColor.withOpacity(isDark ? 0.4 : 0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(isDark ? 0.2 : 0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          imgPath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              ProductUtils.getIconData(typeString),
                              size: 60,
                              color: primaryColor,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Product Name
                  SlideTransition(
                    position: _slideAnimation,
                    child: Text(
                      widget.product.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Product Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      typeString,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Warranty Status Banner
          if (isExpired || isExpiringSoon)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isExpired ? Colors.red : Colors.orange,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (isExpired ? Colors.red : Colors.orange).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      isExpired ? Icons.warning_rounded : Icons.schedule_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isExpired ? 'Warranty Expired' : 'Warranty Expiring Soon',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            isExpired 
                              ? 'Expired on $warranty'
                              : 'Expires in $daysUntilExpiry days',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Product Details Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Quick Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Purchase Date',
                          purchasedDate,
                          Icons.calendar_today,
                          Colors.blue,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Warranty Until',
                          warranty,
                          Icons.shield_outlined,
                          isExpired ? Colors.red : Colors.green,
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Product ID',
                          widget.product.id.substring(0, 8).toUpperCase(),
                          Icons.qr_code,
                          Colors.purple,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Support Contact',
                          contactNumber,
                          Icons.phone,
                          Colors.orange,
                          isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Additional Details Card
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark 
                    ? Colors.white.withOpacity(0.1) 
                    : Colors.black.withOpacity(0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Type', typeString, isDark),
                  _buildDetailRow('Location', widget.product.location, isDark),
                  _buildDetailRow('Contact', contactNumber, isDark),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Action Buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Call Support Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _callSupport(contactNumber);
                      },
                      icon: const Icon(Icons.phone, size: 24, color: Colors.white),
                      label: const Text(
                        'Call Support',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: isDark ? 8 : 4,
                        shadowColor: primaryColor.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Secondary Actions
                  Row(
                    children: [
                      Expanded(
                        child: _buildSecondaryButton(
                          'Edit Product',
                          Icons.edit_outlined,
                          () {
                            HapticFeedback.lightImpact();
                            _showEditProductBottomSheet(context);
                          },
                          primaryColor,
                          isDark,
                          false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSecondaryButton(
                          'Delete',
                          Icons.delete_outline,
                          () {
                            HapticFeedback.lightImpact();
                            _showDeleteConfirmation();
                          },
                          Colors.red,
                          isDark,
                          true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onPressed, bool isDark, {required bool isDestructive}) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDestructive 
          ? (isDark ? Colors.red.withOpacity(0.15) : Colors.red.withOpacity(0.1))
          : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDestructive 
            ? Colors.red.withOpacity(0.3)
            : (isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1)),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDestructive 
              ? Colors.red.withOpacity(isDark ? 0.2 : 0.1)
              : (isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08)),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isDestructive 
            ? Colors.red 
            : (isDark ? Colors.white : Colors.black87),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
            ? color.withOpacity(0.3)
            : color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton(
    String text,
    IconData icon,
    VoidCallback onPressed,
    Color color,
    bool isDark,
    bool isDestructive,
  ) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: color),
        label: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark 
            ? color.withOpacity(0.1) 
            : Colors.white,
          side: BorderSide(
            color: color,
            width: isDark ? 1 : 1.5,
          ),
          elevation: isDark ? 0 : 2,
          shadowColor: color.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
