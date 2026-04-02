import 'package:flutter/material.dart';

import '../../../models/order.dart';
import '../../../services/nitaai_api.dart';
import '../../widgets/section_card.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({
    super.key,
    required this.api,
  });

  final NitaAiApi api;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: StreamBuilder<Order>(
        stream: api.watchCart(),
        builder: (context, snapshot) {
          final order = snapshot.data;
          final items = order?.items ?? const <OrderItem>[];
          final subtotal = items.fold<num>(0, (sum, item) => sum + item.lineTotal);
          final deliveryFee = items.isEmpty ? 0 : 40;
          final grandTotal = subtotal + deliveryFee;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: <Widget>[
              Text('Cart', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                api.isLive
                    ? 'This screen listens to your draft order from Firestore.'
                    : 'Demo order data is shown until Firebase credentials are added.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              if (items.isEmpty)
                const SectionCard(
                  child: _EmptyCart(),
                )
              else ...<Widget>[
                SectionCard(
                  child: Column(
                    children: items
                        .map((item) => _CartLine(item: item))
                        .expand((widget) => <Widget>[widget, const Divider(height: 24)])
                        .toList()
                      ..removeLast(),
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Delivery details', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 14),
                      _LabelValueRow(label: 'Address', value: order?.deliveryAddress ?? 'Add address'),
                      const SizedBox(height: 10),
                      _LabelValueRow(label: 'Notes', value: order?.notes ?? 'No delivery notes'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  child: Column(
                    children: <Widget>[
                      _LabelValueRow(label: 'Subtotal', value: 'Rs. ${subtotal.toStringAsFixed(0)}'),
                      const SizedBox(height: 10),
                      _LabelValueRow(label: 'Delivery fee', value: 'Rs. ${deliveryFee.toStringAsFixed(0)}'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(height: 1),
                      ),
                      _LabelValueRow(
                        label: 'Total',
                        value: 'Rs. ${grandTotal.toStringAsFixed(0)}',
                        emphasize: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => api.placeOrder(),
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: Text(order?.status == 'draft' ? 'Place order' : 'Order placed'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(58),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text('${item.quantity}x', style: theme.textTheme.titleMedium),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(item.name, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Rs. ${item.unitPrice.toStringAsFixed(0)} each',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text('Rs. ${item.lineTotal.toStringAsFixed(0)}', style: theme.textTheme.titleMedium),
      ],
    );
  }
}

class _LabelValueRow extends StatelessWidget {
  const _LabelValueRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: emphasize ? theme.textTheme.titleMedium : theme.textTheme.bodyLarge,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: emphasize
                ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
                : theme.textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: <Widget>[
        Icon(Icons.shopping_cart_checkout, size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text('Your cart is empty', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Add items to your draft order in Firestore and they will appear here automatically.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
