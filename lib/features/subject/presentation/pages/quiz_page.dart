import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; 
import 'result_page.dart';

class QuizPage extends StatefulWidget {
  final String subjectId; 
  final String setId;     

  const QuizPage({super.key, required this.subjectId, required this.setId});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int score = 0; 
  int currentQuestionIndex = 0; 

  List<Map<String, dynamic>> questions = []; 
  // 🔴 1. สร้าง List เพื่อเก็บ "คำตอบของทุกข้อ" (ค่า -1 คือยังไม่ได้ตอบ)
  List<int> userAnswers = []; 
  bool isLoading = true;

  Timer? _timer;
  int _timeSpentInSeconds = 0; 
  int _timeLimitInSeconds = 0; 

  @override
  void initState() {
    super.initState();
    _loadQuestionsAndTime(); 
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuestionsAndTime() async {
    try {
      var setDoc = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('sets')
          .doc(widget.setId)
          .get();

      int timeLimitMins = 10; 
      if (setDoc.exists && setDoc.data()!.containsKey('timeLimitMins')) {
        timeLimitMins = setDoc.data()!['timeLimitMins'] as int;
      }

      var snapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('sets')
          .doc(widget.setId)
          .collection("questions")
          .get();

      if (mounted) {
        setState(() {
          questions = snapshot.docs.map((doc) => doc.data()).toList();
          // 🔴 2. สร้างกล่องเก็บคำตอบให้เท่ากับจำนวนข้อสอบที่มี (ใส่ค่าเริ่มต้นเป็น -1)
          userAnswers = List.filled(questions.length, -1);
          _timeLimitInSeconds = timeLimitMins * 60; 
          isLoading = false;
        });

        if (questions.isNotEmpty) {
          _startTimer();
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeSpentInSeconds++; 
      });
      
      if (_timeLimitInSeconds > 0 && _timeSpentInSeconds >= _timeLimitInSeconds) {
        _timer?.cancel();
        _submitQuiz(isTimeUp: true); 
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    String minsStr = minutes.toString().padLeft(2, '0');
    String secsStr = remainingSeconds.toString().padLeft(2, '0');
    return "$minsStr:$secsStr";
  }

  void _submitQuiz({bool isTimeUp = false}) {
    if (isTimeUp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⏰ Time is up! Submitting your quiz...", style: TextStyle(fontFamily: 'SF-Pro')),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
    }

    _timer?.cancel();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ResultPage(
        score: score, 
        totalQuestions: questions.length, 
        subjectId: widget.subjectId,
        setId: widget.setId,
        timeSpent: _timeSpentInSeconds, 
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔴 3. เช็คว่าข้อปัจจุบัน "ตอบไปแล้วหรือยัง" โดยดูจากค่าใน userAnswers
    bool hasAnsweredCurrent = userAnswers.isNotEmpty && userAnswers[currentQuestionIndex] != -1;
    int currentSelected = userAnswers.isNotEmpty ? userAnswers[currentQuestionIndex] : -1;

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
            isLoading ? "Loading..." : "Question ${currentQuestionIndex + 1}/${questions.length}", 
            style: const TextStyle(color: Colors.white, fontFamily: 'SF-Pro', fontWeight: FontWeight.bold)
          ),
          actions: [
            if (!isLoading && questions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (_timeLimitInSeconds - _timeSpentInSeconds <= 60) 
                         ? Colors.redAccent 
                         : Colors.white.withOpacity(0.2), 
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(_timeSpentInSeconds), 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro', fontSize: 16),
                    ),
                  ],
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.white)) 
              : questions.isEmpty 
                  ? const Center(child: Text("ไม่พบข้อสอบในระบบ", style: TextStyle(color: Colors.white)))
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(questions[currentQuestionIndex]['questionText'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'SF-Pro', height: 1.5)),
                          const SizedBox(height: 24),

                          ...List.generate(
                            (questions[currentQuestionIndex]['options'] as List).length,
                            (index) {
                              List<dynamic> options = questions[currentQuestionIndex]['options'];
                              int correctIndex = questions[currentQuestionIndex]['correctAnswerIndex'];
                              return _choice(
                                options[index].toString(), 
                                index, 
                                correctIndex, 
                                hasAnsweredCurrent, 
                                currentSelected
                              );
                            },
                          ),
                          const SizedBox(height: 20),

                          if (hasAnsweredCurrent)
                            Center(
                              child: Container(
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: currentSelected == questions[currentQuestionIndex]['correctAnswerIndex'] ? Colors.greenAccent : Colors.redAccent,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  currentSelected == questions[currentQuestionIndex]['correctAnswerIndex']
                                      ? "Correct! 🎉"
                                      : "Incorrect\nCorrect answer: ${questions[currentQuestionIndex]['options'][questions[currentQuestionIndex]['correctAnswerIndex']]}",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: currentSelected == questions[currentQuestionIndex]['correctAnswerIndex'] ? Colors.greenAccent : Colors.redAccent,
                                    fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro'
                                  ),
                                ),
                              ),
                            ),
                          const Spacer(),

                          // 🔴 4. เพิ่มปุ่ม Back ควบคู่ไปกับปุ่ม Next
                          Row(
                            children: [
                              if (currentQuestionIndex > 0) ...[
                                Expanded(
                                  flex: 1,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white.withOpacity(0.2), 
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      elevation: 0,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        currentQuestionIndex--; // ถอยหลัง 1 ข้อ
                                      });
                                    },
                                    child: const Text("Back", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: hasAnsweredCurrent ? const Color(0xFF0A2A66) : Colors.grey[400], 
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    elevation: hasAnsweredCurrent ? 6 : 0,
                                  ),
                                  onPressed: hasAnsweredCurrent ? () {
                                    if (currentQuestionIndex < questions.length - 1) {
                                      setState(() {
                                        currentQuestionIndex++; // ไปข้อถัดไป
                                      });
                                    } else {
                                      _submitQuiz(); // ส่งข้อสอบ
                                    }
                                  } : null,
                                  child: Text(
                                    currentQuestionIndex < questions.length - 1 ? "Next Question" : "Finish Quiz", 
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  // 🔴 อัปเดตฟังก์ชันรับพารามิเตอร์เพิ่ม เพื่อให้มันรู้สถานะของข้อปัจจุบัน
  Widget _choice(String text, int index, int correctIndex, bool hasAnsweredCurrent, int currentSelected) {
    return GestureDetector(
      onTap: () {
        // ถ้าตอบไปแล้ว ห้ามกดเปลี่ยนคำตอบอีก
        if (hasAnsweredCurrent) return;
        
        setState(() {
          userAnswers[currentQuestionIndex] = index; // บันทึกคำตอบลงในกล่อง
          if (index == correctIndex) {
            score++;
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getColor(index, correctIndex, hasAnsweredCurrent, currentSelected),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black12, width: 1.5), 
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(text, style: const TextStyle(color: Colors.black, fontSize: 16, fontFamily: 'SF-Pro', fontWeight: FontWeight.w500))),
            if (hasAnsweredCurrent && index == correctIndex) const Icon(Icons.check_circle, color: Colors.green)
            else if (hasAnsweredCurrent && index == currentSelected && index != correctIndex) const Icon(Icons.cancel, color: Colors.red),
          ],
        ),
      ),
    );
  }

  Color _getColor(int index, int correctIndex, bool hasAnsweredCurrent, int currentSelected) {
    if (!hasAnsweredCurrent) return Colors.white.withOpacity(0.95);
    if (index == correctIndex) return Colors.green.shade100; 
    if (index == currentSelected && index != correctIndex) return Colors.red.shade100; 
    return Colors.white.withOpacity(0.4); 
  }
}