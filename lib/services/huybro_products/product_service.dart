// ApiService
import '../../models/huybro_products/product_model.dart';
import '../api_service.dart';

class ProductService {
  final ApiService _apiService = ApiService();

  Future<ProductPageResponse> getProducts({
    int page = 0,
    int size = 8,
    String? keyword,
    String? sortBy,
    String? order,
    // --- BỘ LỌC TỪ API ---
    List<String>? brands,
    List<String>? types,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'page': page,
        'size': size,
        'sortBy': sortBy ?? 'name',
        'order': order ?? 'asc',
      };

      if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;
      if (minPrice != null) params['minPrice'] = minPrice;
      if (maxPrice != null) params['maxPrice'] = maxPrice;

      // Spring Boot nhận List param dạng: brand=A&brand=B
      // Dio hỗ trợ tốt việc này nếu value là List
      if (brands != null && brands.isNotEmpty) params['brand'] = brands;
      if (types != null && types.isNotEmpty) params['type'] = types;

      final response = await _apiService.get(
        '/api/products/page',
        queryParameters: params,
      );

      return ProductPageResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Lỗi tải danh sách sản phẩm: $e');
    }
  }

  Future<ProductModel> getProductById(int id) async {
    try {
      final response = await _apiService.get('/api/products/$id');
      return ProductModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Lỗi tải chi tiết: $e');
    }
  }
}
