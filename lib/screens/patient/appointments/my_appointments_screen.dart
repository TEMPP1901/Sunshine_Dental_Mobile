import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/patient/patient_models.dart';
import '../../../../services/patient/patient_service.dart';
import 'widgets/appointment_card.dart'; // Đảm bảo bạn đã tạo widget này

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

  Future<void> _confirmCancel(int id) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận hủy"),
        content: const Text(
          "Bạn có chắc muốn hủy lịch hẹn này? Hành động này không thể hoàn tác.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Đóng"),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _service.cancelAppointment(id, "Bận việc đột xuất");
                Fluttertoast.showToast(msg: "Đã hủy lịch thành công");
                _fetchData(); // Load lại danh sách
              } catch (e) {
                Fluttertoast.showToast(
                  msg: "Lỗi: ${e.toString()}",
                  backgroundColor: Colors.red,
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hủy lịch"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản Lý Lịch Hẹn"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: "Sắp tới"),
            Tab(text: "Lịch sử"),
            Tab(text: "Đã hủy"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(['PENDING', 'CONFIRMED']),
                _buildList(['COMPLETED']),
                _buildList(['CANCELLED', 'NOSHOW']),
              ],
            ),
    );
  }

  Widget _buildList(List<String> statusFilter) {
    final list = _appointments
        .where((a) => statusFilter.contains(a.status))
        .toList();

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "Không có lịch hẹn nào",
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
          return AppointmentCard(
            appointment: item,
            onCancel: item.canCancel ? () => _confirmCancel(item.id) : null,
          );
        },
      ),
    );
  }
}
