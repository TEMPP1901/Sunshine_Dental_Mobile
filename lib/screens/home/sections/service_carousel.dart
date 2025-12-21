import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

class ServiceCarousel extends StatelessWidget {
  const ServiceCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Dữ liệu tĩnh (Hardcode)
    final List<Map<String, dynamic>> services = [
      {
        'name': 'home.service.ortho'.tr(), // "Niềng răng"
        'icon': '🦷',
        'color': const Color(0xFFE3F2FD),
        'desc': 'home.service.orthoDesc'.tr(), // "Chỉnh nha thẩm mỹ"
      },
      {
        'name': 'home.service.porcelain'.tr(), // "Bọc sứ"
        'icon': '✨',
        'color': const Color(0xFFFFF3E0),
        'desc': 'home.service.porcelainDesc'.tr(), // "Răng trắng sáng"
      },
      {
        'name': 'home.service.implant'.tr(), // "Trồng Implant"
        'icon': '🔩',
        'color': const Color(0xFFE8F5E9),
        'desc': 'home.service.implantDesc'.tr(), // "Phục hồi mất răng"
      },
      {
        'name': 'home.service.whitening'.tr(), // "Tẩy trắng"
        'icon': '💎',
        'color': const Color(0xFFF3E5F5),
        'desc': 'home.service.whiteningDesc'.tr(), // "Nụ cười rạng rỡ"
      },
      {
        'name': 'home.service.extraction'.tr(), // "Nhổ răng"
        'icon': '💉',
        'color': const Color(0xFFFFEBEE),
        'desc': 'home.service.extractionDesc'.tr(), // "Không đau"
      },
    ];

    return SizedBox(
      height: 140, // Chiều cao đủ cho Card
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final s = services[index];
          return Container(
            width: 110, // Chiều rộng mỗi card
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  context.push('/products');
                  Fluttertoast.showToast(msg: "Đã chọn: ${s['name']}");
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: s['color'],
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          s['icon'],
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        s['name'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: const Color(0xFF0D1B3E), // Màu chữ đậm
                        ),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s['desc'],
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
