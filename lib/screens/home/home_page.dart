import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      final colorScheme = Theme.of(context).colorScheme;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      
      debugPrint(' [HomePage] Building with isDark: $isDark');
      debugPrint(' [HomePage] Background color: ${colorScheme.surfaceContainerLow}');
      
      return Scaffold(
        backgroundColor: isDark 
            ? const Color(0xFF1E1E1E)
            : colorScheme.surfaceContainerLow,
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Builder(
                      builder: (context) {
                        debugPrint(' [HomePage] Building _HeaderSection');
                        try {
                          return _HeaderSection();
                        } catch (e, stackTrace) {
                          debugPrint(' [HomePage] Error in _HeaderSection: $e');
                          return Container(
                            padding: const EdgeInsets.all(16),
                            child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    Builder(
                      builder: (context) {
                        debugPrint(' [HomePage] Building _PromoBanner');
                        try {
                          return const _PromoBanner();
                        } catch (e, stackTrace) {
                          debugPrint('[HomePage] Error in _PromoBanner: $e');
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    Builder(
                      builder: (context) {
                        debugPrint(' [HomePage] Building _SectionTitle (Services)');
                        try {
                          return _SectionTitle(
                            title: 'home.section.services'.tr(),
                            onSeeAll: () => Fluttertoast.showToast(msg: 'Navigating to Services'),
                          );
                        } catch (e, stackTrace) {
                          debugPrint(' [HomePage] Error in _SectionTitle (Services): $e');
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        debugPrint(' [HomePage] Building _ServiceCarousel');
                        try {
                          return const _ServiceCarousel();
                        } catch (e, stackTrace) {
                          debugPrint(' [HomePage] Error in _ServiceCarousel: $e');
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    Builder(
                      builder: (context) {
                        debugPrint(' [HomePage] Building _SectionTitle (Doctors)');
                        try {
                          return _SectionTitle(
                            title: 'home.section.availableDoctor'.tr(),
                            onSeeAll: () => Fluttertoast.showToast(msg: 'Navigating to Doctors'),
                          );
                        } catch (e, stackTrace) {
                          debugPrint(' [HomePage] Error in _SectionTitle (Doctors): $e');
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        debugPrint(' [HomePage] Building _DoctorCard');
                        try {
                          return const _DoctorCard();
                        } catch (e, stackTrace) {
                          debugPrint('[HomePage] Error in _DoctorCard: $e');
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                    const SizedBox(height: 28),
                    Builder(
                      builder: (context) {
                        debugPrint(' [HomePage] Building _TrustedByBanner');
                        try {
                          return const _TrustedByBanner();
                        } catch (e, stackTrace) {
                          debugPrint(' [HomePage] Error in _TrustedByBanner: $e');
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                    const SizedBox(height: 28),
                    Builder(
                      builder: (context) {
                        debugPrint(' [HomePage] Building _SectionTitle (MedicalRecord)');
                        try {
                          return _SectionTitle(
                            title: 'home.section.medicalRecord'.tr(),
                            onSeeAll: () => Fluttertoast.showToast(msg: 'Navigating to Records'),
                            showSeeAll: false,
                          );
                        } catch (e, stackTrace) {
                          debugPrint(' [HomePage] Error in _SectionTitle (MedicalRecord): $e');
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        debugPrint(' [HomePage] Building _MedicalRecordPreview');
                        try {
                          return const _MedicalRecordPreview();
                        } catch (e, stackTrace) {
                          debugPrint(' [HomePage] Error in _MedicalRecordPreview: $e');
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 16,
                child: Builder(
                  builder: (context) {
                    debugPrint(' [HomePage] Building _QuickActionsBar');
                    try {
                      return const _QuickActionsBar();
                    } catch (e, stackTrace) {
                      debugPrint(' [HomePage] Error in _QuickActionsBar: $e');
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('[HomePage] Error building widget: $e');
      debugPrint(' [HomePage] Stack trace: $stackTrace');
      // UI dự phòng khi gặp lỗi
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading home page: $e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Nhấn để thử tải lại
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

// HEADER SECTION: hiển thị thông tin người dùng và truy cập profile
class _HeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = context.watch<UserProvider>().user;
    final fullName = user?['fullName']?.toString();
    final avatarUrl = user?['avatarUrl']?.toString();
    final avatarImage = ApiService.resolveAvatarImage(avatarUrl);
    
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go('/profile'), // Đi đến trang Profile khi bấm vào avatar
          child: CircleAvatar(
            radius: 24,
            backgroundImage: avatarImage,
            backgroundColor: colorScheme.primaryContainer,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'home.greeting'.tr(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                fullName != null && fullName.isNotEmpty ? fullName : 'profile.guest'.tr(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onBackground,
                    ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          width: 48,
          child: Card(
            elevation: 3,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: colorScheme.surface,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  context.push('/notifications');
                },
                borderRadius: BorderRadius.circular(16),
                child: ValueListenableBuilder<int>(
                  valueListenable: NotificationService().unreadCount,
                  builder: (context, count, child) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          child: Icon(
                            Icons.notifications_none_rounded,
                            color: colorScheme.onSurface,
                            size: 24,
                          ),
                        ),
                        if (count > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 150),
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, -0.3),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOut,
                                    )),
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Text(
                                  count > 99 ? '99+' : count.toString(),
                                  key: ValueKey<int>(count),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// PROMO BANNER: hiển thị quảng cáo nổi bật
class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.secondary.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'home.promo.heading'.tr(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'home.promo.subtitle'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimary.withOpacity(0.9),
                        ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.onPrimary,
                      foregroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {},
                    child: Text(
                      'home.promo.button'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              height: 120,
              width: 80,
              child: Image.asset(
                'assets/images/hero-tooth.png',
                fit: BoxFit.contain,
                color: colorScheme.onPrimary.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// SECTION TITLE: tiêu đề từng mục với nút See All
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.onSeeAll, this.showSeeAll = true});

  final String title;
  final VoidCallback onSeeAll;
  final bool showSeeAll;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onBackground,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showSeeAll)
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                'common.seeAll'.tr(),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// SERVICE CAROUSEL: lấy danh sách dịch vụ nổi bật từ API và hiển thị ngang
class _ServiceCarousel extends StatefulWidget {
  const _ServiceCarousel();

  @override
  State<_ServiceCarousel> createState() => _ServiceCarouselState();
}

class _ServiceCarouselState extends State<_ServiceCarousel> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // Gọi API lấy danh sách dịch vụ
  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint(' [HomePage] Loading products...');
      final response = await ApiService().get('/api/products');
      final List<dynamic> products = response.data;
      
      // Lọc chỉ lấy sản phẩm đang hoạt động (isActive) và giới hạn hiển thị 8
      final filteredProducts = products
          .where((p) => p['isActive'] == true)
          .take(8)
          .map((p) => p as Map<String, dynamic>)
          .toList();

      if (!mounted) return;
      debugPrint(' [HomePage] Products loaded: ${filteredProducts.length}');
      setState(() {
        _products = filteredProducts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(' [HomePage] Error loading products: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _products = [];
      });
    }
  }

  // Lấy link ảnh đại diện dịch vụ
  String _getImageUrl(Map<String, dynamic> product) {
    final images = product['image'];
    if (images != null && images is List && images.isNotEmpty) {
      final firstImage = images[0];
      if (firstImage is Map) {
        final imageUrl = firstImage['imageUrl']?.toString() ?? firstImage['url']?.toString();
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
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            return SizedBox(
              width: 100,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    if (_error != null) {
      debugPrint(' [HomePage] ServiceCarousel error: $_error');
      return const SizedBox.shrink();
    }
    
    if (_products.isEmpty) {
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: InkWell(
                onTap: () {
                  Fluttertoast.showToast(msg: 'Selected $productName');
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: colorScheme.primaryContainer.withOpacity(0.5),
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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

// DOCTOR CARD: danh sách bác sĩ, có thể book lịch
class _DoctorCard extends StatefulWidget {
  const _DoctorCard();

  @override
  State<_DoctorCard> createState() => _DoctorCardState();
}

class _DoctorCardState extends State<_DoctorCard> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _schedules = [];
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
    _scrollController.addListener(_updateScrollButtons);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Cập nhật trạng thái có thể bấm nút cuộn trái/phải
  void _updateScrollButtons() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    setState(() {
      _canScrollLeft = position.pixels > 0;
      _canScrollRight = position.pixels < position.maxScrollExtent;
    });
  }

  // Di chuyển carousel sang trái
  void _scrollLeft() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.offset - 320,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Di chuyển carousel sang phải
  void _scrollRight() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.offset + 320,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Hiển thị dialog đặt lịch hẹn với bác sĩ
  void _showBookingDialog(BuildContext context, Map<String, dynamic> doctor, Map<String, dynamic> clinic, Map<String, dynamic> room) {
    final colorScheme = Theme.of(context).colorScheme;
    final doctorName = doctor['fullName']?.toString() ?? 'Doctor';
    final doctorId = doctor['id'] ?? doctor['userId'];
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.calendar_month, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'home.doctor.booking'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'home.doctor.bookingWith'.tr(args: [doctorName]),
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              if (clinic['name'] != null) ...[
                Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: colorScheme.tertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        clinic['name'].toString(),
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              Text(
                'home.doctor.bookingNote'.tr(),
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'common.cancel'.tr(),
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.go('/service');
                Fluttertoast.showToast(
                  msg: 'home.doctor.bookingRedirect'.tr(),
                  toastLength: Toast.LENGTH_SHORT,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('home.doctor.confirmBooking'.tr()),
            ),
          ],
        );
      },
    );
  }

  // Gọi API lấy danh sách bác sĩ, có fallback dùng API schedule nếu lỗi
  Future<void> _fetchDoctors() async {
    try {
      final response = await ApiService().get('/api/hr/employees/doctors');
      final data = response.data;
      
      if (data is List && data.isNotEmpty) {
        final doctorList = data.map((doctor) {
          final doctorMap = Map<String, dynamic>.from(doctor as Map);
          return {
            'doctor': {
              'id': doctorMap['id'],
              'fullName': doctorMap['fullName'] ?? '—',
              'avatarUrl': doctorMap['avatarUrl'],
            },
            'clinic': doctorMap['clinic'] ?? {},
            'room': {},
            'workDate': null,
            'startTime': null,
            'endTime': null,
          };
        }).toList();
        
        setState(() {
          _schedules = doctorList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'home.doctor.empty'.tr();
          _isLoading = false;
        });
      }
    } catch (e) {
      // Nếu gọi API doctors lỗi, thử gọi API schedules/current
      try {
        final scheduleResponse = await ApiService().get('/api/hr/schedules/current');
        final scheduleData = scheduleResponse.data;
        if (scheduleData is List && scheduleData.isNotEmpty) {
          // Lọc loại trùng lặp, chỉ lấy một lịch cho mỗi bác sĩ
          final Map<int, Map<String, dynamic>> uniqueDoctors = {};
          for (var schedule in scheduleData) {
            final scheduleMap = Map<String, dynamic>.from(schedule as Map);
            final doctor = scheduleMap['doctor'];
            if (doctor != null) {
              final doctorId = doctor['id'] ?? doctor['userId'];
              if (doctorId != null && !uniqueDoctors.containsKey(doctorId)) {
                uniqueDoctors[doctorId] = scheduleMap;
              }
            }
          }
          
          setState(() {
            _schedules = uniqueDoctors.values.toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'home.doctor.empty'.tr();
            _isLoading = false;
          });
        }
      } catch (scheduleError) {
        // Nếu cả hai API đều lỗi, hiển thị thông báo lỗi ra màn hình
        setState(() {
          _error = 'home.doctor.error'.tr();
          _isLoading = false;
        });
      }
    }
  }

  // Build từng ô thông tin bác sĩ
  Widget _buildDoctorCard(BuildContext context, Map<String, dynamic> schedule) {
    final colorScheme = Theme.of(context).colorScheme;
    final doctor = Map<String, dynamic>.from(schedule['doctor'] ?? {});
    final clinic = Map<String, dynamic>.from(schedule['clinic'] ?? {});
    final room = Map<String, dynamic>.from(schedule['room'] ?? {});
    final workDate = schedule['workDate']?.toString();
    final startTime = schedule['startTime']?.toString();
    final endTime = schedule['endTime']?.toString();
    final status = schedule['status']?.toString().toUpperCase();
    final avatarUrl = doctor['avatarUrl']?.toString();
    final avatarImage = ApiService.resolveAvatarImage(avatarUrl);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: colorScheme.surfaceContainerHighest,
            backgroundImage: avatarImage,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? Icon(
                    Icons.person_rounded,
                    size: 36,
                    color: colorScheme.primary,
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        doctor['fullName']?.toString() ?? '—',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                      ),
                    ),
                    Icon(
                      Icons.verified_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    clinic['name'],
                    room['name'],
                  ].whereType<String>().where((element) => element.isNotEmpty).join(' • '),
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (workDate != null || (startTime != null && endTime != null)) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule, color: colorScheme.tertiary, size: 18),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          [
                            workDate != null ? DateFormat('MMM dd').format(DateTime.parse(workDate)) : null,
                            if (startTime != null && endTime != null) '$startTime - $endTime',
                          ].whereType<String>().join(' • '),
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (status != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: status == 'ACTIVE' 
                                ? Colors.green.shade100 
                                : status == 'INACTIVE'
                                ? Colors.red.shade100
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: status == 'ACTIVE' 
                                  ? Colors.green.shade800 
                                  : status == 'INACTIVE'
                                  ? Colors.red.shade800
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: status == 'INACTIVE' 
                        ? null 
                        : () => _showBookingDialog(context, doctor, clinic, room),
                    icon: const Icon(Icons.calendar_month_outlined, size: 18),
                    label: const Text('Book Now'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: status == 'INACTIVE' 
                          ? colorScheme.onSurfaceVariant.withOpacity(0.38)
                          : colorScheme.primary,
                      side: BorderSide(
                        color: status == 'INACTIVE' 
                            ? colorScheme.outline.withOpacity(0.12)
                            : colorScheme.primary.withOpacity(0.5),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    Widget content;
    if (_isLoading) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    } else if (_error != null) {
      content = Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _error!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      );
    } else if (_schedules.isEmpty) {
      content = Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'home.doctor.empty'.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      );
    } else {
      // Hiển thị horizontal list bác sĩ, có nút cuộn trái/phải
      content = SizedBox(
        height: 220,
        child: Stack(
          children: [
            ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _schedules.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 320,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: _buildDoctorCard(context, _schedules[index]),
                  ),
                );
              },
            ),
            if (_canScrollLeft)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: Icon(Icons.chevron_left, color: colorScheme.primary, size: 32),
                    onPressed: _scrollLeft,
                    tooltip: 'Previous',
                  ),
                ),
              ),
            if (_canScrollRight)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: Icon(Icons.chevron_right, color: colorScheme.primary, size: 32),
                    onPressed: _scrollRight,
                    tooltip: 'Next',
                  ),
                ),
              ),
          ],
        ),
      );
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateScrollButtons();
      });
    }

    return content;
  }
}

// TRUSTED BY BANNER: Logo khách hàng chạy ngang tự động
class _TrustedByBanner extends StatefulWidget {
  const _TrustedByBanner();

  @override
  State<_TrustedByBanner> createState() => _TrustedByBannerState();
}

class _TrustedByBannerState extends State<_TrustedByBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  static const double _itemSize = 56;
  static const double _spacing = 20;
  final _logos =
      List.generate(10, (index) => 'assets/images/slider-logo${index + 1}.png');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Hiển thị logo tròn
  Widget _badge(BuildContext context, String asset) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: _itemSize,
      height: _itemSize,
      margin: EdgeInsets.only(right: _spacing),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.insert_emoticon, color: colorScheme.onSurfaceVariant);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('home.trustedBy.heading'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    )),
            const SizedBox(height: 16),
            SizedBox(
              height: _itemSize,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final offset = _animation.value * -1200;
                  return Stack(
                    children: [
                      Positioned(
                        left: offset,
                        child: Row(
                          children: [
                            ..._logos.map((logo) => _badge(context, logo)),
                            ..._logos.map((logo) => _badge(context, logo)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// MEDICAL RECORD PREVIEW: xem nhanh thông tin răng của user
class _MedicalRecordPreview extends StatelessWidget {
  const _MedicalRecordPreview();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'home.section.medicalRecord'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 16),
            // Placeholder cho biểu đồ/hình ảnh
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text('Teeth Chart Placeholder', style: TextStyle(color: colorScheme.onSurfaceVariant)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _LegendDot(color: colorScheme.tertiary, label: 'home.record.hasTreatment'.tr()),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _LegendDot(color: colorScheme.primary, label: 'home.record.recommended'.tr()),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'home.record.summary'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: TextButton.icon(
                onPressed: () => Fluttertoast.showToast(msg: 'View Medical Record'),
                icon: const Icon(Icons.file_copy_outlined, size: 20),
                label: Text('home.record.viewDetails'.tr()),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dot chú thích trong medical record preview
class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 10,
          width: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

// QUICK ACTIONS BAR: bottom nav, truy cập nhanh các chức năng quan trọng
class _QuickActionsBar extends StatelessWidget {
  const _QuickActionsBar();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = context.watch<UserProvider>().user;
    final roles = (user?['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final isDoctor = roles.contains('DOCTOR');
    
    final icons = [
      Icons.home_rounded,
      if (isDoctor) Icons.calendar_today_rounded,
      Icons.message_outlined,
      Icons.history_rounded,
      Icons.person_rounded,
    ];
    final labels = [
      'home.nav.home',
      if (isDoctor) 'home.nav.schedule',
      'home.nav.chat',
      'home.nav.history',
      'home.nav.profile'
    ];
    final routes = [
      '/home',
      if (isDoctor) '/schedule',
      '/chat',
      '/history',
      '/profile'
    ];
    
    const currentIndex = 0;

    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(icons.length, (index) {
            final isActive = index == currentIndex;
            // xác định icon primary (ví dụ chat có size to hơn) dựa trên vai trò
            final chatIndex = isDoctor ? 2 : 1;
            final isPrimaryAction = index == chatIndex; 
            
            return GestureDetector(
              onTap: () {
                if (routes[index] != '/home' && routes[index] != '/profile' && routes[index] != '/schedule') {
                   Fluttertoast.showToast(msg: '${labels[index].tr()} is coming soon');
                } else {
                  context.go(routes[index]);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: isActive
                          ? colorScheme.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      icons[index],
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      size: isPrimaryAction ? 28 : 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[index].tr(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}