import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'activity_page.dart';
import 'course_analysis_page.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {

  Future<Map<String, dynamic>> _fetchAnalysisData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final historySnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('history')
        .orderBy('timestamp') 
        .get();

    int totalQuiz = historySnap.docs.length;
    double sumPercentages = 0;
    double maxPercent = 0;
    double minPercent = 100; 
    double recentPercent = 0;
    List<FlSpot> userSpots = [];

    if (totalQuiz > 0) {
      int index = 0;
      for (var doc in historySnap.docs) {
        var data = doc.data();
        int score = data['score'] ?? 0;
        int totalQuestions = data['totalQuestions'] ?? 20;

        double percent = totalQuestions > 0 ? (score / totalQuestions) * 100 : 0;

        sumPercentages += percent;
        if (percent > maxPercent) maxPercent = percent;
        if (percent < minPercent) minPercent = percent;
        
        recentPercent = percent; 
        userSpots.add(FlSpot(index.toDouble(), percent));
        index++;
      }
      
      // บั๊กกราฟพังถ้ามีข้อมูลแค่ 1 จุด
      if (userSpots.length == 1) {
        // ก๊อปปี้จุดเดิมเพิ่มไปข้างหน้า 1 ช่อง เพื่อให้ลากเส้นแนวนอนได้
        userSpots.add(FlSpot(1, recentPercent));
      }
      
    } else {
      minPercent = 0; 
      userSpots = [const FlSpot(0, 0), const FlSpot(1, 0)]; 
    }

    double avgPercent = totalQuiz > 0 ? (sumPercentages / totalQuiz) : 0;

    return {
      'totalQuiz': totalQuiz,
      'avgScore': avgPercent,
      'bestScore': maxPercent,
      'minScore': minPercent,
      'recentScore': recentPercent, 
      'userSpots': userSpots,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF003E99), Color(0xFF0053CC), Color(0xFF227CFF)],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _fetchAnalysisData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }

              final data = snapshot.data ?? {};
              final totalQuiz = data['totalQuiz'] ?? 0;
              final avgScore = (data['avgScore'] ?? 0.0).toStringAsFixed(0);
              final bestScore = (data['bestScore'] ?? 0.0).toStringAsFixed(0);
              final minScore = (data['minScore'] ?? 0.0).toStringAsFixed(0);
              final recentScore = (data['recentScore'] ?? 0.0).toStringAsFixed(0); 
              final List<FlSpot> userSpots = data['userSpots'] ?? [const FlSpot(0, 0), const FlSpot(1, 0)];

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text('Analysis', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')),
                    const SizedBox(height: 24),

                    _buildActivityCard(context, totalQuiz.toString(), avgScore, userSpots),
                    const SizedBox(height: 16),

                    _buildCoursesCard(context, totalQuiz.toString(), avgScore),
                    const SizedBox(height: 16),

                    _buildPerformanceCard(bestScore, avgScore, recentScore, minScore, userSpots),

                    const SizedBox(height: 120),
                  ],
                ),
              );
            }
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, String totalQuiz, String avgScore, List<FlSpot> spots) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivityPage()));
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
                const Text('Weekly Activity', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'SF-Pro')),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(totalQuiz, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_outward, color: Colors.green, size: 14),
                    Text('$avgScore%', style: TextStyle(color: Colors.green[600], fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ],
            ),
            SizedBox(
              height: 50,
              width: 120,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots, 
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesCard(BuildContext context, String totalQuiz, String avgScore) { 
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const CourseAnalysisPage()));
      },
      child: _buildCardTemplate(
        title: 'Courses',
        showArrow: true, 
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total Quiz', totalQuiz, '', Colors.redAccent),
            _buildVerticalDivider(),
            _buildStatItem('Average Score', avgScore, ' %', Colors.green),
            _buildVerticalDivider(),
            _buildStatItem('Time', '-', ' Hr', Colors.lightBlue), 
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(String bestScore, String avgScore, String recentScore, String minScore, List<FlSpot> userSpots) {
    return _buildCardTemplate(
      title: 'Performance',
      showArrow: false,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Best Score', bestScore, ' %', Colors.redAccent),
              _buildVerticalDivider(),
              _buildStatItem('Average Score', avgScore, ' %', Colors.green),
              _buildVerticalDivider(),
              _buildStatItem('Recent Score', recentScore, ' %', Colors.lightBlue), 
            ],
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            height: 180,
            width: double.infinity,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(
                  show: true, 
                  border: Border(bottom: BorderSide(color: Colors.grey.shade500, width: 2), left: BorderSide(color: Colors.grey.shade500, width: 2))
                ),
                lineBarsData: [
                  // โชว์แค่เส้นคะแนนจริงของผู้ใช้งาน เพื่อความสมจริง (เอาเส้นหลอกๆ ออก)
                  _createLineData(const Color(0xFF1B6DF9), userSpots),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          // แก้ไข: ปรับแก้ Legend ให้ข้อความ ตัวแปร และ % ถูกต้องตรงกับกราฟและสถิติ
          _buildLegendItem(const Color(0xFF1B6DF9), 'Your Score Trend', 'Actual'),
          _buildLegendItem(Colors.green, 'Highest Score', '$bestScore%'),
          _buildLegendItem(Colors.blueGrey, 'Average Score', '$avgScore%'),
          _buildLegendItem(Colors.redAccent, 'Lowest Score', '$minScore%'),
        ],
      ),
    );
  }

  LineChartBarData _createLineData(Color color, List<FlSpot> spots) {
    return LineChartBarData(
      spots: spots,
      isCurved: true, 
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: true), // เปิดให้เห็นจุดบนกราฟ จะได้ดูออกว่าทำไปกี่ครั้ง
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.2), // เพิ่มเงาสีใต้กราฟให้ดูสวยขึ้น
      ),
    );
  }

  Widget _buildCardTemplate({required String title, required Widget child, bool showArrow = true}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5F8),
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
                  const Icon(Icons.local_fire_department, color: Color(0xFFFF9500)),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(color: Color(0xFFFF9500), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')),
                ],
              ),
              if (showArrow) const Icon(Icons.chevron_right, color: Colors.black87),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit, Color labelColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: labelColor, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')),
            if (unit.isNotEmpty) Text(unit, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey, fontFamily: 'SF-Pro')),
          ],
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 40, width: 1, color: Colors.grey[300]);
  }

  Widget _buildLegendItem(Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(color: Colors.black87, fontFamily: 'SF-Pro')),
            ],
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')),
        ],
      ),
    );
  }
}