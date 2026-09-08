import 'menu_item.dart';

class OrderItem {
  final MenuItem menuItem;
  final int quantity;
  final String? note;

  OrderItem({
    required this.menuItem,
    required this.quantity,
    this.note,
  });

  double get totalPrice => menuItem.price * quantity;
}
