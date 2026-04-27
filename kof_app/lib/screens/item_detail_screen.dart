import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/menu_item.dart';
import '../models/menu_item_size.dart';
import '../providers/cart_provider.dart';
import '../utils/menu_item_image.dart';

class ItemDetailScreen extends StatefulWidget {
  final MenuItem item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late MenuItemSize? _selectedSize;
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    _selectedSize = widget.item.hasSizes
        ? widget.item.sizes.firstWhere(
            (s) => s.name == kDefaultSizeName,
            orElse: () => widget.item.sizes.first,
          )
        : null;
  }

  int get _unitPriceCents =>
      widget.item.priceCents + (_selectedSize?.priceCentsDelta ?? 0);

  int get _totalPriceCents => _unitPriceCents * _qty;

  void _addToCartAndClose() {
    context.read<CartProvider>().add(
          widget.item,
          size: _selectedSize,
          qty: _qty,
        );
    Navigator.pop(context);
  }

  String _localizedSizeLabel(AppLocalizations l10n, String sizeName) {
    return switch (sizeName) {
      'Small' => l10n.sizeSmall,
      'Medium' => l10n.sizeMedium,
      'Large' => l10n.sizeLarge,
      'Xtra Large' => l10n.sizeXtraLarge,
      _ => sizeName,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final item = widget.item;
    final imagePath = imageAssetForItem(item.name);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          // Hero header — green panel with cup illustration
          _HeroHeader(
            imagePath: imagePath,
            fallbackIcon: iconForMenuItem(
              name: item.name,
              category: item.category,
            ),
          ),

          // Back button overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: _CircleIconButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
              tooltip: l10n.itemDetailBack,
            ),
          ),

          // Bottom sheet-style content panel
          DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.55,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // drag handle
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        children: [
                          Text(
                            item.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (item.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              item.description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.65),
                                height: 1.4,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),

                          if (item.hasSizes && item.sizes.isNotEmpty) ...[
                            Text(
                              l10n.itemDetailSize,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _SizeSelector(
                              sizes: item.sizes,
                              selected: _selectedSize,
                              labelFor: (s) => _localizedSizeLabel(l10n, s.name),
                              onChanged: (s) => setState(() => _selectedSize = s),
                            ),
                            const SizedBox(height: 24),
                          ],

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.itemDetailQuantity,
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.55),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '€${(_totalPriceCents / 100).toStringAsFixed(2)}',
                                    style:
                                        theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              _QtyStepper(
                                value: _qty,
                                onChanged: (v) => setState(() => _qty = v),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          if (!item.isOrderable)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  l10n.itemDetailUnavailable,
                                  style: TextStyle(
                                    color: theme.colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _addToCartAndClose,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  l10n.itemDetailAddToCart,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final String? imagePath;
  final IconData fallbackIcon;
  const _HeroHeader({this.imagePath, this.fallbackIcon = Icons.coffee});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Center(
        child: imagePath != null
            ? Image.asset(
                imagePath!,
                fit: BoxFit.contain,
                height: 460,
                errorBuilder: (_, _, _) => Icon(
                  fallbackIcon,
                  color: Colors.white,
                  size: 220,
                ),
              )
            : Icon(fallbackIcon, color: Colors.white, size: 220),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.95),
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, color: Colors.black87),
      ),
    );
  }
}

class _SizeSelector extends StatelessWidget {
  final List<MenuItemSize> sizes;
  final MenuItemSize? selected;
  final ValueChanged<MenuItemSize> onChanged;
  final String Function(MenuItemSize) labelFor;

  const _SizeSelector({
    required this.sizes,
    required this.selected,
    required this.onChanged,
    required this.labelFor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: sizes.map((s) {
        final isSel = selected?.name == s.name;
        return GestureDetector(
          onTap: () => onChanged(s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isSel
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSel
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  labelFor(s),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSel
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                if (s.priceCentsDelta != 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    s.priceCentsDelta > 0
                        ? '+€${(s.priceCentsDelta / 100).toStringAsFixed(2)}'
                        : '-€${(s.priceCentsDelta.abs() / 100).toStringAsFixed(2)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSel
                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.85)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _QtyStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoundBtn(
            icon: Icons.remove,
            onTap: value > 1 ? () => onChanged(value - 1) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              '$value',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          _RoundBtn(
            icon: Icons.add,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RoundBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: enabled
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface.withValues(alpha: 0.4),
          size: 18,
        ),
      ),
    );
  }
}
