import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class TestimonialsSection extends StatefulWidget {
  const TestimonialsSection({super.key});

  @override
  State<TestimonialsSection> createState() => _TestimonialsSectionState();
}

class _TestimonialsSectionState extends State<TestimonialsSection> {
  int _currentIndex = 0;

  // Danh sách các đánh giá khách hàng với thông tin ảnh, quote, tên, chi tiết (trích từ file dịch)
  final List<Map<String, String>> _testimonials = [
    {
      'image': 'assets/images/patient1.png',
      'quoteKey': 'home.testimonials.quote1',
      'nameKey': 'home.testimonials.name1',
      'detailKey': 'home.testimonials.detail1',
    },
    {
      'image': 'assets/images/patient2.png',
      'quoteKey': 'home.testimonials.quote2',
      'nameKey': 'home.testimonials.name2',
      'detailKey': 'home.testimonials.detail2',
    },
    {
      'image': 'assets/images/patient3.png',
      'quoteKey': 'home.testimonials.quote3',
      'nameKey': 'home.testimonials.name3',
      'detailKey': 'home.testimonials.detail3',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Xác định thiết bị là mobile để tùy chỉnh UI
    final isMobile = MediaQuery.of(context).size.width < 768;
    final current = _testimonials[_currentIndex];

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 32 : 64,
        horizontal: isMobile ? 16 : 32,
      ),
      color: Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: Column(
          children: [
            Text(
              "Customer Testimonials",
              style: TextStyle(
                fontSize: isMobile ? 24 : 40,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0D1B3E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 768) {
                  // Giao diện desktop
                  return Row(
                    children: [
                      // Ảnh đại diện khách hàng
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 60),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              current['image']!,
                              width: 288,
                              height: 288,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 288,
                                  height: 288,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.person, size: 100),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Trích dẫn đánh giá
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '"${tr(current['quoteKey']!)}"',
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                fontStyle: FontStyle.italic,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    tr(current['nameKey']!),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF3366FF),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tr(current['detailKey']!),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  // Giao diện mobile
                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          current['image']!,
                          fit: BoxFit.cover,
                          width: 288,
                          height: 288,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 288,
                              height: 288,
                              color: Colors.grey[300],
                              child: const Icon(Icons.person, size: 100),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '"${tr(current['quoteKey']!)}"',
                        style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        tr(current['nameKey']!),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3366FF),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr(current['detailKey']!),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 32),
            // Dãy chấm chuyển testimonial (Pagination dots)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _testimonials.length,
                (index) => GestureDetector(
                  onTap: () {
                    // Đổi testimonial theo index được chọn
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: _currentIndex == index
                          ? const LinearGradient(
                              colors: [Color(0xFF66CCFF), Color(0xFF3366FF)],
                            )
                          : null,
                      color: _currentIndex == index ? null : Colors.grey[200],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _currentIndex == index
                            ? Colors.transparent
                            : Colors.grey[400]!,
                        width: 2,
                      ),
                      boxShadow: _currentIndex == index
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    transform: _currentIndex == index
                        ? (Matrix4.identity()..scale(1.05))
                        : Matrix4.identity(),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: _currentIndex == index
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
