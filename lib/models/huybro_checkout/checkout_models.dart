// 1. Request gửi lên BE khi tạo hóa đơn (COD) hoặc Capture (Online)
class CheckoutRequestModel {
  String paymentType;    // "COD" hoặc "BANK_TRANSFER"
  String? paymentChannel; // "PAYPAL", "VNPAY", "CASH_ON_DELIVERY"
  String currency;       // "USD" hoặc "VND"
  String customerFullName;
  String customerEmail;
  String customerPhone;
  String shippingAddress;
  String? note;

  CheckoutRequestModel({
    required this.paymentType,
    this.paymentChannel,
    required this.currency,
    required this.customerFullName,
    required this.customerEmail,
    required this.customerPhone,
    required this.shippingAddress,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'paymentType': paymentType,
      'paymentChannel': paymentChannel,
      'currency': currency,
      'customerFullName': customerFullName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'shippingAddress': shippingAddress,
      'note': note,
    };
  }
}

// 2. Response sau khi tạo hóa đơn thành công
class CheckoutInvoiceModel {
  final int invoiceId;
  final String invoiceCode;
  final String paymentStatus; // "PENDING", "PAID"
  final double totalAmount;

  CheckoutInvoiceModel({
    required this.invoiceId,
    required this.invoiceCode,
    required this.paymentStatus,
    required this.totalAmount,
  });

  factory CheckoutInvoiceModel.fromJson(Map<String, dynamic> json) {
    return CheckoutInvoiceModel(
      invoiceId: json['invoiceId'],
      invoiceCode: json['invoiceCode'],
      paymentStatus: json['paymentStatus'] ?? 'PENDING',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
    );
  }
}

// 3. Thông tin liên hệ lấy từ User (Contact Info)
class ContactInfoModel {
  final String fullName;
  final String email;
  final String phone;

  ContactInfoModel({required this.fullName, required this.email, required this.phone});

  factory ContactInfoModel.fromJson(Map<String, dynamic> json) {
    return ContactInfoModel(
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}