
class OrderItem {
  final String id;
  final String productTitle;
  final String category;
  final String requestTitle;
  final String genre;
  final String reference;
  final String status;
  final DateTime createdAt;

  OrderItem({
    required this.id,
    required this.productTitle,
    required this.category,
    required this.requestTitle,
    required this.genre,
    required this.reference,
    this.status = 'Menunggu Penjual',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class OrderData {
  static final List<OrderItem> orders = [];

  static void addOrder(OrderItem order) {
    orders.insert(0, order);
  }
}