import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../services/patient/patient_service.dart';
import '../../../../models/patient/patient_models.dart';
import 'widgets/medical_record_card.dart'; // Import widget vừa tạo

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  final PatientService _service = PatientService();

  List<MedicalRecord> _fullHistory = [];
  List<MedicalRecord> _filteredHistory = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  DateTime? _filterDate;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    // API dashboard trả về luôn medicalHistory
    final data = await _service.getDashboardSummary();
    if (mounted) {
      setState(() {
        if (data != null) {
          _fullHistory = data.medicalHistory;
          _filteredHistory = data.medicalHistory;
        }
        _isLoading = false;
      });
    }
  }

  void _filterData() {
    final query = _searchController.text.toLowerCase();
    String? dateStr;
    if (_filterDate != null) {
      dateStr = DateFormat('dd/MM/yyyy').format(_filterDate!);
    }

    setState(() {
      _filteredHistory = _fullHistory.where((record) {
        final matchesSearch =
            record.doctorName.toLowerCase().contains(query) ||
            record.diagnosis.toLowerCase().contains(query) ||
            record.treatment.toLowerCase().contains(query);

        final matchesDate = dateStr == null || record.visitDate == dateStr;

        return matchesSearch && matchesDate;
      }).toList();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _filterDate = picked);
      _filterData();
    }
  }

  void _clearFilter() {
    _searchController.clear();
    setState(() => _filterDate = null);
    _filterData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Lịch Sử Khám Bệnh"),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Header Thống kê & Filter
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _filterData(),
                  decoration: InputDecoration(
                    hintText: "Tìm theo bác sĩ, chẩn đoán...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 12),
                // Date Filter & Count
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        _filterDate == null
                            ? "Lọc theo ngày"
                            : DateFormat('dd/MM/yyyy').format(_filterDate!),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _filterDate != null
                            ? Colors.blue
                            : Colors.grey[700],
                        side: BorderSide(
                          color: _filterDate != null
                              ? Colors.blue
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                    if (_filterDate != null ||
                        _searchController.text.isNotEmpty)
                      IconButton(
                        onPressed: _clearFilter,
                        icon: const Icon(Icons.clear, color: Colors.red),
                        tooltip: "Xóa lọc",
                      ),
                    const Spacer(),
                    Text(
                      "${_filteredHistory.length} hồ sơ",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Danh sách
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredHistory.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredHistory.length,
                    itemBuilder: (context, index) {
                      return MedicalRecordCard(record: _filteredHistory[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Không tìm thấy hồ sơ nào",
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
          if (_filterDate != null || _searchController.text.isNotEmpty)
            TextButton(
              onPressed: _clearFilter,
              child: const Text("Xóa bộ lọc"),
            ),
        ],
      ),
    );
  }
}
