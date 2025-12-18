import 'package:flutter/material.dart';
import '../../models/huybro_products/product_model.dart';
import '../../services/huybro_products/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _service = ProductService();

  // --- STATE DANH SÁCH ---
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Phân trang
  int _currentPage = 0;
  bool _isLastPage = false;

  // --- STATE BỘ LỌC (Filter & Sort) ---
  String _keyword = '';
  String _sortBy = 'defaultRetailPrice'; // Mặc định sắp xếp theo giá
  String _order = 'asc';                 // Mặc định tăng dần

  // Bộ lọc nâng cao (Brand, Type, Price Range)
  List<String> _filterBrands = [];
  List<String> _filterTypes = [];
  double? _filterMinPrice;
  double? _filterMaxPrice;

  // --- STATE CHI TIẾT ---
  ProductModel? _selectedProduct;
  bool _isDetailLoading = false;

  // --- NEW: STATE CHO SẢN PHẨM MỚI (Ở Detail) ---
  List<ProductModel> _newArrivals = [];
  bool _isNewArrivalsLoading = false;

  // ===========================================================================
  // GETTERS (BỔ SUNG ĐỂ UI ĐỌC DỮ LIỆU)
  // ===========================================================================
  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  ProductModel? get selectedProduct => _selectedProduct;
  bool get isDetailLoading => _isDetailLoading;

  List<ProductModel> get newArrivals => _newArrivals;

  // [BỔ SUNG] Getter cho Filter để UI highlight được item đang chọn
  String get sortBy => _sortBy;
  String get order => _order;
  List<String> get filterBrands => _filterBrands;
  List<String> get filterTypes => _filterTypes;

  // ===========================================================================
  // 1. HÀM FETCH DANH SÁCH (QUAN TRỌNG)
  // ===========================================================================
  Future<void> fetchProducts({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 0;
      _products.clear();
      _isLastPage = false;
      _errorMessage = '';
    }

    if (_isLastPage) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Gọi Service với đầy đủ tham số bộ lọc
      final response = await _service.getProducts(
        page: _currentPage,
        size: 8,
        keyword: _keyword,
        sortBy: _sortBy,
        order: _order,
        brands: _filterBrands,
        types: _filterTypes,
        minPrice: _filterMinPrice,
        maxPrice: _filterMaxPrice,
      );

      _products.addAll(response.content);
      _isLastPage = response.last;
      _currentPage++;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Lỗi fetchProducts: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // 2. CÁC HÀM SETTER & LOGIC BỘ LỌC (ĐÃ BỔ SUNG ĐẦY ĐỦ)
  // ===========================================================================

  // Tìm kiếm theo từ khóa
  void setKeyword(String val) {
    _keyword = val;
    fetchProducts(isRefresh: true);
  }

  // Sắp xếp
  void setSort(String field, String order) {
    _sortBy = field;
    _order = order;
    fetchProducts(isRefresh: true);
  }

  // [BỔ SUNG] Logic chọn/bỏ chọn 1 Brand (Toggle)
  void toggleBrand(String brand) {
    if (_filterBrands.contains(brand)) {
      _filterBrands.remove(brand);
    } else {
      _filterBrands.add(brand);
    }
    fetchProducts(isRefresh: true);
  }

  // [BỔ SUNG] Logic chọn/bỏ chọn 1 Type (Toggle)
  void toggleType(String type) {
    if (_filterTypes.contains(type)) {
      _filterTypes.remove(type);
    } else {
      _filterTypes.add(type);
    }
    fetchProducts(isRefresh: true);
  }

  // [BỔ SUNG] Xóa bộ lọc theo loại
  void clearFilter(String filterType) {
    if (filterType == 'brand') {
      _filterBrands.clear();
    } else if (filterType == 'type') {
      _filterTypes.clear();
    }
    fetchProducts(isRefresh: true);
  }

  // [BỔ SUNG] Reset toàn bộ bộ lọc về mặc định
  void resetFilters() {
    _keyword = '';
    _sortBy = 'defaultRetailPrice';
    _order = 'asc';
    _filterBrands.clear();
    _filterTypes.clear();
    _filterMinPrice = null;
    _filterMaxPrice = null;
    fetchProducts(isRefresh: true);
  }

  // Áp dụng bộ lọc nâng cao (Set 1 lần nhiều giá trị - dùng cho nút Apply)
  void applyFilters({
    List<String>? brands,
    List<String>? types,
    double? min,
    double? max,
  }) {
    if (brands != null) _filterBrands = brands;
    if (types != null) _filterTypes = types;
    _filterMinPrice = min;
    _filterMaxPrice = max;
    fetchProducts(isRefresh: true);
  }

  // ===========================================================================
  // 3. HÀM FETCH CHI TIẾT
  // ===========================================================================
  Future<void> fetchProductDetail(int id) async {
    _isDetailLoading = true;
    _selectedProduct = null;
    _errorMessage = '';
    notifyListeners();

    try {
      _selectedProduct = await _service.getProductById(id);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Lỗi fetchProductDetail: $e");
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // 4. HÀM FETCH SẢN PHẨM MỚI (CHO DETAIL)
  // ===========================================================================
  Future<void> fetchNewArrivals() async {
    if (_newArrivals.isNotEmpty) return;

    _isNewArrivalsLoading = true;
    notifyListeners();

    try {
      final response = await _service.getProducts(
        page: 0,
        size: 5,
        sortBy: 'createdAt',
        order: 'desc',
      );
      _newArrivals = response.content;
    } catch (e) {
      debugPrint("Lỗi fetchNewArrivals: $e");
    } finally {
      _isNewArrivalsLoading = false;
      notifyListeners();
    }
  }
}