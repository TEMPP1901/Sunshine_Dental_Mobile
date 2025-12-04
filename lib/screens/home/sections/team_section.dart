import 'package:flutter/material.dart';

// Widget hiển thị phần thông tin đội ngũ bác sĩ trên trang chủ
class TeamSection extends StatelessWidget {
  const TeamSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Xác định chế độ mobile hay desktop
    final isMobile = MediaQuery.of(context).size.width < 768;

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
              'Meet Our Professional Team',
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
                  // Layout desktop: chia 3 cột
                  return Row(
                    children: [
                      // Cột trái: thông tin tổng quan phòng khám
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFE2E8EB), Color(0xFFE9EDF4), Color(0xFFAFD9F6)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Dedicated to Better Patient Outcomes',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D1B3E),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Our team is comprised of highly qualified and passionate professionals dedicated to providing outstanding dental care for every smile.',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Ảnh đại diện bác sĩ trung tâm
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/images/doctor.png',
                            fit: BoxFit.cover,
                            height: 400,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 400,
                                color: Colors.grey[300],
                                child: const Icon(Icons.person, size: 100),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Cột phải: thông tin bác sĩ chi tiết
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Dr. John Smith',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D1B3E),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'With over 15 years of experience in the dental field, Dr. Smith is passionate about delivering the best care and beautiful smiles for his patients.',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 32,
                              runSpacing: 8,
                              children: [
                                RichText(
                                  text: const TextSpan(
                                    style: TextStyle(fontSize: 14),
                                    children: [
                                      TextSpan(
                                        text: 'Speciality: ',
                                        style: TextStyle(
                                          color: Color(0xFFFF6600),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Orthodontics & Cosmetic Dentistry',
                                        style: TextStyle(color: Color(0xFF0D1B3E)),
                                      ),
                                    ],
                                  ),
                                ),
                                RichText(
                                  text: const TextSpan(
                                    style: TextStyle(fontSize: 14),
                                    children: [
                                      TextSpan(
                                        text: 'Joined since: ',
                                        style: TextStyle(
                                          color: Color(0xFFFF6600),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '2008',
                                        style: TextStyle(color: Color(0xFF0D1B3E)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF66CCFF), Color(0xFF3366FF)],
                                ),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    // TODO: navigate to doctor detail page
                                  },
                                  borderRadius: BorderRadius.circular(28),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 8,
                                    ),
                                    child: const Text(
                                      'Learn more',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  // Layout mobile: dồn nội dung theo chiều dọc
                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFE2E8EB), Color(0xFFE9EDF4), Color(0xFFAFD9F6)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dedicated to Better Patient Outcomes',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D1B3E),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Our team is comprised of highly qualified and passionate professionals dedicated to providing outstanding dental care for every smile.',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/doctor.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 300,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 300,
                              color: Colors.grey[300],
                              child: const Icon(Icons.person, size: 100),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dr. John Smith',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D1B3E),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'With over 15 years of experience in the dental field, Dr. Smith is passionate about delivering the best care and beautiful smiles for his patients.',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: const TextSpan(
                                  style: TextStyle(fontSize: 14),
                                  children: [
                                    TextSpan(
                                      text: 'Speciality: ',
                                      style: TextStyle(
                                        color: Color(0xFFFF6600),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Orthodontics & Cosmetic Dentistry',
                                      style: TextStyle(color: Color(0xFF0D1B3E)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              RichText(
                                text: const TextSpan(
                                  style: TextStyle(fontSize: 14),
                                  children: [
                                    TextSpan(
                                      text: 'Joined since: ',
                                      style: TextStyle(
                                        color: Color(0xFFFF6600),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '2008',
                                      style: TextStyle(color: Color(0xFF0D1B3E)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF66CCFF), Color(0xFF3366FF)],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  // TODO: navigate to doctor detail page
                                },
                                borderRadius: BorderRadius.circular(28),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 8,
                                  ),
                                  child: const Text(
                                    'Learn more',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
