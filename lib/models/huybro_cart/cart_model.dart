class CartModel {
  final List<CartItemModel> items;
  final CartTotalsModel totals;
  final String invoiceCode;
  final String currency;
  final double? exchangeRateToVnd;

  CartModel({
    required this.items,
    required this.totals,
    required this.invoiceCode,
    required this.currency,
    this.exchangeRateToVnd,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      items: (json['items'] as List?)?.map((e) => CartItemModel.fromJson(e)).toList() ?? [],
      totals: CartTotalsModel.fromJson(json['totals'] ?? {}),
      invoiceCode: json['invoiceCode'] ?? '',
      currency: json['currency'] ?? 'USD',
      exchangeRateToVnd: json['exchangeRateToVnd'],
    );
  }
}

class CartItemModel {
  final int productId;
  final String sku;
  final String productName;
  final String brand;
  final String? mainImageUrl;
  final int quantity;

  // Giá trị tiền tệ
  final double unitPriceBeforeTax;
  final double taxRatePercent;
  final double taxAmount;
  final double unitPriceAfterTax;
  final double lineTotalAmount;
  final String currency;

  CartItemModel({
    required this.productId,
    required this.sku,
    required this.productName,
    required this.brand,
    this.mainImageUrl,
    required this.quantity,
    required this.unitPriceBeforeTax,
    required this.taxRatePercent,
    required this.taxAmount,
    required this.unitPriceAfterTax,
    required this.lineTotalAmount,
    required this.currency,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      productId: json['productId'],
      sku: json['sku'] ?? 'N/A',
      productName: json['productName'] ?? '',
      brand: json['brand'] ?? '',
      mainImageUrl: json['mainImageUrl'],
      quantity: json['quantity'] ?? 0,
      unitPriceBeforeTax: (json['unitPriceBeforeTax'] ?? 0).toDouble(),
      taxRatePercent: (json['taxRatePercent'] ?? 0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      unitPriceAfterTax: (json['unitPriceAfterTax'] ?? 0).toDouble(),
      lineTotalAmount: (json['lineTotalAmount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
    );
  }
}

class CartTotalsModel {
  final double subTotalBeforeTax;
  final double totalAfterTax;

  CartTotalsModel({
    required this.subTotalBeforeTax,
    required this.totalAfterTax,
  });

  factory CartTotalsModel.fromJson(Map<String, dynamic> json) {
    return CartTotalsModel(
      subTotalBeforeTax: (json['subTotalBeforeTax'] ?? 0).toDouble(),
      totalAfterTax: (json['totalAfterTax'] ?? 0).toDouble(),
    );
  }
}