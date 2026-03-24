import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔴 Import Firestore
import 'result_page.dart';

class QuizPage extends StatefulWidget {
  final String subjectId; // 🔴 รับ ID วิชา
  final String setId;     // 🔴 รับ ID ชุดข้อสอบ

  const QuizPage({super.key, required this.subjectId, required this.setId});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int selected = -1;
  bool answered = false;
  int score = 0; // 🔴 ตัวแปรเก็บคะแนนสะสม
  int currentQuestionIndex = 0; // 🔴 ตัวแปรจำว่าอยู่ข้อที่เท่าไหร่

  List<Map<String, dynamic>> questions = []; // 🔴 กล่องเก็บข้อสอบทั้งหมด
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions(); // 🔴 โหลดข้อสอบทันทีที่เปิดหน้านี้
  }

  // 🔴 ฟังก์ชันดึงข้อสอบจาก Firebase
  Future<void> _loadQuestions() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('sets')
          .doc(widget.setId)
          .collection('questions')
          .get();

      if (mounted) {
        setState(() {
          // เอาข้อมูลที่ดึงมาใส่ใน List
          questions = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF003E99), Color(0xFF0053CC), Color(0xFF227CFF)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            // 🔴 แสดงให้รู้ว่าทำถึงข้อไหนแล้ว
            isLoading ? "Loading..." : "Question ${currentQuestionIndex + 1}/${questions.length}", 
            style: const TextStyle(color: Colors.white, fontFamily: 'SF-Pro', fontWeight: FontWeight.bold)
          ),
        ),

        body: SafeArea(
          child: isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.white)) // หมุนรอตอนโหลด
              : questions.isEmpty 
                  ? const Center(child: Text("ไม่พบข้อสอบในระบบ", style: TextStyle(color: Colors.white)))
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔴 แสดงโจทย์
                          Text(
                            questions[currentQuestionIndex]['questionText'] ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'SF-Pro', height: 1.5),
                          ),

                          const SizedBox(height: 24),

                          // 🔴 วนลูปสร้างตัวเลือก ก ข ค ง อัตโนมัติจาก Firebase
                          ...List.generate(
                            (questions[currentQuestionIndex]['options'] as List).length,
                            (index) {
                              List<dynamic> options = questions[currentQuestionIndex]['options'];
                              int correctIndex = questions[currentQuestionIndex]['correctAnswerIndex'];
                              return _choice(options[index].toString(), index, correctIndex);
                            },
                          ),

                          const SizedBox(height: 20),

                          // RESULT BOX
                          if (answered)
                            Center(
                              child: Container(
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected == questions[currentQuestionIndex]['correctAnswerIndex']
                                        ? Colors.green
                                        : Colors.red,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  selected == questions[currentQuestionIndex]['correctAnswerIndex']
                                      ? "Correct! 🎉"
                                      : "Incorrect\nCorrect answer: ${questions[currentQuestionIndex]['options'][questions[currentQuestionIndex]['correctAnswerIndex']]}",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selected == questions[currentQuestionIndex]['correctAnswerIndex']
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'SF-Pro'
                                  ),
                                ),
                              ),
                            ),

                          const Spacer(),

                          // NEXT BUTTON 
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: answered ? const Color(0xFF0A2A66) : Colors.grey[400], // ถ้ายังไม่ตอบให้ปุ่มเป็นสีเทา
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 6,
                              ),
                              onPressed: () {
                                if (!answered) return; // 🔴 บังคับให้ตอบก่อนถึงจะกด Next ได้

                                // ถ้ายังไม่ถึงข้อสุดท้าย ให้ไปข้อต่อไป
                                if (currentQuestionIndex < questions.length - 1) {
                                  setState(() {
                                    currentQuestionIndex++;
                                    answered = false; // รีเซ็ตสถานะการตอบ
                                    selected = -1;
                                  });
                                } else {
                                  // 🔴 ถ้าถึงข้อสุดท้ายแล้ว ให้ไปหน้า Result พร้อมส่งคะแนนไป
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => ResultPage(
                                      // TODO: ส่งคะแนนไปหน้า Result
                                      score: score, // ส่งคะแนนที่ได้
                                      totalQuestions: questions.length, // ส่งจำนวนข้อทั้งหมด
                                      subjectId: widget.subjectId,
                                      setId: widget.setId,
                                    )),
                                  );
                                }
                              },
                              child: Text(
                                // เปลี่ยนข้อความปุ่มถ้าเป็นข้อสุดท้าย
                                currentQuestionIndex < questions.length - 1 ? "Next Question" : "Finish Quiz", 
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  // 🔴 ปรับ _choice ให้รับ correctIndex มาเช็คด้วย
  Widget _choice(String text, int index, int correctIndex) {
    return GestureDetector(
      onTap: () {
        if (answered) return;

        setState(() {
          selected = index;
          answered = true;
          // 🔴 ถ้าตอบถูก ให้บวกคะแนน
          if (selected == correctIndex) {
            score++;
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getColor(index, correctIndex),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(text, style: const TextStyle(color: Colors.black, fontSize: 16, fontFamily: 'SF-Pro'))),
            if (answered && index == correctIndex)
              const Icon(Icons.check, color: Colors.black)
            else if (answered && index == selected && index != correctIndex)
              const Icon(Icons.close, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Color _getColor(int index, int correctIndex) {
    if (!answered) {
      return Colors.white.withOpacity(0.8);
    }
    if (index == correctIndex) {
      return Colors.green.shade400; // ตอบถูกสีเขียว
    }
    if (index == selected && index != correctIndex) {
      return Colors.red.shade400; // ตอบผิดสีแดง
    }
    return Colors.white.withOpacity(0.4); // ข้ออื่นที่ไม่ได้เลือกให้ดรอปสีลง
  }
}