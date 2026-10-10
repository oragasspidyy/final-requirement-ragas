import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../theme.dart';

final peso = NumberFormat.currency(locale: 'en_US', symbol: '₱', decimalDigits: 2);
final pesoShort = NumberFormat.currency(locale: 'en_US', symbol: '₱', decimalDigits: 0);

String fmtDate(DateTime d) => DateFormat('MMM d, y').format(d);
String fmtShort(DateTime d) => DateFormat('MMM d').format(d);
String fmtDay(DateTime d) => DateFormat('EEE, MMM d').format(d);
String fmtNumeric(DateTime d) => DateFormat('MM/dd/yyyy').format(d);

void showSnack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? AppColors.danger : AppColors.ink,
    ));
}

/// Round pet picture: uploaded photo, or a species illustration.
class PetAvatar extends StatelessWidget {
  const PetAvatar({super.key, required this.pet, this.size = 56});
  final Pet? pet;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bytes = pet?.photoBytes;
    final ImageProvider image = bytes != null
        ? MemoryImage(bytes)
        : AssetImage(pet?.defaultAsset ?? 'assets/images/pet_other.png')
            as ImageProvider;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
        image: DecorationImage(image: image, fit: BoxFit.cover),
      ),
    );
  }
}

/// Pill-shaped status badge (Pending / Confirmed / Completed / Cancelled ...).
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    BorderSide? side;
    TextDecoration? deco;
    String label = status;
    switch (status.toLowerCase()) {
      case 'confirmed':
        bg = AppColors.primary;
        fg = Colors.white;
        label = 'Confirmed';
        break;
      case 'completed':
        bg = const Color(0xFFDCFCE7);
        fg = AppColors.success;
        label = 'Completed';
        break;
      case 'cancelled':
        bg = const Color(0xFFF3F4F6);
        fg = AppColors.muted;
        deco = TextDecoration.lineThrough;
        label = 'Cancelled';
        break;
      case 'due soon':
        bg = AppColors.warning;
        fg = Colors.white;
        label = 'Due soon';
        break;
      case 'overdue':
        bg = AppColors.danger;
        fg = Colors.white;
        label = 'Overdue';
        break;
      case 'up to date':
        bg = const Color(0xFFDCFCE7);
        fg = AppColors.success;
        label = 'Up to date';
        break;
      case 'pending':
        bg = const Color(0xFFFFF7E6);
        fg = const Color(0xFFB45309);
        side = const BorderSide(color: Color(0xFFFCD34D));
        label = 'Pending';
        break;
      default:
        bg = const Color(0xFFF3F4F6);
        fg = AppColors.ink;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: side == null ? null : Border.fromBorderSide(side),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          decoration: deco,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.onSeeAll});
  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: const Text('See all',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 14),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primaryLight,
            child: Icon(icon, size: 34, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(title,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted)),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

/// A tappable field that opens a date picker.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.hint = 'Select date',
    this.validator,
    this.clearable = false,
  });
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime firstDate;
  final DateTime lastDate;
  final String hint;
  final String? Function(DateTime?)? validator;
  final bool clearable;

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      initialValue: value,
      // validate against the latest value passed in by the parent
      validator: validator == null ? null : (_) => validator!(value),
      builder: (state) {
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final now = DateTime.now();
            DateTime initial = value ?? now;
            if (initial.isBefore(firstDate)) initial = firstDate;
            if (initial.isAfter(lastDate)) initial = lastDate;
            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: firstDate,
              lastDate: lastDate,
            );
            if (picked != null) {
              state.didChange(picked);
              onChanged(picked);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              errorText: state.errorText,
              suffixIcon: clearable && value != null
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        state.didChange(null);
                        onChanged(null);
                      },
                    )
                  : const Icon(Icons.calendar_month_outlined),
            ),
            child: Text(
              value == null ? hint : fmtNumeric(value!),
              style: TextStyle(
                fontSize: 16,
                color: value == null ? AppColors.muted : AppColors.ink,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Dashed-line separated label/value rows used on confirm & success screens.
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.trailing, this.last = false});
  final String label;
  final String value;
  final Widget? trailing;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 15)),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: trailing ??
                  Text(value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Yes',
  bool destructive = false,
}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No')),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: AppColors.danger)
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return res ?? false;
}

/// Dropdown styled like the text fields. Uses a plain [DropdownButton]
/// inside a [FormField] so it works the same on every Flutter version.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelOf,
    this.hint = 'Select',
    this.validator,
  });
  final T? value;
  final List<T> items;
  final ValueChanged<T?>? onChanged;
  final String Function(T)? labelOf;
  final String hint;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: value,
      validator: validator == null ? null : (_) => validator!(value),
      builder: (state) => InputDecorator(
        decoration: InputDecoration(
          errorText: state.errorText,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: items.contains(value) ? value : null,
            isExpanded: true,
            hint: Text(hint, style: const TextStyle(color: AppColors.muted)),
            borderRadius: BorderRadius.circular(14),
            items: [
              for (final e in items)
                DropdownMenuItem<T>(
                  value: e,
                  child: Text(labelOf?.call(e) ?? e.toString(),
                      overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: onChanged == null
                ? null
                : (v) {
                    state.didChange(v);
                    onChanged!(v);
                  },
          ),
        ),
      ),
    );
  }
}
