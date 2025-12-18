class ProductImage {
  final int imageId;
  final String imageUrl;
  final int imageOrder;

  ProductImage({
    required this.imageId,
    required this.imageUrl,
    required this.imageOrder,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      imageId: json['imageId'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      imageOrder: json['imageOrder'] ?? 0,
    );
  }
}

class ProductPurchaseHistory {
  final String customerName;
  final double price;
  final int quantity;
  final DateTime? purchaseDate;

  ProductPurchaseHistory({
    required this.customerName,
    required this.price,
    required this.quantity,
    this.purchaseDate,
  });

  factory ProductPurchaseHistory.fromJson(Map<String, dynamic> json) {
    return ProductPurchaseHistory(
      customerName: json['customerName'] ?? 'Khách hàng',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.tryParse(json['purchaseDate'])
          : null,
    );
  }
}

class ProductModel {
  final int productId;
  final String sku;
  final String productName;
  final String? brand;
  final String? productDescription;
  final int unit;
  final double defaultRetailPrice;
  final String currency; // Đã thêm lại trường này từ DTO
  final double? originalPrice;
  final double? discountPercentage;
  final int soldCount;
  final List<ProductImage> images; // List chứa đủ 3 ảnh
  final List<String> typeNames;
  final List<ProductPurchaseHistory> recentPurchases;
  final List<ProductModel> relatedProducts;

  ProductModel({
    required this.productId,
    required this.sku,
    required this.productName,
    this.brand,
    this.productDescription,
    required this.unit,
    required this.defaultRetailPrice,
    required this.currency,
    this.originalPrice,
    this.discountPercentage,
    required this.soldCount,
    required this.images,
    required this.typeNames,
    required this.recentPurchases,
    required this.relatedProducts,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // 1. Map & Sort Images (Quan trọng: Sort để ảnh 1, 2, 3 đúng thứ tự)
    var imgList = <ProductImage>[];
    if (json['image'] != null) {
      imgList = (json['image'] as List)
          .map((e) => ProductImage.fromJson(e))
          .toList();
      imgList.sort((a, b) => a.imageOrder.compareTo(b.imageOrder));
    }

    var relatedList = <ProductModel>[];
    if (json['relatedProducts'] != null) {
      relatedList = (json['relatedProducts'] as List)
          .map((e) => ProductModel.fromJson(e))
          .toList();
    }

    var historyList = <ProductPurchaseHistory>[];
    if (json['recentPurchases'] != null) {
      historyList = (json['recentPurchases'] as List)
          .map((e) => ProductPurchaseHistory.fromJson(e))
          .toList();
    }

    return ProductModel(
      productId: json['productId'],
      sku: json['sku'] ?? '',
      productName: json['productName'] ?? 'Sản phẩm',
      brand: json['brand'],
      productDescription: json['productDescription'],
      unit: json['unit'] ?? 0,
      defaultRetailPrice: (json['defaultRetailPrice'] ?? 0).toDouble(),
      // Mặc định VND nếu null
      currency: json['currency'] ?? 'VND',
      originalPrice: json['originalPrice'] != null
          ? (json['originalPrice']).toDouble()
          : null,
      discountPercentage: json['discountPercentage'] != null
          ? (json['discountPercentage']).toDouble()
          : null,
      soldCount: json['soldCount'] ?? 0,
      images: imgList,
      typeNames: json['typeNames'] != null
          ? List<String>.from(json['typeNames'])
          : [],
      recentPurchases: historyList,
      relatedProducts: relatedList,
    );
  }

  // Helper lấy ảnh đại diện (ảnh đầu tiên)
  String? get thumbnail {
    if (images.isEmpty) return null;
    return images.first.imageUrl;
  }
}

class ProductPageResponse {
  final List<ProductModel> content;
  final int totalPages;
  final bool last;

  ProductPageResponse({
    required this.content,
    required this.totalPages,
    required this.last,
  });

  factory ProductPageResponse.fromJson(Map<String, dynamic> json) {
    return ProductPageResponse(
      content: (json['content'] as List).map((e) => ProductModel.fromJson(e)).toList(),
      totalPages: json['totalPages'] ?? 0,
      last: json['last'] ?? true,
    );
  }
}