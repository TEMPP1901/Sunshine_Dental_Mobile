import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../services/api_service.dart';

class ServiceCarousel extends StatefulWidget {
  const ServiceCarousel({super.key});

  @override
  State<ServiceCarousel> createState() => _ServiceCarouselState();
}

class _ServiceCarouselState extends State<ServiceCarousel> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService().get('/api/products');
      final List<dynamic> products = response.data;

      final filteredProducts = products
          .where((p) => p['isActive'] == true)
          .take(8)
          .map((p) => p as Map<String, dynamic>)
          .toList();

      if (!mounted) return;
      setState(() {
        _products = filteredProducts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _products = [];
      });
    }
  }

  String _getImageUrl(Map<String, dynamic> product) {
    final images = product['image'];
    if (images != null && images is List && images.isNotEmpty) {
      final firstImage = images[0];
      if (firstImage is Map) {
        final imageUrl =
            firstImage['imageUrl']?.toString() ?? firstImage['url']?.toString();
        if (imageUrl != null && imageUrl.isNotEmpty) {
          return ApiService.resolveUrl(imageUrl);
        }
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return SizedBox(
        height: 110,
        child: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    if (_error != null || _products.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = _products[index];
          final productName = product['productName']?.toString() ?? 'Service';
          final imageUrl = _getImageUrl(product);

          return SizedBox(
            width: 100,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: InkWell(
                onTap: () {
                  Fluttertoast.showToast(msg: 'Selected $productName');
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: colorScheme.primaryContainer
                            .withOpacity(0.5),
                        backgroundImage: imageUrl.isNotEmpty
                            ? NetworkImage(
                                imageUrl,
                                headers: ApiService.authHeaders(),
                              )
                            : null,
                        child: imageUrl.isEmpty
                            ? Icon(
                                Icons.healing_outlined,
                                color: colorScheme.primary,
                                size: 22,
                              )
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Flexible(
                        child: Text(
                          productName,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                                fontSize: 11,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
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
