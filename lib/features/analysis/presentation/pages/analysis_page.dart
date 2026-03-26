import 'package:flutter/material.dart';
import 'activity_page.dart';
import 'course_analysis_page.dart';

class AnalysisPage extends StatelessWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ตั้งเป็นสีใสเพื่อให้เห็น Container ไล่สีด้านล่าง
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF003E99), // สีเข้มสุดด้านบน
              Color(0xFF0053CC),
              Color(0xFF227CFF), // สีสว่างสุดด้านล่าง
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // 1. Header Text
                const Text(
                  'Analysis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SF-Pro',
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Activity Card
                _buildActivityCard(context),
                const SizedBox(height: 16),

                // 3. Courses Card
                _buildCoursesCard(context),
                const SizedBox(height: 16),

                // 4. Performance Card
                _buildPerformanceCard(),

                // เผื่อพื้นที่ว่างด้านล่างเยอะๆ จะได้ไม่โดนแถบ Navigation Bar บัง
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // Widget ย่อยสำหรับ Card ที่ 1: Activity
  // ---------------------------------------------------------
  Widget _buildActivityCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // เมื่อกดการ์ด ให้พาไปหน้า ActivityPage
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ActivityPage()),
        );
      },
      child: _buildCardTemplate(
        title: 'Activity',
        showArrow: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Activity',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF-Pro',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      '00',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SF-Pro',
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_outward,
                      color: Colors.green,
                      size: 14,
                    ),
                    Text(
                      '00%',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // กล่องจำลองสำหรับใส่กราฟเส้น
            Container(
              height: 50,
              width: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Text(
                'Graph Area',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // Widget ย่อยสำหรับ Card ที่ 2: Courses
  // ---------------------------------------------------------
  Widget _buildCoursesCard(BuildContext context) { // 🔴 รับ context เข้ามาด้วย
    return GestureDetector(
      onTap: () {
        // เมื่อกดการ์ด ให้พาไปหน้า CourseAnalysisPage
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CourseAnalysisPage()),
        );
      },
      child: _buildCardTemplate(
        title: 'Courses',
        showArrow: true, // เปิดลูกศรให้รู้ว่ากดได้
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total Quiz', '0', '', Colors.redAccent),
            _buildVerticalDivider(),
            _buildStatItem('Average Score', '0', ' %', Colors.green),
            _buildVerticalDivider(),
            _buildStatItem('Time', '0', ' Hr', Colors.lightBlue),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // Widget ย่อยสำหรับ Card ที่ 3: Performance
  // ---------------------------------------------------------
  Widget _buildPerformanceCard() {
    return _buildCardTemplate(
      title: 'Performance',
      showArrow: false,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Best Score', '0', '', Colors.redAccent),
              _buildVerticalDivider(),
              _buildStatItem('Average Score', '0', ' %', Colors.green),
              _buildVerticalDivider(),
              _buildStatItem('Recent Score', '0', ' %', Colors.lightBlue),
            ],
          ),
          const SizedBox(height: 24),
          // กล่องจำลองสำหรับกราฟเส้นแบบหลายเส้น
          Container(
            height: 150,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: const Border(
                left: BorderSide(color: Colors.black54, width: 2),
                bottom: BorderSide(color: Colors.black54, width: 2),
              ),
            ),
            child: const Text(
              'Multi-Line Graph Area',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          // ส่วนของ Legend (คำอธิบายสีเส้นกราฟ)
          _buildLegendItem(Colors.purpleAccent, 'Improvement Score', '00%'),
          _buildLegendItem(Colors.blue, 'Average Score', '00%'),
          _buildLegendItem(Colors.green, 'Highest Score', '00'),
          _buildLegendItem(Colors.redAccent, 'Lowest Score', '00'),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // Helper Widgets (ตัวช่วยสร้าง UI ซ้ำๆ ให้โค้ดสั้นลง)
  // ---------------------------------------------------------

  // โครงสร้างการ์ดสีขาวขอบมน
  Widget _buildCardTemplate({
    required String title,
    required Widget child,
    bool showArrow = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5F8), // สีขาวอมเทาตามดีไซน์
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Color(0xFFFF9500),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFFF9500),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SF-Pro',
                    ),
                  ),
                ],
              ),
              if (showArrow)
                const Icon(Icons.chevron_right, color: Colors.black87),
            ],
          ),
          const SizedBox(height: 16),
          child, // เนื้อหาด้านในของการ์ด
        ],
      ),
    );
  }

  // ตัวแสดงตัวเลขสถิติ (มีชื่อ, ตัวเลข, หน่วย)
  Widget _buildStatItem(
    String label,
    String value,
    String unit,
    Color labelColor,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'SF-Pro',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'SF-Pro',
              ),
            ),
            if (unit.isNotEmpty)
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontFamily: 'SF-Pro',
                ),
              ),
          ],
        ),
      ],
    );
  }

  // เส้นคั่นแนวตั้ง
  Widget _buildVerticalDivider() {
    return Container(height: 40, width: 1, color: Colors.grey[300]);
  }

  // ตัวแสดงคำอธิบายสี (Legend) ใต้กราฟ
  Widget _buildLegendItem(Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontFamily: 'SF-Pro',
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'SF-Pro',
            ),
          ),
        ],
      ),
    );
  }
}
