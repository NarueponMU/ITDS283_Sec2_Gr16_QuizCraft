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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. ย้าย List หน้าจอมาไว้ตรงนี้ เพื่อให้ส่งคำสั่งไปหน้า Home ได้
    final List<Widget> pages = [
      HomePage(onStartQuiz: () => _onItemTapped(1)), // ส่งคำสั่งให้สลับไปแท็บที่ 1 (Subject)
      const SubjectPage(),
      const AnalysisPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      extendBody: true, 
      body: pages[_selectedIndex], // 2. เปลี่ยนมาใช้ตัวแปร pages ที่เราเพิ่งสร้าง
      
      bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0), 
              child: Container(
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12), 
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1), 
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
      child: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.2),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontFamily: 'SF-Pro'
              ),
            ),
          ],
        ),
      ),
    );
  }
}