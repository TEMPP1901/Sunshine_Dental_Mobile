// FILE: lib/screens/huybro_products/widgets/product_filter_sheets.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ionicons/ionicons.dart';
import 'package:go_router/go_router.dart';

import '../../../../providers/huybro_products/product_provider.dart';
import '../../../../utils/huybro_utils/glass_theme.dart';

// --- WIDGET 1: SHEET CHỌN BRAND / TYPE ---
class FilterSelectionSheet extends StatelessWidget {
  final String title;
  final String filterType; // 'brand' hoặc 'type'

  const FilterSelectionSheet({
    super.key,
    required this.title,
    required this.filterType,
  });

  @override
  Widget build(BuildContext context) {
    // Dùng watch để UI cập nhật khi chọn/bỏ chọn
    final provider = context.watch<ProductProvider>();

    // 1. Lấy danh sách items có sẵn từ products hiện tại
    Set<String> items = {};
    if (filterType == 'brand') {
      items = provider.products
          .where((p) => p.brand != null)
          .map((p) => p.brand!)
          .toSet();
    } else {
      items = provider.products.expand((p) => p.typeNames).toSet();
    }

    // 2. Lấy danh sách đang được chọn để highlight
    final List<String> selectedItems = filterType == 'brand'
        ? provider.filterBrands
        : provider.filterTypes;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (selectedItems.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      provider.clearFilter(filterType);
                      context.pop();
                    },
                    child: const Text(
                      "Xóa chọn",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),

          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text("Không có dữ liệu lọc"),
            ),

          // List Items
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: items.map((item) {
                final isSelected = selectedItems.contains(item);
                return ListTile(
                  title: Text(
                    item,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? GlassTheme.primaryPurple
                          : Colors.black87,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Ionicons.checkmark_circle,
                          color: GlassTheme.primaryPurple,
                        )
                      : const Icon(
                          Ionicons.ellipse_outline,
                          color: Colors.grey,
                          size: 18,
                        ),
                  onTap: () {
                    // Logic chọn/bỏ chọn
                    if (filterType == 'brand') {
                      provider.toggleBrand(item);
                    } else {
                      provider.toggleType(item);
                    }
                    // Không pop để user có thể chọn nhiều cái, hoặc pop luôn tùy UX bạn muốn
                    // context.pop();
                  },
                );
              }).toList(),
            ),
          ),

          // Nút Đóng
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlassTheme.primaryPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => context.pop(),
                child: const Text(
                  "Xong",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET 2: SHEET SẮP XẾP ---
class SortSelectionSheet extends StatelessWidget {
  const SortSelectionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final currentSort = provider.sortBy;
    final currentOrder = provider.order;

    bool isSelected(String sort, String order) =>
        currentSort == sort && currentOrder == order;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Sắp xếp theo",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),

          _buildOption(
            context,
            "Giá: Thấp đến Cao",
            "defaultRetailPrice",
            "asc",
            isSelected("defaultRetailPrice", "asc"),
          ),
          _buildOption(
            context,
            "Giá: Cao đến Thấp",
            "defaultRetailPrice",
            "desc",
            isSelected("defaultRetailPrice", "desc"),
          ),
          _buildOption(
            context,
            "Tên: A - Z",
            "productName",
            "asc",
            isSelected("productName", "asc"),
          ), // Giả sử field tên là productName

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    String label,
    String field,
    String order,
    bool isActive,
  ) {
    return ListTile(
      leading: Icon(
        Ionicons.swap_vertical_outline,
        color: isActive ? GlassTheme.primaryPurple : Colors.grey,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? GlassTheme.primaryPurple : Colors.black87,
        ),
      ),
      trailing: isActive
          ? const Icon(Ionicons.checkmark, color: GlassTheme.primaryPurple)
          : null,
      onTap: () {
        Provider.of<ProductProvider>(
          context,
          listen: false,
        ).setSort(field, order);
        context.pop();
      },
    );
  }
}
