import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';

// Import màn hình AI Chat (theo cấu trúc folder mới)
import '../ai_chat/ai_chat_screen.dart';

// Import các sections
import 'sections/header_section.dart';
import 'sections/upcoming_appointment_card.dart';
import 'sections/promo_banner.dart';
import 'sections/section_title.dart';
import 'sections/service_carousel.dart';
import 'sections/doctor_card.dart';
import 'sections/trusted_by_banner.dart';
import 'sections/quick_actions_bar.dart';
import 'sections/contact_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      final colorScheme = Theme.of(context).colorScheme;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      debugPrint(' [HomePage] Building with isDark: $isDark');

      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF1E1E1E)
            : colorScheme.surfaceContainerLow,

        // --- TÍCH HỢP NÚT CHAT AI ---
        floatingActionButton: Padding(
          // Thêm padding bottom để nút không bị dính vào QuickActionsBar
          padding: const EdgeInsets.only(bottom: 80.0),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AIChatScreen()),
              );
            },
            backgroundColor: Colors.blue[600],
            elevation: 4,
            shape: const CircleBorder(), // Đảm bảo nút hình tròn
            child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
          ),
        ),
        // Đặt vị trí nút ở góc dưới phải (mặc định)
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

        body: SafeArea(
          child: Stack(
            children: [
              // Nội dung chính có thể cuộn
              SingleChildScrollView(
                // Tăng padding bottom lên 120 để không bị che bởi QuickActionsBar
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header
                    const HeaderSection(),

                    const SizedBox(height: 24),

                    // 2. Upcoming Appointment
                    const UpcomingAppointmentCard(),

                    const SizedBox(height: 24),

                    // 3. Promo Banner
                    const PromoBanner(),

                    const SizedBox(height: 32),

                    // 4. Services
                    SectionTitle(
                      title: 'home.section.services'.tr(),
                      onSeeAll: () => GoRouter.of(context).push('/booking'),
                    ),
                    const SizedBox(height: 16),
                    const ServiceCarousel(),

                    const SizedBox(height: 32),

                    // 5. Doctors
                    SectionTitle(
                      title: 'home.section.availableDoctor'.tr(),
                      onSeeAll: () =>
                          Fluttertoast.showToast(msg: 'Navigating to Doctors'),
                    ),
                    const SizedBox(height: 16),
                    const DoctorCard(),

                    const SizedBox(height: 28),

                    // 6. Trusted By
                    const TrustedByBanner(),

                    const SizedBox(height: 28),

                    // 7. Contact
                    const ContactSection(),
                  ],
                ),
              ),

              // Bottom Nav Bar (Floating)
              const Positioned(
                left: 24,
                right: 24,
                bottom: 16,
                child: QuickActionsBar(),
              ),
            ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('[HomePage] Error building widget: $e');
      debugPrint(' [HomePage] Stack trace: $stackTrace');
      return Scaffold(body: Center(child: Text('Error loading home page: $e')));
    }
  }
}
