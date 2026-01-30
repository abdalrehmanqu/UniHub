class MarketplaceListing {
  const MarketplaceListing({
    required this.id,
    required this.sellerName,
    required this.title,
    required this.description,
    required this.price,
    required this.createdAt,
    this.sellerAvatarUrl,
    this.imageUrl,
    this.status,
    this.location,
  });

  final String id;
  final String sellerName;
  final String? sellerAvatarUrl;
  final String title;
  final String description;
  final double price;
  final String? imageUrl;
  final String? status;
  final String? location;
  final DateTime createdAt;

  factory MarketplaceListing.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final displayName = profile?['display_name']?.toString();
    final username = profile?['username']?.toString();
    final priceValue = json['price'];
    final price = priceValue is num
        ? priceValue.toDouble()
        : double.tryParse(priceValue?.toString() ?? '') ?? 0.0;
    final createdAtValue = json['created_at'];
    final createdAt = createdAtValue is String
        ? DateTime.parse(createdAtValue)
        : (createdAtValue as DateTime?) ?? DateTime.now();

    return MarketplaceListing(
      id: (json['id'] ?? '').toString(),
      sellerName: displayName?.isNotEmpty == true
          ? displayName!
          : (username?.isNotEmpty == true ? username! : 'Seller'),
      sellerAvatarUrl: profile?['avatar_url']?.toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: price,
      imageUrl: json['image_url']?.toString(),
      status: json['status']?.toString(),
      location: json['location']?.toString(),
      createdAt: createdAt,
    );
  }
}
