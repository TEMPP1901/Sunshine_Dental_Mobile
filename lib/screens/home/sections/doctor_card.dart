import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';

class DoctorCard extends StatefulWidget {
  const DoctorCard({super.key});

  @override
  State<DoctorCard> createState() => _DoctorCardState();
}

class _DoctorCardState extends State<DoctorCard> {
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

  void _showBookingDialog(
    BuildContext context,
    Map<String, dynamic> doctor,
    Map<String, dynamic> clinic,
    Map<String, dynamic> room,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final doctorName = doctor['fullName']?.toString() ?? 'Doctor';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text('home.doctor.booking'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('home.doctor.bookingWith'.tr(args: [doctorName])),
              const SizedBox(height: 16),
              if (clinic['name'] != null) Text(clinic['name'].toString()),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('common.cancel'.tr()),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.go('/service');
                Fluttertoast.showToast(msg: 'home.doctor.bookingRedirect'.tr());
              },
              child: Text('home.doctor.confirmBooking'.tr()),
            ),
          ],
        );
      },
    );
  }

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
      setState(() {
        _error = 'home.doctor.error'.tr();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Text(_error!);
    if (_schedules.isEmpty) return Text('home.doctor.empty'.tr());

    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: _schedules.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = _schedules[index];
              return SizedBox(
                width: 320,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(item['doctor']['fullName'] ?? ''),
                  ),
                ),
              );
            },
          ),
          if (_canScrollRight)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _scrollRight,
              ),
            ),
        ],
      ),
    );
  }
}
