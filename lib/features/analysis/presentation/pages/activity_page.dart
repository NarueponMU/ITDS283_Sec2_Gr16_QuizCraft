import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // ใช้จัดการและจัดรูปแบบวันที่

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  String _selectedTime = 'This Week';
  final List<String> _timeOptions = ['This Week', 'This Month', 'This Year'];

  // ตัวแปรเก็บข้อมูลสถิติที่คำนวณแล้ว
  int _totalQuizzes = 0;
  Map<String, int> _chartData = {}; // เก็บข้อมูลวาดกราฟ เช่น {'Mon': 2, 'Tue': 0}
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchActivityData(); // ดึงข้อมูลทันทีที่เปิดหน้า
  }

  // 🔴 1. ฟังก์ชันดึงและประมวลผลข้อมูลจาก Firebase
  Future<void> _fetchActivityData() async {
    setState(() => _isLoading = true);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final historySnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .get();

      final now = DateTime.now();
      int totalCount = 0;
      Map<String, int> tempChartData = {};

      // เตรียมโครงสร้างกราฟเปล่าๆ ตาม Time Range ที่เลือก
      if (_selectedTime == 'This Week') {
        // สร้างโครง Sun - Sat (7 วันย้อนหลัง)
        for (int i = 6; i >= 0; i--) {
          String day = DateFormat('EEE').format(now.subtract(Duration(days: i)));
          tempChartData[day] = 0;
        }
      } else if (_selectedTime == 'This Month') {
        tempChartData = {'W1': 0, 'W2': 0, 'W3': 0, 'W4': 0};
      } else if (_selectedTime == 'This Year') {
        tempChartData = {'Q1': 0, 'Q2': 0, 'Q3': 0, 'Q4': 0};
      }

      // วนลูปอ่านประวัติแต่ละก้อน
      for (var doc in historySnap.docs) {
        var data = doc.data();
        if (data['timestamp'] == null) continue;
        
        DateTime recordDate = (data['timestamp'] as Timestamp).toDate();

        // 🔴 กรองข้อมูลและจัดลงกราฟตามช่วงเวลาที่เลือก
        if (_selectedTime == 'This Week') {
          // เช็คว่าอยู่ใน 7 วันที่ผ่านมาหรือไม่
          if (now.difference(recordDate).inDays <= 6) {
            totalCount++;
            String dayLabel = DateFormat('EEE').format(recordDate);
            if (tempChartData.containsKey(dayLabel)) {
              tempChartData[dayLabel] = tempChartData[dayLabel]! + 1;
            }
          }
        } else if (_selectedTime == 'This Month') {
          // เช็คว่าอยู่เดือนเดียวกันและปีเดียวกัน
          if (recordDate.month == now.month && recordDate.year == now.year) {
            totalCount++;
            int day = recordDate.day;
            if (day <= 7) tempChartData['W1'] = tempChartData['W1']! + 1;
            else if (day <= 14) tempChartData['W2'] = tempChartData['W2']! + 1;
            else if (day <= 21) tempChartData['W3'] = tempChartData['W3']! + 1;
            else tempChartData['W4'] = tempChartData['W4']! + 1;
          }
        } else if (_selectedTime == 'This Year') {
          // เช็คว่าอยู่ปีเดียวกัน
          if (recordDate.year == now.year) {
            totalCount++;
            int month = recordDate.month;
            if (month <= 3) tempChartData['Q1'] = tempChartData['Q1']! + 1;
            else if (month <= 6) tempChartData['Q2'] = tempChartData['Q2']! + 1;
            else if (month <= 9) tempChartData['Q3'] = tempChartData['Q3']! + 1;
            else tempChartData['Q4'] = tempChartData['Q4']! + 1;
          }
        }
      }

      // อัปเดต UI
      if (mounted) {
        setState(() {
          _totalQuizzes = totalCount;
          _chartData = tempChartData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // เปลี่ยนชื่อหัวข้อกราฟ
  String _getChartTitle() {
    switch (_selectedTime) {
      case 'This Month': return 'Monthly Activity';
      case 'This Year': return 'Yearly Activity';
      case 'This Week':
      default: return 'Weekly Activity';
    }
  }

  // 🔴 2. ฟังก์ชันวาดกราฟจากข้อมูลจริง
  Widget _buildDynamicChart() {
    List<Widget> bars = [];
    
    // หาค่าสูงสุดเพื่อเอามาเทียบสัดส่วนกราฟ (กันกราฟทะลุกรอบ)
    int maxValue = _chartData.values.isEmpty ? 1 : _chartData.values.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) maxValue = 1; // ป้องกันหารด้วย 0

    // วาดแท่งกราฟทีละแท่งจากข้อมูลจริง
    _chartData.forEach((label, count) {
      // คำนวณความสูง (สัดส่วนจาก 0.0 - 1.0)
      double heightRatio = count / maxValue;
      bars.add(_buildBarGroup(label, heightRatio, count)); 
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bars,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // ให้โปร่งใสเพื่อโชว์ Gradient ด้านล่าง
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
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    // 1. Header (แก้ไขให้กลับมาใช้โครงสร้างเดิมของคุณ)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
                        ),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_fire_department, color: Color(0xFFFF9500), size: 36),
                            SizedBox(width: 8),
                            Text(
                              'Activity',
                              style: TextStyle(color: Color(0xFFFF9500), fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro'),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24), // บาลานซ์ปุ่ม Back
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 2. Dropdown
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: Center(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedTime,
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                            style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro'),
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            onChanged: (String? newValue) {
                              if (newValue != null && newValue != _selectedTime) {
                                setState(() {
                                  _selectedTime = newValue;
                                });
                                _fetchActivityData(); // 🔴 ดึงข้อมูลใหม่เมื่อเปลี่ยน Time Range
                              }
                            },
                            items: _timeOptions.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Stat Cards (ใช้ข้อมูลจริง)
                    Row(
                      children: [
                        Expanded(child: _buildStatCard(title: 'Total Quizzes\nTaken', value: '$_totalQuizzes', unit: '', titleColor: Colors.redAccent)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatCard(title: 'Total Time\nSpent', value: '-', unit: ' Hr', titleColor: Colors.lightBlue)), // เวลาใส่ - ไว้ก่อน
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 4. Streak Card (จำลองไว้ก่อน)
                    Row(
                      children: [
                        Expanded(child: _buildStatCard(title: 'Streak', value: '1', unit: ' Day', titleColor: const Color(0xFFFF9500))),
                        const SizedBox(width: 16),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 5. Dynamic Chart Area (ใช้ข้อมูลจริง)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: const Color(0xFFF2F5F8), borderRadius: BorderRadius.circular(24)),
                      child: Column(
                        children: [
                          Text(_getChartTitle(), style: const TextStyle(color: Color(0xFFFF9500), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 200,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // แกน Y แบบอัตโนมัติตามค่าสูงสุด
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _yAxisLabel(_getMaxValue().toString()),
                                    _yAxisLabel((_getMaxValue() * 0.75).toInt().toString()),
                                    _yAxisLabel((_getMaxValue() * 0.5).toInt().toString()),
                                    _yAxisLabel((_getMaxValue() * 0.25).toInt().toString()),
                                    _yAxisLabel('0'),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: _buildDynamicChart()), 
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  // ตัวช่วยหาค่าสูงสุดแกน Y
  int _getMaxValue() {
    if (_chartData.isEmpty) return 10;
    int max = _chartData.values.reduce((a, b) => a > b ? a : b);
    return max == 0 ? 10 : max;
  }

  Widget _yAxisLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 10, color: Colors.black54));
  }

  Widget _buildStatCard({required String title, required String value, required String unit, required Color titleColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')),
                if (unit.isNotEmpty) Text(unit, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔴 ปรับแท่งกราฟให้แสดง 1 แท่งต่อ 1 ค่า (เพราะเราไม่ได้แยกประเภท Quiz ย่อยๆ ในหน้า Activity)
  Widget _buildBarGroup(String label, double heightRatio, int realCount) {
    // ป้องกันกราฟเตี้ยเกินไปจนมองไม่เห็น
    double finalHeight = heightRatio > 0 ? heightRatio : 0.05;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // แสดงตัวเลขไว้บนกราฟถ้ามีค่า
        if (realCount > 0)
           Text('$realCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 4),
        Container(
          width: 12, // เพิ่มขนาดความกว้างกราฟนิดนึง
          height: 150 * finalHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            // เปลี่ยนสีเป็นโทนเขียวตามดีไซน์หลัก
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF55E37D), Color(0xFF1E8F43)]),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black87, fontFamily: 'SF-Pro')),
      ],
    );
  }
}