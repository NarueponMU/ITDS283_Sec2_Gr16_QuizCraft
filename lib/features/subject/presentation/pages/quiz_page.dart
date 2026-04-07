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
  int currentQuestionIndex = 0; 
  List<Map<String, dynamic>> questions = []; 
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
      if (mounted) {
        setState(() {
          _timeSpentInSeconds++; 
        });
        
        if (_timeLimitInSeconds > 0 && _timeSpentInSeconds >= _timeLimitInSeconds) {
          _timer?.cancel();
          _submitQuiz(isTimeUp: true); 
        }
      }
    });
  }

  // ปรับการแสดงผลเป็น "เวลาที่เหลือ" (Count Down)
  String _formatTime(int totalSeconds, int spentSeconds) {
    int remaining = totalSeconds - spentSeconds;
    if (remaining < 0) remaining = 0;
    
    int minutes = remaining ~/ 60;
    int seconds = remaining % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  void _submitQuiz({bool isTimeUp = false}) {
    _timer?.cancel();
    
    if (!mounted) return;

    if (isTimeUp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Time is up!", style: TextStyle(fontFamily: 'SF-Pro')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    // คำนวณคะแนนตอนส่งทีเดียว เพื่อความแม่นยำ
    int finalScore = 0;
    for (int i = 0; i < questions.length; i++) {
      if (userAnswers[i] == questions[i]['correctAnswerIndex']) {
        finalScore++;
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ResultPage(
        score: finalScore, 
        totalQuestions: questions.length, 
        subjectId: widget.subjectId,
        setId: widget.setId,
        timeSpent: _timeSpentInSeconds, 
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            isLoading ? "Loading..." : "Q: ${currentQuestionIndex + 1}/${questions.length}", 
            style: const TextStyle(color: Colors.white, fontFamily: 'SF-Pro', fontWeight: FontWeight.bold)
          ),
          actions: [
            if (!isLoading && questions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (_timeLimitInSeconds - _timeSpentInSeconds <= 30) 
                         ? Colors.redAccent.withOpacity(0.8) 
                         : Colors.black26, 
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(_timeLimitInSeconds, _timeSpentInSeconds), 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro'),
                    ),
                  ],
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.white)) 
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          questions[currentQuestionIndex]['questionText'] ?? '', 
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'SF-Pro', height: 1.5)
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Choices
                      Expanded(
                        child: ListView(
                          children: List.generate(
                            (questions[currentQuestionIndex]['options'] as List).length,
                            (index) {
                              List<dynamic> options = questions[currentQuestionIndex]['options'];
                              int correctIndex = questions[currentQuestionIndex]['correctAnswerIndex'];
                              return _choice(options[index].toString(), index, correctIndex, hasAnsweredCurrent, currentSelected);
                            },
                          ),
                        ),
                      ),

                      // Navigation Buttons
                      Row(
                        children: [
                          if (currentQuestionIndex > 0) ...[
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                ),
                                onPressed: () => setState(() => currentQuestionIndex--),
                                child: const Text("Back", style: TextStyle(color: Colors.white, fontFamily: 'SF-Pro')),
                              ),
                            ),
                            const SizedBox(width: 15),
                          ],
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hasAnsweredCurrent ? const Color(0xFFFFB03A) : Colors.grey[400], 
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              onPressed: hasAnsweredCurrent ? () {
                                if (currentQuestionIndex < questions.length - 1) {
                                  setState(() => currentQuestionIndex++);
                                } else {
                                  _submitQuiz();
                                }
                              } : null,
                              child: Text(
                                currentQuestionIndex < questions.length - 1 ? "Next Question" : "Finish Quiz", 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')
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

  Widget _choice(String text, int index, int correctIndex, bool hasAnsweredCurrent, int currentSelected) {
    return GestureDetector(
      onTap: () {
        if (hasAnsweredCurrent) return;
        setState(() {
          userAnswers[currentQuestionIndex] = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getColor(index, correctIndex, hasAnsweredCurrent, currentSelected),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: hasAnsweredCurrent && index == correctIndex ? Colors.green : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(text, style: TextStyle(color: hasAnsweredCurrent ? Colors.black87 : Colors.black, fontSize: 16, fontFamily: 'SF-Pro'))),
            if (hasAnsweredCurrent && index == correctIndex) const Icon(Icons.check_circle, color: Colors.green)
            else if (hasAnsweredCurrent && index == currentSelected && index != correctIndex) const Icon(Icons.cancel, color: Colors.red),
          ],
        ),
      ),
    );
  }

  Color _getColor(int index, int correctIndex, bool hasAnsweredCurrent, int currentSelected) {
    if (!hasAnsweredCurrent) return Colors.white;
    if (index == correctIndex) return Colors.green.shade100; 
    if (index == currentSelected && index != correctIndex) return Colors.red.shade100; 
    return Colors.white.withOpacity(0.5); 
  }
}