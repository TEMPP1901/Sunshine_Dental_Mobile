import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart'; // Import i18n
import '../../../../models/patient/patient_models.dart';
import '../../../../services/patient/patient_service.dart';
import 'widgets/appointment_card.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PatientService _service = PatientService();
  List<PatientAppointment> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final data = await _service.getAppointments();
    if (mounted) {
      setState(() {
        _appointments = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "appointments.title".tr(), // "Quản Lý Lịch Hẹn"
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: colorScheme.primary,
          // Sử dụng Builder để rebuild khi đổi ngôn ngữ (nếu cần thiết,
          // nhưng TabBar thường cần reload màn hình để update text)
          tabs: [
            Tab(text: "appointments.tabs.upcoming".tr()), // "Sắp tới"
            Tab(text: "appointments.tabs.history".tr()), // "Lịch sử"
            Tab(text: "appointments.tabs.cancelled".tr()), // "Đã hủy"
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList([
                  'PENDING',
                  'SCHEDULED',
                  'CONFIRMED',
                  'IN_PROGRESS',
                  'PROCESSING',
                ]),
                _buildList(['COMPLETED']),
                _buildList(['CANCELLED', 'CANCELED', 'NOSHOW', 'NO_SHOW']),
              ],
            ),
    );
  }

  Widget _buildList(List<String> statusFilter) {
    final list = _appointments
        .where((a) => statusFilter.contains(a.status.toUpperCase()))
        .toList();

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "appointments.empty".tr(), // "Không có lịch hẹn nào"
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) {
          final item = list[i];
          return AppointmentCard(appointment: item);
        },
      ),
    );
  }
}
