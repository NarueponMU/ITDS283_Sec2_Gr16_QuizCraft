import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:quizcraft/features/home/presentation/pages/home_page.dart';
import 'package:quizcraft/features/analysis/presentation/pages/analysis_page.dart';
import 'package:quizcraft/features/profile/presentation/pages/profile_page.dart';
import 'package:quizcraft/features/subject/presentation/pages/subject_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 1. สร้างฟังก์ชันสลับแท็บที่หน้า Home สามารถเรียกใช้ได้
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    //  2. การวาง List หน้าจอไว้ตรงนี้โอเคแล้วสำหรับ callback 
    // แต่ถ้าแอปเริ่มใหญ่ขึ้น แนะนำให้ใช้ IndexedStack ครอบแทน เพื่อรักษา State ของแต่ละหน้าไว้ไม่ให้หายไปตอนสลับแท็บ
    final List<Widget> pages = [
      HomePage(onStartQuiz: () => _onItemTapped(1)), 
      const SubjectPage(),
      const AnalysisPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      extendBody: true, // 🌟 ทะลุผ่านเพื่อเอฟเฟกต์ Glassmorphism
      
      // 3. ใช้ IndexedStack แทน pages[_selectedIndex] 
      // ข้อดี: เวลาเราสลับไปหน้า Analysis แล้วกลับมาหน้า Home หน้า Home จะไม่เริ่มโหลดใหม่ ข้อมูลจะยังอยู่ที่เดิมครับ
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      
      bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(15, 0, 15, 20), // เพิ่มระยะห่างขอบล่างนิดนึงให้ดูเหมือนลอยได้
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0), // ปรับลงมานิดนึงเพื่อให้ลื่นขึ้นบนมือถือทุกรุ่น
              child: Container(
                height: 85,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5), 
                ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(icon: Icons.home_outlined, label: 'Home', index: 0),
                      _buildNavItem(icon: Icons.laptop_mac, label: 'Subject', index: 1), 
                      _buildNavItem(icon: Icons.bar_chart_outlined, label: 'Analysis', index: 2),
                      _buildNavItem(icon: Icons.account_circle_outlined, label: 'Profile', index: 3),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer( // เปลี่ยนเป็น AnimatedContainer เพื่อให้เวลาเลือกแล้วสีค่อยๆ เปลี่ยนดูแพงขึ้น
        duration: const Duration(milliseconds: 300),
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // ถ้าเลือกอยู่ ให้เป็นสีฟ้า ถ้าไม่เลือกให้เป็นสีขาวจางๆ
                color: isSelected ? const Color(0xFF1B6DF9).withOpacity(0.8) : Colors.white.withOpacity(0.1),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'SF-Pro'
              ),
            ),
          ],
        ),
      ),
    );
  }
}