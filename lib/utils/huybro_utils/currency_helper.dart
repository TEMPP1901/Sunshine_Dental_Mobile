import 'package:intl/intl.dart';

class CurrencyHelper {
  // Nhận vào số tiền và mã tiền tệ
  static String format(double amount, String? currencyCode) {
    // Nếu là USD -> Format kiểu Mỹ ($)
    if (currencyCode != null && currencyCode.toUpperCase() == 'USD') {
      final format = NumberFormat.currency(locale: 'en_US', symbol: '\$');
      return format.format(amount);
    }

    // Mặc định là VND -> Format kiểu Việt (đ) và bỏ số thập phân
    final format = NumberFormat.currency(
        locale: 'vi_VN',
        symbol: 'đ',
        decimalDigits: 0
    );
    return format.format(amount);
  }
}