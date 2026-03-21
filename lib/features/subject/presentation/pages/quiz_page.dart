import 'package:flutter/material.dart';
import 'result_page.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int selected = -1;
  bool answered = false;

  final int correctIndex = 0;

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
          title: const Text("Quiz", style: TextStyle(color: Colors.white)),
        ),

        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Which of the following is correct variable declaration?",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),

                const SizedBox(height: 24),

                _choice("A. variable = 123", 0),
                _choice("B. 123 = variable", 1),
                _choice("C. let variable = 123", 2),
                _choice("D. dim variable as 123", 3),

                const SizedBox(height: 20),

                // 🔥 RESULT BOX
                if (answered)
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected == correctIndex
                              ? Colors.green
                              : Colors.red,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        selected == correctIndex
                            ? "Correct!"
                            : "Incorrect\nCorrect answer: A. variable = 123",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected == correctIndex
                              ? Colors.green
                              : Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                const Spacer(),

                // 🔥 NEXT BUTTON (ยาวเต็ม + ฟ้าเข้ม)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A2A66),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 6,
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const ResultPage()),
                      );
                    },
                    child: const Text("Next", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _choice(String text, int index) {
    return GestureDetector(
      onTap: () {
        if (answered) return;

        setState(() {
          selected = index;
          answered = true;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getColor(index),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 1.5),

          // 🔥 shadow ให้ดู soft
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
            Text(text, style: const TextStyle(color: Colors.black)),

            if (answered && index == correctIndex)
              const Icon(Icons.check, color: Colors.black)
            else if (answered && index == selected && index != correctIndex)
              const Icon(Icons.close, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Color _getColor(int index) {
    if (!answered) {
      // 🔥 ฟ้าอ่อน
      return Colors.white.withOpacity(0.55);
    }

    if (index == correctIndex) {
      return Colors.green;
    }

    if (index == selected && index != correctIndex) {
      return Colors.red;
    }

    return Colors.white.withOpacity(0.6);
  }
}
