import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/pos_theme.dart';

class PosCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? color;

  const PosCard(
      {super.key, required this.child, this.padding, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color ?? PosTheme.cardColor,
          borderRadius: BorderRadius.circular(PosTheme.borderRadius),
          border: Border.all(color: const Color(0xFF333333), width: 0.5),
        ),
        padding: padding ?? const EdgeInsets.all(PosTheme.cardPadding),
        child: child,
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  final String? label;

  const StatusBadge({super.key, required this.status, this.label});

  @override
  Widget build(BuildContext context) {
    final text = label ?? status.toUpperCase();
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'completed':
        bg = const Color(0xFF22C55E).withValues(alpha: 0.15);
        fg = const Color(0xFF22C55E);
        break;
      case 'pending':
        bg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        fg = const Color(0xFFF59E0B);
        break;
      case 'cancelled':
        bg = const Color(0xFFEF4444).withValues(alpha: 0.15);
        fg = const Color(0xFFEF4444);
        break;
      case 'active':
        bg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        fg = const Color(0xFFF59E0B);
        break;
      case 'free':
        bg = const Color(0xFF22C55E).withValues(alpha: 0.15);
        fg = const Color(0xFF22C55E);
        break;
      default:
        bg = PosTheme.surfaceColor;
        fg = PosTheme.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style:
              TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class PriceText extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final bool bold;

  const PriceText(
      {super.key, required this.amount, this.style, this.bold = true});

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
    return Text(
      f.format(amount),
      style: (style ??
              const TextStyle(
                  fontSize: 14,
                  color: PosTheme.textPrimary,
                  fontFamily: 'Roboto'))
          .copyWith(
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const SearchField(
      {super.key, required this.hintText, this.onChanged, this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: PosTheme.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: PosTheme.textMuted, fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded,
            color: PosTheme.textMuted, size: 20),
        suffixIconColor: PosTheme.textMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }
}

class PosButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isOutlined;
  final bool isSmall;

  const PosButton({
    super.key,
    required this.label,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.isOutlined = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? PosTheme.primaryColor;
    final effectiveFg = foregroundColor ?? Colors.white;
    final padding = isSmall
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: effectiveFg,
          side: BorderSide(color: effectiveBg),
          padding: padding,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PosTheme.borderRadiusSmall)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: isSmall ? 12 : 13, fontWeight: FontWeight.w600)),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: effectiveBg,
        foregroundColor: effectiveFg,
        padding: padding,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PosTheme.borderRadiusSmall)),
        elevation: 0,
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: isSmall ? 12 : 13, fontWeight: FontWeight.w700)),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;

  const SectionHeader(
      {super.key, required this.title, this.actionText, this.onActionTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PosTheme.spacingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: PosTheme.textPrimary)),
          if (actionText != null && onActionTap != null)
            TextButton(
                onPressed: onActionTap,
                child: Text(actionText!,
                    style: const TextStyle(
                        color: PosTheme.primaryColor, fontSize: 13))),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtext;
  final Color? accentColor;

  const MetricCard(
      {super.key,
      required this.label,
      required this.value,
      this.subtext,
      this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PosTheme.cardColor,
        borderRadius: BorderRadius.circular(PosTheme.borderRadius),
        border: Border.all(color: const Color(0xFF333333), width: 0.5),
      ),
      padding: const EdgeInsets.all(PosTheme.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: PosTheme.textSecondary,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: accentColor ?? PosTheme.textPrimary,
                fontFamily: 'Roboto'),
          ),
          if (subtext != null) ...[
            const SizedBox(height: 2),
            Text(subtext!,
                style:
                    const TextStyle(fontSize: 11, color: PosTheme.textMuted)),
          ],
        ],
      ),
    );
  }
}

class PosFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const PosFilterChip(
      {super.key, required this.label, required this.isSelected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? PosTheme.primaryColor : PosTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color:
                  isSelected ? PosTheme.primaryColor : const Color(0xFF444444),
              width: 0.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : PosTheme.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_rounded,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: PosTheme.textMuted),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: PosTheme.textSecondary)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 13, color: PosTheme.textMuted)),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(actionText!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PosTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(PosTheme.borderRadiusSmall),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
