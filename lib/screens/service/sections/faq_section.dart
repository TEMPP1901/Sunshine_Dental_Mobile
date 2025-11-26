import 'package:flutter/material.dart';

class FaqSection extends StatefulWidget {
  const FaqSection({super.key});

  @override
  State<FaqSection> createState() => _FaqSectionState();
}

class _FaqSectionState extends State<FaqSection> {
  final List<Map<String, String>> _faqs = const [
    {
      'q': 'What are your office hours?',
      'a': 'Mon-Fri 9:00–17:00. Saturday & Sunday day off.',
    },
    {
      'q': 'Do you accept my insurance?',
      'a': 'Yes, we support major insurers and provide detailed invoices.',
    },
    {
      'q': 'How often should I visit for a checkup?',
      'a': 'Every 6 months, or as your dentist advises.',
    },
    {
      'q': 'What services do you offer?',
      'a': 'General dentistry, orthodontics, cosmetic procedures, and more.',
    },
    {
      'q': 'Do you offer emergency dental care?',
      'a': 'Yes, we provide urgent care during office hours.',
    },
    {
      'q': 'How can I schedule an appointment?',
      'a': 'Call us or use our online booking system on the website.',
    },
  ];

  final Set<int> _expandedIndices = {};

  @override
  Widget build(BuildContext context) {
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
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
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
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.black54,
                ),
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
          }).toList(),
        ],
      ),
    );
  }
}
