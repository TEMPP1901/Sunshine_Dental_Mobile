import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/user_provider.dart';
import '../../services/api_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return PopScope(
      canPop: context.canPop(),
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLow, // Nền chính nhẹ nhàng
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 120), // Tăng padding ngang
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderSection(), // Không cần truyền theme
                    const SizedBox(height: 24),
                    const _PromoBanner(),
                    const SizedBox(height: 32),
                    _SectionTitle(
                      title: 'home.section.services'.tr(),
                      onSeeAll: () => Fluttertoast.showToast(msg: 'Navigating to Services'),
                    ),
                    const SizedBox(height: 16),
                    const _ServiceCarousel(),
                    const SizedBox(height: 32),
                    _SectionTitle(
                      title: 'home.section.availableDoctor'.tr(),
                      onSeeAll: () => Fluttertoast.showToast(msg: 'Navigating to Doctors'),
                    ),
                    const SizedBox(height: 16),
                    const _DoctorCard(),
                    const SizedBox(height: 28),
                    const _TrustedByBanner(),
                    const SizedBox(height: 28),
                    _SectionTitle(
                      title: 'home.section.medicalRecord'.tr(),
                      onSeeAll: () => Fluttertoast.showToast(msg: 'Navigating to Records'),
                      showSeeAll: false, // Không cần nút See All cho Medical Record
                    ),
                    const SizedBox(height: 16),
                    const _MedicalRecordPreview(),
                  ],
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 16,
                child: const _QuickActionsBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== HEADER SECTION ====================
class _HeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = context.watch<UserProvider>().user;
    final fullName = user?['fullName']?.toString();
    final avatarUrl = user?['avatarUrl']?.toString();
    ImageProvider? avatarImage;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      avatarImage = NetworkImage(ApiService.resolveUrl(avatarUrl));
    } else {
      avatarImage = const AssetImage('assets/images/doctor.png');
    }
    
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go('/profile'), // Thêm hành động chạm vào Avatar để đi đến Profile
          child: CircleAvatar(
            radius: 24, // Giảm kích thước avatar
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
                'home.greeting'.tr(), // Dùng tr() cho i18n
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
            elevation: 2, // Dùng elevation nhẹ nhàng
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              onTap: () => Fluttertoast.showToast(msg: 'Notification opened'),
              borderRadius: BorderRadius.circular(16),
              child: Icon(
                Icons.notifications_none_rounded,
                color: colorScheme.onSurface,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==================== PROMO BANNER ====================
class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 6, // Banner nổi bật với elevation cao hơn
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias, // Cắt Image nếu tràn ra ngoài
      child: Container(
        decoration: BoxDecoration(
          // Gradient sử dụng màu Primary và Secondary để bắt mắt hơn
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
                          fontWeight: FontWeight.w800, // Thêm độ đậm
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
                      backgroundColor: colorScheme.onPrimary, // Nền trắng/sáng
                      foregroundColor: colorScheme.primary, // Chữ màu primary
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
            // Hình ảnh bên phải
            SizedBox(
              height: 120,
              width: 80,
              child: Image.asset(
                'assets/images/hero-tooth.png',
                fit: BoxFit.contain,
                color: colorScheme.onPrimary.withOpacity(0.9), // Tinh chỉnh màu ảnh
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== SECTION TITLE ====================
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
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onBackground,
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

// ==================== SERVICE CAROUSEL ====================
class _ServiceCarousel extends StatelessWidget {
  const _ServiceCarousel();

  static final _services = [
    _ServiceItem('Scaling', 'assets/images/tooth-logo.png'),
    _ServiceItem('Braces', 'assets/images/patient1.png'),
    _ServiceItem('Crown', 'assets/images/patient2.png'),
    _ServiceItem('Whitening', 'assets/images/patient3.png'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SizedBox(
      height: 110, // Giảm nhẹ chiều cao
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = _services[index];
          
          return SizedBox(
            width: 100, // Giảm nhẹ chiều rộng
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Bo góc nhỏ hơn cho gọn
              child: InkWell(
                onTap: () => Fluttertoast.showToast(msg: 'Selected ${item.title}'),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: colorScheme.primaryContainer.withOpacity(0.5),
                        // Image.asset trong CircleAvatar sẽ bị lỗi, dùng Icon tạm
                        child: Icon(
                          Icons.healing_outlined, 
                          color: colorScheme.primary, 
                          size: 24
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
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

class _ServiceItem {
  const _ServiceItem(this.title, this.asset);
  final String title;
  final String asset;
}


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

  void _updateScrollButtons() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    setState(() {
      _canScrollLeft = position.pixels > 0;
      _canScrollRight = position.pixels < position.maxScrollExtent;
    });
  }

  void _scrollLeft() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.offset - 320,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollRight() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.offset + 320,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

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
                // Navigate to service page hoặc booking page
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

  Future<void> _fetchDoctors() async {
    try {
      // Lấy danh sách bác sĩ từ API public
      final response = await ApiService().get('/api/hr/employees/doctors');
      final data = response.data;
      
      if (data is List && data.isNotEmpty) {
        // Chuyển đổi từ employee format sang format tương tự schedule để tương thích với UI
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
      // Fallback: Nếu API doctors không hoạt động, thử dùng API schedules/current
      try {
        final scheduleResponse = await ApiService().get('/api/hr/schedules/current');
        final scheduleData = scheduleResponse.data;
        if (scheduleData is List && scheduleData.isNotEmpty) {
          // Loại bỏ trùng lặp: Group theo doctorId
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
        // Nếu cả 2 API đều lỗi, hiển thị error
        setState(() {
          _error = 'home.doctor.error'.tr();
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildDoctorCard(BuildContext context, Map<String, dynamic> schedule) {
    final colorScheme = Theme.of(context).colorScheme;
    final doctor = Map<String, dynamic>.from(schedule['doctor'] ?? {});
    final clinic = Map<String, dynamic>.from(schedule['clinic'] ?? {});
    final room = Map<String, dynamic>.from(schedule['room'] ?? {});
    final workDate = schedule['workDate']?.toString();
    final startTime = schedule['startTime']?.toString();
    final endTime = schedule['endTime']?.toString();
    final avatarUrl = doctor['avatarUrl']?.toString();

    ImageProvider? avatar;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      avatar = NetworkImage(ApiService.resolveUrl(avatarUrl));
    } else {
      avatar = const AssetImage('assets/images/doctor.png');
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image(
              image: avatar,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
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
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: () => _showBookingDialog(context, doctor, clinic, room),
                    icon: const Icon(Icons.calendar_month_outlined, size: 18),
                    label: const Text('Book Now'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
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
      // Hiển thị danh sách bác sĩ dạng ListView theo chiều ngang với nút điều hướng
      content = SizedBox(
        height: 180, // Chiều cao cố định cho horizontal list
        child: Stack(
          children: [
            ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _schedules.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 320, // Chiều rộng cố định cho mỗi card
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: _buildDoctorCard(context, _schedules[index]),
                  ),
                );
              },
            ),
            // Nút mũi tên trái
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
            // Nút mũi tên phải
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
      
      // Cập nhật trạng thái nút sau khi build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateScrollButtons();
      });
    }

    return content;
  }
}

// ==================== TRUSTED BY BANNER ====================
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

// ==================== MEDICAL RECORD PREVIEW ====================
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
            // Placeholder cho biểu đồ/hình ảnh (Nếu có asset)
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
                _LegendDot(color: colorScheme.tertiary, label: 'home.record.hasTreatment'.tr()),
                const SizedBox(width: 16),
                _LegendDot(color: colorScheme.primary, label: 'home.record.recommended'.tr()),
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
            // Nút Xem chi tiết
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

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          height: 10, // Giảm kích thước dot
          width: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ==================== QUICK ACTIONS BAR (BOTTOM NAV) ====================
class _QuickActionsBar extends StatelessWidget {
  const _QuickActionsBar();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final icons = [
      Icons.home_rounded,
      Icons.calendar_today_rounded,
      Icons.message_outlined,
      Icons.history_rounded,
      Icons.person_rounded,
    ];
    final labels = ['home.nav.home', 'home.nav.schedule', 'home.nav.chat', 'home.nav.history', 'home.nav.profile'];
    final routes = ['/home', '/schedule', '/chat', '/history', '/profile'];
    
    const currentIndex = 0; // Giả định Home là tab đầu tiên

    return Card(
      elevation: 10, // Elevation cao để nổi bật
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Giảm padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(icons.length, (index) {
            final isActive = index == currentIndex;
            final isPrimaryAction = index == 2; // Ví dụ: Chat/Message là trung tâm
            
            return GestureDetector(
              onTap: () {
                if (routes[index] != '/home' && routes[index] != '/profile') {
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
                      fontSize: 10, // Font nhỏ hơn cho gọn
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