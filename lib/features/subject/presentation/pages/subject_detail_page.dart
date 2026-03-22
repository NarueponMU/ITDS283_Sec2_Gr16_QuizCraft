import 'package:flutter/material.dart';
import 'quiz_page.dart';

class SubjectDetailPage extends StatelessWidget {
  final String title;

  const SubjectDetailPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF003E99),
            Color(0xFF0053CC),
            Color(0xFF227CFF),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [

                // Title ใหญ่
                const Text(
                  "Python Programming",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                // Description
                const Text(
                  "This course includes basic programming concepts such as variables, loops, conditions, and functions.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 20),

                // Progress Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your Progress",
                        style: TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Complete 2/10 sets",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Best Score : 80 %",
                        style: TextStyle(
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Sets
                _setItem(context, "Set 1: Variables & Data Types"),
                _setItem(context, "Set 2: IF-Else"),
                _setItem(context, "Set 3: Loops"),
                _setItem(context, "Set 4: Functions"),
                _setItem(context, "Set 5: OOP Basics"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _setItem(BuildContext context, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),

                // จำนวนข้อ + เวลา
                const Text(
                  "10 questions • 5 mins",
                  style: TextStyle(
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          // 🔹 BUTTON
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuizPage()),
              );
            },
            child: const Text("Start"),
          ),
        ],
      ),
    );
  }
}