import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late Animation<double> _scaleAnimation;

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

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    // Start animation only if widget is still mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void deactivate() {
    _animationController.stop();
    super.deactivate();
  }

  @override
  void dispose() {
    _animationController.stop();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    String type = ProductUtils.getTypeName(widget.product.type.toString());
    String imgPath = ProductUtils.getImagePath(type);
    String purchasedDate = DateFormat.yMMMd().format(widget.product.purchasedDate);
    String warranty = DateFormat.yMMMd().format(widget.product.warrantyPeriod);
    String contactNumber = widget.product.contactNumber.toString();
    Color primaryColor = ProductUtils.getColor(type);

    bool checkWarrantyExpiration(DateTime warrantyPeriod) {
      DateTime currentDate = DateTime.now();
      return currentDate.isAfter(warrantyPeriod);
    }

    bool isExpired = checkWarrantyExpiration(widget.product.warrantyPeriod);
    int daysUntilExpiry = widget.product.warrantyPeriod.difference(DateTime.now()).inDays;
    bool isExpiringSoon = daysUntilExpiry <= 30 && daysUntilExpiry > 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        leading: _buildIconButton(Icons.arrow_back_ios_new, () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        }, theme, primaryColor),
        actions: [
          _buildIconButton(Icons.edit_outlined, () {
            HapticFeedback.lightImpact();
            _showEditProductBottomSheet(context);
          }, theme, primaryColor),
          _buildIconButton(Icons.delete_outline, () {
            HapticFeedback.mediumImpact();
            _showDeleteConfirmation();
          }, theme, Colors.red),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Compact Hero Section
          SliverToBoxAdapter(
            child: Container(
              height: 280,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark 
                    ? [
                        primaryColor.withOpacity(0.3),
                        primaryColor.withOpacity(0.1),
                        theme.colorScheme.surface,
                      ]
                    : [
                        primaryColor.withOpacity(0.1),
                        primaryColor.withOpacity(0.05),
                        theme.colorScheme.surface,
                      ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: isDark 
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
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
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Image.asset(
                          imgPath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              ProductUtils.getIconData(type),
                              size: 60,
                              color: primaryColor,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Product Name
                  SlideTransition(
                    position: _slideAnimation,
                    child: Text(
                      widget.product.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Product Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isExpired ? Colors.red : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isExpired ? Icons.warning_rounded : Icons.schedule_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isExpired
                          ? 'Warranty Expired'
                          : 'Expires in $daysUntilExpiry days',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Compact Info Cards
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick Stats
                _buildStatsRow(theme, purchasedDate, warranty, isExpired),
                
                const SizedBox(height: 16),
                
                // Product Details
                _buildCompactCard(
                  theme,
                  'Product Details',
                  Icons.info_outline,
                  primaryColor,
                  [
                    _buildDetailRow('Product Name', widget.product.name, theme),
                    _buildDetailRow('Category', type, theme),
                    _buildDetailRow('Location', widget.product.location, theme),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Support Details
                _buildCompactCard(
                  theme,
                  'Support & Warranty',
                  Icons.support_agent,
                  isExpired ? Colors.red : Colors.green,
                  [
                    _buildDetailRow('Purchase Date', purchasedDate, theme),
                    _buildDetailRow('Warranty Until', warranty, theme),
                    _buildDetailRow('Support Number', contactNumber, theme),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Action Buttons
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      // Call Support Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            _callSupport(contactNumber);
                          },
                          icon: const Icon(Icons.phone, size: 20),
                          label: const Text('Call Support'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Secondary Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                _showEditProductBottomSheet(context);
                              },
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Edit'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                _showDeleteConfirmation();
                              },
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Delete'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.5),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Text(
                                type,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Ultra-modern content cards
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.grey[900]!,
                      Colors.black,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Warranty status with stunning design
                      if (isExpired || isExpiringSoon)
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isExpired
                                    ? [Colors.red.shade600, Colors.red.shade800]
                                    : [Colors.orange.shade600, Colors.orange.shade800],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: (isExpired ? Colors.red : Colors.orange).withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Icon(
                                    isExpired ? Icons.warning_rounded : Icons.schedule_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isExpired ? 'Warranty Expired' : 'Warranty Expiring Soon',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isExpired 
                                            ? 'This product is no longer covered'
                                            : 'Expires in $daysUntilExpiry days',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
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
                      
                      // Premium info cards
                      _buildPremiumInfoCard(
                        context,
                        'Product Information',
                        [
                          _buildPremiumDetailRow('Product Name', widget.product.name, Icons.label),
                          _buildPremiumDetailRow('Category', type, Icons.category),
                          _buildPremiumDetailRow('Location', widget.product.location, Icons.location_on),
                        ],
                        primaryColor,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildPremiumInfoCard(
                        context,
                        'Warranty & Support',
                        [
                          _buildPremiumDetailRow('Purchase Date', purchasedDate, Icons.calendar_today),
                          _buildPremiumDetailRow('Warranty Until', warranty, Icons.security),
                          _buildPremiumDetailRow('Support Contact', contactNumber, Icons.phone),
                        ],
                        isExpired ? Colors.red.shade600 : Colors.green.shade600,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Premium action button
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, primaryColor.withOpacity(0.8)],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                _callSupport(contactNumber);
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.phone, color: Colors.white, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    'Call Support Now',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Secondary actions
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.blue.shade600.withOpacity(0.5)),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(25),
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    _showEditProductBottomSheet(context);
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.edit, color: Colors.blue.shade600, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Edit',
                                        style: TextStyle(
                                          color: Colors.blue.shade600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.red.shade600.withOpacity(0.5)),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(25),
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    _showDeleteConfirmation();
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.delete, color: Colors.red.shade600, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: Colors.red.shade600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build premium card info method
  Widget _buildPremiumInfoCard(
    BuildContext context,
    String title,
    List<Widget> children,
    Color accentColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.info,
              color: accentColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // Build premium detail row
  Widget _buildPremiumDetailRow(String label, String value, IconData icon) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.10),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: primaryColor,
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
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Method to handle calling support
  void _callSupport(String phoneNumber) {
    try {
      // Use the flutter_phone_direct_caller plugin
      // FlutterPhoneDirectCaller.callNumber(phoneNumber);

      // For now, we'll show a snackbar since we removed the import
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calling $phoneNumber...'),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to call $phoneNumber'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Appliance'),
        content: Text(
            'Are you sure you want to delete "${widget.product.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child:
                Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      widget.onDelete(widget.product.id);
      Navigator.pop(context);
    }
  }

  Future<void> _showEditProductBottomSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return EditProductBottomSheet(
          product: widget.product,
          onProductEdited: widget.onProductEdited,
        );
      },
    );
  }
}

