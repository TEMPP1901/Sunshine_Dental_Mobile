import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'sections/services_grid_section.dart';
import 'sections/why_choose_us_section.dart';
import 'sections/how_it_works_section.dart';
import 'sections/faq_section.dart';

class ServicePage extends StatelessWidget {
  const ServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Trả về màn hình dịch vụ, có thể quay lại màn trước nếu có thể
    return PopScope(
      canPop: context.canPop(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Service'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const ServicesGridSection(),
              const WhyChooseUsSection(),
              const HowItWorksSection(),
              const FaqSection(),
            ],
          ),
        ),
      ),
    );
  }
}
