import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/booking/booking_provider.dart';
import '../../../services/booking/booking_api_service.dart';
import '../../../models/booking/booking_models.dart';

class StepServiceClinic extends StatefulWidget {
  const StepServiceClinic({super.key});

  @override
  State<StepServiceClinic> createState() => _StepServiceClinicState();
}

class _StepServiceClinicState extends State<StepServiceClinic> {
  final BookingApiService _apiService = BookingApiService();
  List<BookingClinic> clinics = [];
  List<BookingService> services = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final c = await _apiService.getClinics();
      final s = await _apiService.getServices();
      if (mounted) {
        setState(() {
          clinics = c;
          services = s;
          isLoading = false;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);

    if (isLoading) return const Center(child: CircularProgressIndicator());

    // Tìm clinic đã chọn trong list (so sánh bằng id để tránh lỗi reference)
    // DropdownButton yêu cầu value phải là cùng instance với một item trong items list
    BookingClinic? selectedClinicValue;
    if (provider.selectedClinic != null && clinics.isNotEmpty) {
      try {
        selectedClinicValue = clinics.firstWhere(
          (c) => c.id == provider.selectedClinic!.id,
        );
      } catch (e) {
        // Nếu không tìm thấy, set về null để tránh lỗi
        selectedClinicValue = null;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("1. Chọn cơ sở", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<BookingClinic>(
            value: selectedClinicValue,
            hint: const Text("Chọn phòng khám"),
            items: clinics.map((c) => DropdownMenuItem(
              value: c,
              child: Text(c.clinicName, overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (val) {
              if (val != null) provider.setClinic(val);
            },
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),

          const SizedBox(height: 24),
          const Text("2. Chọn dịch vụ", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // List Services (Accordion)
          ...services.map((service) => ExpansionTile(
            title: Text(service.serviceName),
            children: service.variants.map((variant) {
              bool isSelected = provider.selectedServiceVariant?.variantId == variant.variantId;
              return ListTile(
                title: Text(variant.variantName),
                subtitle: Text("${variant.price} VND - ${variant.duration} phút"),
                trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                selected: isSelected,
                onTap: () => provider.setService(service, variant),
              );
            }).toList(),
          )),

          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: (provider.selectedClinic != null && provider.selectedServiceVariant != null)
                ? provider.nextStep
                : null,
            child: const Text("Tiếp tục"),
          )
        ],
      ),
    );
  }
}