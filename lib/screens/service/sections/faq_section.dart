import 'package:flutter/material.dart';

class FaqSection extends StatefulWidget {
  const FaqSection({super.key});

  @override
  State<FaqSection> createState() => _FaqSectionState();
}

class _FaqSectionState extends State<FaqSection> {
  // Danh sách câu hỏi và trả lời (tiếng Anh)
  final List<Map<String, String>> _faqs = const [
    {
      'q': 'What are your office hours?',
      'a': 'Monday to Friday: 9:00 AM – 5:00 PM. Closed on Saturday & Sunday.',
    },
    {
      'q': 'Can I use my insurance at your clinic?',
      'a':
          'Yes, we accept most major insurances and also provide detailed invoices for you.',
    },
    {
      'q': 'How often should I have a dental check-up?',
      'a':
          'We recommend visiting every 6 months or as advised by your dentist.',
    },
    {
      'q': 'Which dental services are available?',
      'a':
          'We offer general dentistry, orthodontics, cosmetic dentistry, preventive care, and more.',
    },
    {
      'q': 'Is emergency dental care provided?',
      'a':
          'Yes, we handle emergencies during our office hours. Please call ahead.',
    },
    {
      'q': 'How to make an appointment?',
      'a':
          'You can call us directly or use the online booking system on our website.',
    },
  ];

  // Quản lý trạng thái mở rộng/collapse của từng mục FAQ
  final Set<int> _expandedIndices = {};

  @override
  Widget build(BuildContext context) {
    // Xác định thiết bị có phải là mobile hay không
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 48),
      color: Colors.grey[50],
      child: Column(
        children: [
          Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: isMobile ? 28 : 40,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ..._faqs.asMap().entries.map((entry) {
            final index = entry.key;
            final faq = entry.value;
            final isExpanded = _expandedIndices.contains(index);

            return Container(
              margin: const EdgeInsets.only(bottom: 1),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: ExpansionTile(
                title: Text(
                  faq['q']!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                trailing: Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.black54,
                ),
                // Xử lý sự kiện khi mở rộng hoặc thu gọn mục FAQ
                onExpansionChanged: (expanded) {
                  setState(() {
                    if (expanded) {
                      _expandedIndices.add(index);
                    } else {
                      _expandedIndices.remove(index);
                    }
                  });
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        faq['a']!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
