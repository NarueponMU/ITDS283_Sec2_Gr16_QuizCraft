import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  String _selectedTime = 'This Week';
  final List<String> _timeOptions = ['This Week', 'This Month', 'This Year'];

  int _totalQuizzes = 0;
  Map<String, int> _chartData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchActivityData();
  }

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

      if (_selectedTime == 'This Week') {
        for (int i = 6; i >= 0; i--) {
          String day = DateFormat('EEE').format(now.subtract(Duration(days: i)));
          tempChartData[day] = 0;
        }
      } else if (_selectedTime == 'This Month') {
        tempChartData = {'W1': 0, 'W2': 0, 'W3': 0, 'W4': 0};
      } else if (_selectedTime == 'This Year') {
        tempChartData = {'Q1': 0, 'Q2': 0, 'Q3': 0, 'Q4': 0};
      }

      for (var doc in historySnap.docs) {
        var data = doc.data();
        
        // ป้องกันแอปพังถ้าข้อมูลใน Database ไม่ใช่ Timestamp
        if (data['timestamp'] == null || data['timestamp'] is! Timestamp) continue;
        
        DateTime recordDate = (data['timestamp'] as Timestamp).toDate();

        if (_selectedTime == 'This Week') {
          if (now.difference(recordDate).inDays <= 6) {
            totalCount++;
            String dayLabel = DateFormat('EEE').format(recordDate);
            if (tempChartData.containsKey(dayLabel)) {
              tempChartData[dayLabel] = tempChartData[dayLabel]! + 1;
            }
          }
        } else if (_selectedTime == 'This Month') {
          if (recordDate.month == now.month && recordDate.year == now.year) {
            totalCount++;
            int day = recordDate.day;
            if (day <= 7) tempChartData['W1'] = tempChartData['W1']! + 1;
            else if (day <= 14) tempChartData['W2'] = tempChartData['W2']! + 1;
            else if (day <= 21) tempChartData['W3'] = tempChartData['W3']! + 1;
            else tempChartData['W4'] = tempChartData['W4']! + 1;
          }
        } else if (_selectedTime == 'This Year') {
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

  String _getChartTitle() {
    switch (_selectedTime) {
      case 'This Month': return 'Monthly Activity';
      case 'This Year': return 'Yearly Activity';
      case 'This Week':
      default: return 'Weekly Activity';
    }
  }

  Widget _buildDynamicChart() {
    List<Widget> bars = [];
    int maxValue = _getMaxValue(); 

    _chartData.forEach((label, count) {
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
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
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
                        const SizedBox(width: 24),
                      ],
                    ),
                    const SizedBox(height: 24),

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
                                  _isLoading = true; // ให้มีวงกลมโหลดรอตอนเปลี่ยนแท็บ
                                });
                                _fetchActivityData();
                              }
                            },
                            items: _timeOptions.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(child: _buildStatCard(title: 'Total Quizzes\nTaken', value: '$_totalQuizzes', unit: '', titleColor: Colors.redAccent)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatCard(title: 'Total Time\nSpent', value: '-', unit: ' Hr', titleColor: Colors.lightBlue)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(child: _buildStatCard(title: 'Streak', value: '1', unit: ' Day', titleColor: const Color(0xFFFF9500))),
                        const SizedBox(width: 16),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                    const SizedBox(height: 24),

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

  // บังคับเพดานขั้นต่ำไว้ที่ 4 เพื่อไม่ให้แกน Y โชว์เลข 0 ซ้ำๆ กันถ้าคนใช้น้อย
  int _getMaxValue() {
    if (_chartData.isEmpty) return 4;
    int max = _chartData.values.reduce((a, b) => a > b ? a : b);
    return max < 4 ? 4 : max;
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

  // ปรับกราฟให้ถ้าค่าเป็น 0 จะแบนติดพื้นและเป็นสีเทาบางๆ ไม่หลอกตาผู้ใช้
  Widget _buildBarGroup(String label, double heightRatio, int realCount) {
    double finalHeight = heightRatio;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (realCount > 0)
           Text('$realCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 4),
        Container(
          width: 12,
          height: finalHeight > 0 ? (150 * finalHeight) : 2, 
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: finalHeight > 0 
                ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF55E37D), Color(0xFF1E8F43)])
                : const LinearGradient(colors: [Colors.black12, Colors.black12]), 
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black87, fontFamily: 'SF-Pro')),
      ],
    );
  }
}