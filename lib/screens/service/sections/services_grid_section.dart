import 'package:flutter/material.dart';

class ServicesGridSection extends StatelessWidget {
  const ServicesGridSection({super.key});

  final List<Map<String, String>> _services = const [
    {
      'title': 'Preventive Care',
      'desc': 'Regular exams, cleanings, and x rays to maintain optimal oral health',
      'icon': 'assets/service_images/preventive-care.png',
    },
    {
      'title': 'Dental Implants',
      'desc': 'Permanent solution for missing teeth with natural look & bite',
      'icon': 'assets/service_images/dental-implant.jpg',
    },
    {
      'title': 'Orthodontics',
      'desc': 'Teeth straightening with braces and aligners for a healthier smile',
      'icon': 'assets/service_images/orthodontics.png',
    },
    {
      'title': 'Cosmetic Dentistry',
      'desc': 'Veneers, crowns, whitening for a brighter, balanced smile',
      'icon': 'assets/service_images/dentistry.png',
    },
    {
      'title': 'Oral Surgery',
      'desc': 'Extractions, wisdom tooth removal, and other surgical procedures',
      'icon': 'assets/service_images/surgery.png',
    },
    {
      'title': 'Pediatric Dentistry',
      'desc': 'Dental care for children in a friendly, comfortable environment',
      'icon': 'assets/service_images/kid-care.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 48),
      color: Colors.grey[50],
      child: Column(
        children: [
          Text(
            'Our Services',
            style: TextStyle(
              fontSize: isMobile ? 28 : 40,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 768 ? 2 : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 3,
                ),
                itemCount: _services.length,
                itemBuilder: (context, index) {
                  final service = _services[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                service['icon']!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.local_hospital,
                                    color: Color(0xFF3366FF),
                                    size: 24,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  service['title']!,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  service['desc']!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
