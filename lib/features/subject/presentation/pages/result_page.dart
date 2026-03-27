import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'quiz_page.dart';

class ResultPage extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final String subjectId;
  final String setId;

  const ResultPage({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.subjectId,
    required this.setId,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  int bestScore = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _saveAndFetchBestScore();
  }

  // 🔴 ฟังก์ชันบันทึกคะแนน ดึงคะแนนสูงสุด และเก็บประวัติการทำข้อสอบ
  Future<void> _saveAndFetchBestScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 🌟 1. ส่วนที่เพิ่มใหม่: บันทึกประวัติการทำข้อสอบ (Attempt History)
      // สร้าง Document ใหม่ทุกครั้งที่ทำข้อสอบเสร็จ
      final historyRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('history') // สร้าง Subcollection ใหม่ชื่อ history
          .doc(); // ปล่อยว่างไว้ให้ Firebase สร้าง ID สุ่มให้ (จะได้ไม่ทับของเดิม)

      await historyRef.set({
        'subjectId': widget.subjectId,
        'setId': widget.setId,
        'score': widget.score,
        'totalQuestions': widget.totalQuestions,
        'timestamp': FieldValue.serverTimestamp(), // ประทับเวลาจริง
      });

      // 🌟 2. ส่วนของ Best Score (เก็บทับแบบเดิม เพื่อใช้ในหน้าวิชา)
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scores')
          .doc('${widget.subjectId}_${widget.setId}');

      final docSnap = await docRef.get();
      int currentBest = 0;

      if (docSnap.exists) {
        currentBest = docSnap.data()?['bestScore'] ?? 0;
      }

      // ถ้าคะแนนรอบนี้มากกว่าคะแนนสูงสุดเดิม ให้บันทึกทับ
      if (widget.score > currentBest) {
        currentBest = widget.score;
        await docRef.set({
          'bestScore': currentBest,
          'lastUpdated': FieldValue.serverTimestamp()
        }, SetOptions(merge: true));
      }

      if (mounted) {
        setState(() {
          bestScore = currentBest;
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
    // คำนวณเปอร์เซ็นต์เพื่อเช็คว่าผ่านไหม
    double percentage = widget.totalQuestions == 0 ? 0 : (widget.score / widget.totalQuestions) * 100;
    bool isPassed = percentage >= 50;

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
          title: const Text("Quiz Complete", style: TextStyle(color: Colors.white, fontFamily: 'SF-Pro')),
        ),
        body: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // ICON (ถ้าผ่านเป็นดาวเขียว/ทอง ถ้าตกเป็นสีแดง)
                      Icon(
                        isPassed ? Icons.star : Icons.sentiment_dissatisfied,
                        size: 80,
                        color: isPassed ? Colors.amberAccent : Colors.redAccent,
                      ),

                      const SizedBox(height: 20),

                      // TITLE
                      Text(
                        isPassed ? "Congratulations!" : "Keep Trying!",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'SF-Pro'),
                      ),

                      const SizedBox(height: 8),

                      // DESCRIPTION
                      Text(
                        isPassed 
                            ? "You have successfully completed the quiz."
                            : "Don't give up! Review the course and try again.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'SF-Pro'),
                      ),

                      const SizedBox(height: 24),

                      // SCORE CARD
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Score: ${widget.score} / ${widget.totalQuestions}",
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro'),
                            ),
                            const SizedBox(height: 12),
                            
                            _RowItem("Correct Answers", "${widget.score}"),
                            _RowItem("Incorrect Answers", "${widget.totalQuestions - widget.score}"),
                            const _RowItem("Time Used", "-"), 
                            _RowItem("Best Score", "$bestScore/${widget.totalQuestions}"),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // BUTTON 1: Retry Quiz
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A2A66),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => QuizPage(
                                subjectId: widget.subjectId,
                                setId: widget.setId,
                              )),
                            );
                          },
                          child: const Text("Retry Quiz", style: TextStyle(fontSize: 17, fontFamily: 'SF-Pro')),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // BUTTON 2: Back to Course
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A2A66),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("Back to Course", style: TextStyle(fontSize: 17, fontFamily: 'SF-Pro')),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

// ROW ITEM
class _RowItem extends StatelessWidget {
  final String title;
  final String value;

  const _RowItem(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.black54, fontSize: 15, fontFamily: 'SF-Pro')),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'SF-Pro')),
        ],
      ),
    );
  }
}