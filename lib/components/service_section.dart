import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_care/components/ui/common.dart';
import 'package:home_care/components/ui/depth.dart';
import 'package:home_care/models/products.dart';
import 'package:home_care/services/product_store.dart';
import 'package:home_care/themes/app_colors.dart';
import 'package:home_care/utils/product_utils.dart';
import 'package:home_care/utils/warranty.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Next-service scheduling plus the repair/maintenance history of a product.
class ServiceSection extends StatelessWidget {
  final Products product;
  const ServiceSection({super.key, required this.product});

  Future<void> _save(BuildContext context, Products updated,
      {String? success}) async {
    try {
      await context.read<ProductStore>().update(updated);
      if (success != null && context.mounted) {
        AppSnack.success(context, success);
      }
    } catch (_) {
      if (context.mounted) AppSnack.error(context, 'Could not save changes');
    }
  }

  DateTime _plusMonths(int months) {
    final now = DateTime.now();
    return DateTime(now.year, now.month + months, now.day);
  }

  Future<void> _schedule(BuildContext context) async {
    final choice = await showModalBottomSheet<Object>(
      context: context,
      builder: (sheetContext) => SheetFrame(
        title: 'Schedule next service',
        subtitle: 'We\'ll remind you 3 days before',
        icon: Icons.event_repeat_rounded,
        color: AppColors.info,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 8, 20, 20 + MediaQuery.of(sheetContext).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in [1, 3, 6, 12])
                    ActionChip(
                      label: Text(
                          m == 12
                              ? 'In 1 year'
                              : 'In $m month${m == 1 ? '' : 's'}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () => Navigator.pop(sheetContext, m),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Button3D(
                label: 'Pick a date',
                icon: Icons.calendar_month_rounded,
                height: 50,
                gradient: AppColors.oceanGradient,
                onPressed: () => Navigator.pop(sheetContext, 'pick'),
              ),
              if (product.nextServiceDate != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext, 'clear'),
                  style:
                      TextButton.styleFrom(foregroundColor: AppColors.danger),
                  child: const Text('Remove scheduled service'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (choice == null || !context.mounted) return;

    DateTime? date;
    if (choice is int) {
      date = _plusMonths(choice);
    } else if (choice == 'pick') {
      date = await showDatePicker(
        context: context,
        initialDate: product.nextServiceDate ?? _plusMonths(1),
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime(2100),
      );
      if (date == null) return;
    }
    if (!context.mounted) return;
    final updated = product.copy()..nextServiceDate = date;
    await _save(context, updated,
        success: date == null
            ? 'Scheduled service removed'
            : 'Service scheduled for ${ProductUtils.formatDate(date)}');
  }

  Future<void> _addRecord(BuildContext context) async {
    final record = await showModalBottomSheet<ServiceRecord>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ServiceRecordSheet(),
    );
    if (record == null || !context.mounted) return;
    final updated = product.copy()
      ..serviceHistory.insert(0, record)
      ..serviceHistory.sort((a, b) => b.date.compareTo(a.date));
    await _save(context, updated, success: 'Service record added');
  }

  Future<void> _deleteRecord(BuildContext context, int index) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete record?',
      message: '"${product.serviceHistory[index].title}" will be removed.',
      confirmLabel: 'Delete',
      icon: Icons.delete_rounded,
    );
    if (!ok || !context.mounted) return;
    final updated = product.copy()..serviceHistory.removeAt(index);
    await _save(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    final status = product.serviceStatus;
    final history = product.serviceHistory;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Service & maintenance',
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
            trailing: product.maintenanceCost > 0
                ? '${ProductUtils.formatMoney(product.maintenanceCost)} spent'
                : null,
          ),
          DepthCard(
            onTap: () => _schedule(context),
            tilt: false,
            depth: 0.6,
            glow: status == ServiceStatus.none ? null : status.color,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                IconOrb(
                  icon: Icons.event_repeat_rounded,
                  color: status == ServiceStatus.none
                      ? AppColors.info
                      : status.color,
                  size: 44,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.nextServiceDate == null
                            ? 'Schedule next service'
                            : product.serviceLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: status == ServiceStatus.overdue
                              ? AppColors.danger
                              : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.nextServiceDate == null
                            ? 'Get a reminder when it\'s due'
                            : ProductUtils.formatDate(product.nextServiceDate!),
                        style:
                            TextStyle(fontSize: 12.5, color: context.textMuted),
                      ),
                    ],
                  ),
                ),
                Icon(
                    product.nextServiceDate == null
                        ? Icons.add_circle_rounded
                        : Icons.edit_calendar_rounded,
                    color: AppColors.primary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          DepthCard(
            depth: 0.6,
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      history.isEmpty
                          ? 'Service history'
                          : 'Service history · ${history.length}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _addRecord(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                if (history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 8, 10),
                    child: Text(
                      'Log repairs, cleanings and filter changes to keep a full record for warranty claims and resale.',
                      style: TextStyle(
                          color: context.textMuted, height: 1.4, fontSize: 13),
                    ),
                  )
                else
                  for (var i = 0; i < history.length; i++)
                    _RecordTile(
                      record: history[i],
                      isLast: i == history.length - 1,
                      onLongPress: () => _deleteRecord(context, i),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final ServiceRecord record;
  final bool isLast;
  final VoidCallback onLongPress;

  const _RecordTile({
    required this.record,
    required this.isLast,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final details = [
      DateFormat.yMMMd().format(record.date),
      if (record.provider != null) record.provider!,
    ].join(' · ');
    return InkWell(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress();
      },
      borderRadius: BorderRadius.circular(12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                const SizedBox(height: 14),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: context.outline)),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(details,
                        style:
                            TextStyle(fontSize: 12, color: context.textMuted)),
                    if (record.notes != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(record.notes!,
                            style: TextStyle(
                                fontSize: 12.5, color: context.textMuted)),
                      ),
                  ],
                ),
              ),
            ),
            if (record.cost != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 6),
                child: Text(ProductUtils.formatMoney(record.cost!),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
          ],
        ),
      ),
    );
  }
}

class _ServiceRecordSheet extends StatefulWidget {
  const _ServiceRecordSheet();

  @override
  State<_ServiceRecordSheet> createState() => _ServiceRecordSheetState();
}

class _ServiceRecordSheetState extends State<_ServiceRecordSheet> {
  final _title = TextEditingController();
  final _cost = TextEditingController();
  final _provider = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();
  String _error = '';

  static const _suggestions = [
    'General service',
    'Repair',
    'Cleaning',
    'Filter change',
    'Gas refill',
    'Part replaced',
  ];

  @override
  void dispose() {
    for (final c in [_title, _cost, _provider, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final costText = _cost.text.trim().replaceAll(',', '');
    final cost = costText.isEmpty ? null : double.tryParse(costText);
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'What was done? Pick or type a title.');
      return;
    }
    if (costText.isNotEmpty && (cost == null || cost < 0)) {
      setState(() => _error = 'Please enter a valid cost');
      return;
    }
    String? opt(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    Navigator.pop(
      context,
      ServiceRecord(
        date: _date,
        title: _title.text.trim(),
        cost: cost,
        provider: opt(_provider),
        notes: opt(_notes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SheetFrame(
        title: 'Add service record',
        subtitle: 'Repairs, cleaning, maintenance',
        icon: Icons.build_rounded,
        color: AppColors.secondary,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              20, 8, 20, 20 + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in _suggestions)
                    ChoiceChip(
                      label: Text(s),
                      selected: _title.text == s,
                      onSelected: (_) => setState(() {
                        _title.text = s;
                        _error = '';
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() => _error = ''),
                decoration: const InputDecoration(
                    hintText: 'What was done?',
                    prefixIcon: Icon(Icons.build_rounded)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DepthCard(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) setState(() => _date = d);
                      },
                      tilt: false,
                      depth: 0.4,
                      radius: 16,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.event_rounded,
                              size: 20, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(DateFormat.yMMMd().format(_date),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _cost,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          hintText: 'Cost',
                          prefixIcon: Icon(Icons.payments_rounded)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _provider,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    hintText: 'Technician / company (optional)',
                    prefixIcon: Icon(Icons.engineering_rounded)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notes,
                maxLines: 2,
                decoration: const InputDecoration(hintText: 'Notes (optional)'),
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(_error,
                    style: const TextStyle(
                        color: AppColors.danger, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 18),
              Button3D(
                label: 'Save Record',
                icon: Icons.check_rounded,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
