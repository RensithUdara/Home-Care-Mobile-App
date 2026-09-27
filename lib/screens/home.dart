import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_care/components/product_card.dart';
import 'package:home_care/components/product_form_sheet.dart';
import 'package:home_care/components/ui/common.dart';
import 'package:home_care/components/ui/depth.dart';
import 'package:home_care/components/ui/modern_app_bar.dart';
import 'package:home_care/models/products.dart';
import 'package:home_care/screens/product.dart';
import 'package:home_care/services/product_store.dart';
import 'package:home_care/themes/app_colors.dart';
import 'package:home_care/utils/product_utils.dart';
import 'package:home_care/utils/share_helper.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeTab extends StatefulWidget {
  final String email;
  final ValueChanged<int> onNavigate;
  final VoidCallback onAdd;

  const HomeTab({
    super.key,
    required this.email,
    required this.onNavigate,
    required this.onAdd,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  static const _gridPrefKey = 'home_grid_view';

  final TextEditingController _searchController = TextEditingController();
  Category? _selectedCategory;
  bool _favoritesOnly = false;
  ProductSort _sort = ProductSort.recent;
  bool _grid = true;

  @override
  void initState() {
    super.initState();
    _loadViewPref();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadViewPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final grid = prefs.getBool(_gridPrefKey);
      if (grid != null && mounted) setState(() => _grid = grid);
    } catch (_) {}
  }

  Future<void> _toggleView() async {
    HapticFeedback.selectionClick();
    setState(() => _grid = !_grid);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_gridPrefKey, _grid);
    } catch (_) {}
  }

  String _getGreeting() {
    int hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _firstName {
    final display = FirebaseAuth.instance.currentUser?.displayName?.trim();
    if (display != null && display.isNotEmpty) return display.split(' ').first;
    final local = widget.email.split('@').first;
    if (local.isEmpty) return 'there';
    return local[0].toUpperCase() + local.substring(1);
  }

  List<Products> _visible(List<Products> all) {
    final q = _searchController.text.trim().toLowerCase();
    final filtered = all.where((p) {
      final matchesSearch = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.location.toLowerCase().contains(q) ||
          (p.brand?.toLowerCase().contains(q) ?? false) ||
          ProductUtils.categoryName(p.type).toLowerCase().contains(q);
      final matchesCategory = _favoritesOnly
          ? p.isFavorite
          : (_selectedCategory == null || p.type == _selectedCategory);
      return matchesSearch && matchesCategory;
    }).toList();
    return ProductStore.sorted(filtered, _sort);
  }

  void _open(Products p) => ProductPage.open(context, p);

  Future<void> _delete(Products p) async {
    final store = context.read<ProductStore>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final backup = await store.delete(p);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppColors.primaryDark,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        content: Text('${p.name} deleted',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () => store.restore(backup),
        ),
      ));
    } catch (_) {
      if (mounted) AppSnack.error(context, 'Could not delete ${p.name}');
    }
  }

  void _quickActions(Products p) {
    HapticFeedback.mediumImpact();
    final store = context.read<ProductStore>();
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SheetFrame(
        title: p.name,
        subtitle: ProductUtils.categoryName(p.type),
        icon: ProductUtils.iconOf(p.type),
        color: ProductUtils.colorOf(p.type),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              16, 4, 16, 16 + MediaQuery.of(sheetContext).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _actionTile(sheetContext, Icons.open_in_new_rounded,
                  'Open details', AppColors.primary, () => _open(p)),
              _actionTile(
                  sheetContext, Icons.edit_rounded, 'Edit', AppColors.info, () {
                ProductFormSheet.show(context,
                    uid: store.uid, product: p, onSaved: store.refresh);
              }),
              _actionTile(
                  sheetContext,
                  p.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  p.isFavorite ? 'Remove from favorites' : 'Add to favorites',
                  const Color(0xFFF59E0B), () async {
                try {
                  await store.toggleFavorite(p);
                } catch (_) {
                  if (mounted) {
                    AppSnack.error(context, 'Could not update favorites');
                  }
                }
              }),
              _actionTile(sheetContext, Icons.ios_share_rounded, 'Share',
                  AppColors.secondary, () => shareProduct(context, p)),
              _actionTile(sheetContext, Icons.library_add_rounded, 'Duplicate',
                  AppColors.success, () {
                ProductFormSheet.show(context,
                    uid: store.uid, template: p, onSaved: store.refresh);
              }),
              _actionTile(sheetContext, Icons.delete_rounded, 'Delete',
                  AppColors.danger, () async {
                final ok = await showConfirmDialog(context,
                    title: 'Delete appliance?',
                    message: '"${p.name}" will be removed from your home.',
                    confirmLabel: 'Delete',
                    icon: Icons.delete_forever_rounded);
                if (ok) _delete(p);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionTile(BuildContext sheetContext, IconData icon, String label,
      Color color, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: IconOrb(icon: icon, color: color, size: 40),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: Icon(Icons.chevron_right_rounded, color: context.textMuted),
      onTap: () {
        Navigator.pop(sheetContext);
        onTap();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProductStore>();
    if (_favoritesOnly && store.favorites.isEmpty) _favoritesOnly = false;
    final visible = _visible(store.products);
    final attention = store.needsAttention;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: store.refresh,
        edgeOffset: 120,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            _buildAppBar(store, store.alertCount),
            SliverToBoxAdapter(child: _buildSearchBar()),
            if (attention.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Needs attention',
                  trailing: 'See all',
                  onTrailingTap: () => widget.onNavigate(2),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: attention.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, i) => Entrance(
                      index: i,
                      child: AttentionCard(
                          product: attention[i],
                          onTap: () => _open(attention[i])),
                    ),
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(child: _buildCategoryFilter(store)),
            SliverToBoxAdapter(child: _buildProductsHeader(visible.length)),
            if (store.isLoading && store.products.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(60),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (store.error != null && store.products.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Connection problem',
                  message: store.error!,
                ),
              )
            else if (visible.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyState(store))
            else if (_grid)
              _buildGrid(visible)
            else
              _buildList(visible),
            const SliverToBoxAdapter(child: SizedBox(height: 130)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ProductStore store, int attention) {
    final topPad = MediaQuery.of(context).padding.top;
    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 300 + topPad * 0.2,
      backgroundColor: AppColors.primaryDark,
      automaticallyImplyLeading: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      clipBehavior: Clip.antiAlias,
      title: const Text('Home Care',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      actions: [
        AppBarIconButton(
          icon: Icons.notifications_rounded,
          tooltip: 'Warranty alerts',
          badge: attention,
          onGradient: true,
          onPressed: () => widget.onNavigate(2),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => widget.onNavigate(3),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.7), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'images/avatar.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person_rounded, color: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.brandGradient),
          child: Stack(
            children: [
              const Positioned.fill(child: FloatingOrbs()),
              Positioned(
                left: 20,
                right: 20,
                bottom: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getGreeting()},',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _firstName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryCard(store),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ProductStore store) {
    final coverage = (store.coverage * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Row(
        children: [
          _summaryStat(Icons.devices_rounded, '${store.count}', 'Appliances'),
          _divider(),
          _summaryStat(Icons.shield_rounded,
              store.count == 0 ? '—' : '$coverage%', 'Covered'),
          _divider(),
          _summaryStat(Icons.account_balance_wallet_rounded,
              ProductUtils.formatMoney(store.totalValue), 'Total value'),
        ],
      ),
    );
  }

  Widget _divider() => Container(
      width: 1, height: 36, color: Colors.white.withValues(alpha: 0.25));

  Widget _summaryStat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: DepthCard(
        padding: EdgeInsets.zero,
        radius: 18,
        depth: 0.6,
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Search by name, brand, room…',
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            prefixIcon:
                const Icon(Icons.search_rounded, color: AppColors.primary),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(ProductStore store) {
    final counts = store.byCategory;
    // Only offer categories the user actually owns, plus "All".
    final cats = Category.values.where((c) => counts.containsKey(c)).toList();
    if (cats.isEmpty) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: SizedBox(
        height: 46,
        child: ListView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _chip(null, 'All', Icons.apps_rounded, store.count,
                AppColors.primary),
            if (store.favorites.isNotEmpty)
              _chip(null, 'Favorites', Icons.star_rounded,
                  store.favorites.length, const Color(0xFFF59E0B),
                  favorites: true),
            for (final c in cats)
              _chip(c, ProductUtils.categoryName(c), ProductUtils.iconOf(c),
                  counts[c]!.length, ProductUtils.colorOf(c)),
          ],
        ),
      ),
    );
  }

  Widget _chip(Category? c, String label, IconData icon, int count, Color color,
      {bool favorites = false}) {
    final selected = favorites
        ? _favoritesOnly
        : (!_favoritesOnly && _selectedCategory == c);
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _favoritesOnly = favorites;
            _selectedCategory = c;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.shade(color) : null,
            color: selected ? null : context.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : context.outline.withValues(alpha: 0.6)),
            boxShadow: selected
                ? AppShadows.glow(color, strength: 0.8)
                : AppShadows.raised(context, depth: 0.3),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: selected ? Colors.white : context.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsHeader(int count) {
    return SectionHeader(
      title: 'Your appliances',
      padding: const EdgeInsets.fromLTRB(20, 22, 12, 10),
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count',
              style: TextStyle(
                  color: context.textMuted, fontWeight: FontWeight.w700)),
          PopupMenuButton<ProductSort>(
            tooltip: 'Sort',
            initialValue: _sort,
            icon: Icon(Icons.swap_vert_rounded, color: context.textPrimary),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: context.surface,
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => [
              for (final s in ProductSort.values)
                PopupMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      Icon(
                        s == _sort
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        size: 18,
                        color:
                            s == _sort ? AppColors.primary : context.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Text(s.label),
                    ],
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: _grid ? 'List view' : 'Grid view',
            onPressed: _toggleView,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (c, a) =>
                  RotationTransition(turns: a, child: c),
              child: Icon(
                _grid ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
                key: ValueKey(_grid),
                color: context.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Products> items) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.86,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => Entrance(
            index: i,
            child: ProductGridCard(
              product: items[i],
              onTap: () => _open(items[i]),
              onLongPress: () => _quickActions(items[i]),
            ),
          ),
          childCount: items.length,
        ),
      ),
    );
  }

  Widget _buildList(List<Products> items) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final p = items[i];
          return Entrance(
            index: i,
            child: Dismissible(
              key: ValueKey('dismiss_${p.id}'),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) => showConfirmDialog(context,
                  title: 'Delete appliance?',
                  message: '"${p.name}" will be removed from your home.',
                  confirmLabel: 'Delete',
                  icon: Icons.delete_forever_rounded),
              onDismissed: (_) => _delete(p),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                decoration: BoxDecoration(
                  gradient: AppColors.sunsetGradient,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_rounded, color: Colors.white),
                    SizedBox(width: 6),
                    Text('Delete',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              child: ProductListCard(
                product: p,
                onTap: () => _open(p),
                onLongPress: () => _quickActions(p),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ProductStore store) {
    final filtering = _searchController.text.isNotEmpty ||
        _selectedCategory != null ||
        _favoritesOnly;
    if (filtering && store.count > 0) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matches',
        message: 'Try a different search term or category.',
      );
    }
    return EmptyState(
      icon: Icons.home_work_rounded,
      title: 'Your home is empty',
      message:
          'Add your first appliance to track its warranty, support contact and more.',
      actionLabel: 'Add Appliance',
      onAction: widget.onAdd,
    );
  }
}
