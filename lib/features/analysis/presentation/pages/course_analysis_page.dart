import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart'; 

class CourseAnalysisPage extends StatefulWidget {
  const CourseAnalysisPage({super.key});

  @override
  State<CourseAnalysisPage> createState() => _CourseAnalysisPageState();
}

class _CourseAnalysisPageState extends State<CourseAnalysisPage> {
  List<Map<String, dynamic>> _subjects = [];
  String? _selectedSubjectId;
  bool _isLoadingSubjects = true;

  // เพิ่มตัวแปรเก็บ Future เพื่อไม่ให้โหลด Firebase ซ้ำๆ เวลากระตุก
  Future<Map<String, dynamic>>? _courseDataFuture;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('subjects').get();
      final subs = snap.docs.map((d) => {
        'id': d.id, 
        'code': d['code'], 
        'name': d['name']
      }).toList();

      if (subs.isNotEmpty) {
        setState(() {
          _subjects = subs;
          _selectedSubjectId = subs.first['id']; 
          _isLoadingSubjects = false;
          // เรียกโหลดข้อมูลข้อสอบครั้งแรก หลังจากได้วิชาเริ่มต้นแล้ว
          _courseDataFuture = _fetchCourseData();
        });
      } else {
        setState(() => _isLoadingSubjects = false);
      }
    } catch (e) {
      setState(() => _isLoadingSubjects = false);
    }
  }

  Future<Map<String, dynamic>> _fetchCourseData() async {
    if (_selectedSubjectId == null) return {};
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final scoresSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('scores')
        .get();

    Map<String, int> setScores = {'set1': 0, 'set2': 0, 'set3': 0, 'set4': 0};
    int completedSets = 0;

    for (var doc in scoresSnap.docs) {
      if (doc.id.startsWith('${_selectedSubjectId}_')) {
        String setId = doc.id.split('_')[1]; 
        setScores[setId] = doc.data()['bestScore'] ?? 0;
        completedSets++;
      }
    }

    List<List<Color>> colorsList = [
      [const Color(0xFFF96D52), const Color(0xFFF4C873)], 
      [const Color(0xFF8F70FF), const Color(0xFF56E0E0)], 
      [const Color(0xFF1ED6B4), const Color(0xFF1CB5E0)], 
      [const Color(0xFF7F00FF), const Color(0xFFE100FF)], 
    ];

    List<Map<String, dynamic>> setProgress = [
      {'name': 'Set 1', 'score': setScores['set1']!, 'colors': colorsList[0]},
      {'name': 'Set 2', 'score': setScores['set2']!, 'colors': colorsList[1]},
      {'name': 'Set 3', 'score': setScores['set3']!, 'colors': colorsList[2]},
      {'name': 'Set 4', 'score': setScores['set4']!, 'colors': colorsList[3]},
    ];

    final historySnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('history')
        .orderBy('timestamp') 
        .get();

    int totalAttempts = 0;
    double sumPercent = 0;
    double bestPercent = 0;
    List<FlSpot> scoreSpots = []; 
    List<FlSpot> avgSpots = [];   

    int index = 0;
    double runningSum = 0;
    for (var doc in historySnap.docs) {
      var data = doc.data();
      if (data['subjectId'] == _selectedSubjectId) {
        totalAttempts++;
        int score = data['score'] ?? 0;
        int tq = data['totalQuestions'] ?? 20;
        double p = tq > 0 ? (score / tq) * 100 : 0;

        sumPercent += p;
        runningSum += p;
        if (p > bestPercent) bestPercent = p;

        scoreSpots.add(FlSpot(index.toDouble(), p));
        avgSpots.add(FlSpot(index.toDouble(), runningSum / totalAttempts)); 
        index++;
      }
    }

    if (totalAttempts == 0) {
      scoreSpots = [const FlSpot(0, 0), const FlSpot(1, 0)];
      avgSpots = [const FlSpot(0, 0), const FlSpot(1, 0)];
    } else if (totalAttempts == 1) {
      scoreSpots.add(FlSpot(1, scoreSpots[0].y));
      avgSpots.add(FlSpot(1, avgSpots[0].y));
    }

    double avgScore = totalAttempts > 0 ? sumPercent / totalAttempts : 0.0;
    double completionRate = (completedSets / 4.0) * 100.0; 

    return {
      'totalAttempts': totalAttempts,
      'avgScore': avgScore,
      'bestScore': bestPercent,
      'completionRate': completionRate > 100 ? 100.0 : completionRate,
      'setProgress': setProgress,
      'scoreSpots': scoreSpots,
      'avgSpots': avgSpots,
    };
  }

  @override
  Widget build(BuildContext context) {
    String currentSubjectName = 'Course';
    if (_selectedSubjectId != null && _subjects.isNotEmpty) {
      var subj = _subjects.firstWhere((s) => s['id'] == _selectedSubjectId);
      currentSubjectName = '${subj['code']} ${subj['name']}'; 
    }

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
          child: _isLoadingSubjects 
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : FutureBuilder<Map<String, dynamic>>(
            future: _courseDataFuture, // เปลี่ยนมาเรียกใช้ตัวแปร Future ที่ล็อคค่าไว้แล้ว
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }

              final data = snapshot.data ?? {};
              final totalAttempts = data['totalAttempts'] ?? 0;
              final avgScore = (data['avgScore'] ?? 0.0).toStringAsFixed(0);
              final bestScore = (data['bestScore'] ?? 0.0).toStringAsFixed(0);
              final completionRate = (data['completionRate'] ?? 0.0).toStringAsFixed(0);
              final List<Map<String, dynamic>> setProgress = data['setProgress'] ?? [];
              final List<FlSpot> scoreSpots = data['scoreSpots'] ?? [const FlSpot(0, 0)];
              final List<FlSpot> avgSpots = data['avgSpots'] ?? [const FlSpot(0, 0)];

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center, 
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
                            ),
                          ),
                        ),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_fire_department, color: Color(0xFFFF9500), size: 36),
                            SizedBox(width: 8),
                            Text('Courses', style: TextStyle(color: Color(0xFFFF9500), fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')),
                          ],
                        ),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                      child: Autocomplete<Map<String, dynamic>>(
                        displayStringForOption: (option) => '${option['code']} ${option['name']}',
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return _subjects; 
                          }
                          return _subjects.where((subj) {
                            final String full = '${subj['code']} ${subj['name']}';
                            return full.toLowerCase().contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        onSelected: (Map<String, dynamic> selection) {
                          setState(() {
                            _selectedSubjectId = selection['id'];
                            // โหลด Future ใหม่เฉพาะตอนที่ผู้ใช้กดเลือกวิชาใหม่เท่านั้น
                            _courseDataFuture = _fetchCourseData();
                          });
                        },
                        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            style: const TextStyle(fontFamily: 'SF-Pro', color: Colors.black87),
                            decoration: const InputDecoration(
                              hintText: 'Search Course',
                              hintStyle: TextStyle(color: Colors.grey, fontFamily: 'SF-Pro'),
                              prefixIcon: Icon(Icons.search, color: Colors.black87),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 15),
                            ),
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              color: Colors.transparent,
                              child: Container(
                                width: MediaQuery.of(context).size.width - 40,
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                                ),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final option = options.elementAt(index);
                                    return ListTile(
                                      title: Text('${option['code']} ${option['name']}', style: const TextStyle(fontFamily: 'SF-Pro', fontSize: 14)),
                                      onTap: () => onSelected(option),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(color: const Color(0xFFF2F5F8), borderRadius: BorderRadius.circular(30)),
                      child: Center(
                        child: Text(
                          currentSubjectName, 
                          style: const TextStyle(color: Color(0xFFFF9500), fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis, 
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: const Color(0xFFF2F5F8), borderRadius: BorderRadius.circular(24)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildStatCard('Total\nAttempts', '$totalAttempts', '', Icons.replay_circle_filled_rounded, const Color(0xFFF96D52))), 
                              const SizedBox(width: 16),
                              Expanded(child: _buildStatCard('Average\nScore', avgScore, ' %', Icons.analytics_rounded, const Color(0xFF8F70FF))), 
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildStatCard('Best\nScore', bestScore, ' %', Icons.emoji_events_rounded, const Color(0xFFFF9500))), 
                              const SizedBox(width: 16),
                              Expanded(child: _buildStatCard('Completion\nRate', completionRate, ' %', Icons.check_circle_rounded, const Color(0xFF1ED6B4))), 
                            ],
                          ),
                          const SizedBox(height: 24), 

                          const Text('Course Process', style: TextStyle(color: Color(0xFFFF9500), fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')),
                          const SizedBox(height: 16),
                          
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: const Color(0xFFE2E6EC), borderRadius: BorderRadius.circular(20)),
                            child: Column(
                              children: setProgress.map((setInfo) {
                                double prog = setInfo['score'] / 20.0;
                                if (prog > 1.0) prog = 1.0;
                                return _buildProgressRow(
                                  setInfo['name'], 
                                  prog, 
                                  '${setInfo['score']}/20',
                                  setInfo['colors']
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 30),

                          SizedBox(
                            height: 180,
                            child: LineChart(
                              LineChartData(
                                // ล็อคแกน Y ไว้ที่ 0-100 สเกลจะได้คงที่สวยงาม
                                minY: 0,
                                maxY: 100,
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade400, strokeWidth: 1.5, dashArray: [5, 5]),
                                ),
                                titlesData: FlTitlesData(show: false),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border(
                                    left: BorderSide(color: Colors.grey.shade500, width: 1.5),
                                    bottom: BorderSide(color: Colors.grey.shade500, width: 1.5),
                                  ),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: avgSpots,
                                    isCurved: true,
                                    color: const Color(0xFF8F70FF),
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: const FlDotData(show: true), // เปิดจุดให้กราฟดูมีมิติ
                                    belowBarData: BarAreaData(show: false),
                                  ),
                                  LineChartBarData(
                                    spots: scoreSpots,
                                    isCurved: true,
                                    color: const Color(0xFFF96D52),
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: const FlDotData(show: true), // เปิดจุดให้กราฟดูมีมิติ
                                    belowBarData: BarAreaData(show: false),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const SizedBox(width: 20),
                              _buildLegendDot(const Color(0xFFF96D52), 'Score'),
                              const SizedBox(width: 40),
                              _buildLegendDot(const Color(0xFF8F70FF), 'Average Score'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            }
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String unit, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1), 
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: accentColor.withOpacity(0.2), width: 1.5), 
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black54, 
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SF-Pro'
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.bottomRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 26, 
                    fontWeight: FontWeight.w900, 
                    fontFamily: 'SF-Pro',
                    color: accentColor, 
                  )
                ),
                if (unit.isNotEmpty)
                  Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SF-Pro',
                      color: Colors.black45,
                    )
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, double progress, String ratioText, List<Color> gradientColors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4FA0FF), fontFamily: 'SF-Pro')),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      height: 8,
                      width: constraints.maxWidth,
                      decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10)),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: constraints.maxWidth * progress,
                          decoration: BoxDecoration(gradient: LinearGradient(colors: gradientColors), borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 45, 
                child: Text(ratioText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'SF-Pro'), textAlign: TextAlign.right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')),
      ],
    );
  }
}