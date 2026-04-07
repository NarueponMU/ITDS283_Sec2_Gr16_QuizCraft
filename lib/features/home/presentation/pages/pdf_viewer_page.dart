import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';

class PdfViewerPage extends StatelessWidget {
  final String title;
  final String pdfUrl;
  final bool isDarkMode; 

  const PdfViewerPage({
    super.key,
    required this.title,
    required this.pdfUrl,
    required this.isDarkMode, 
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF2F5F8), 
      appBar: AppBar(
        elevation: 0, // ปิดเส้นเงาเพื่อให้ดูคลีนแบบ Modern UI
        backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFF003E99), 
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true, // จัดหัวข้อไว้ตรงกลางให้ดูเป็นระเบียบ
        title: Text(
          title, 
          style: const TextStyle(
            color: Colors.white, 
            fontFamily: 'SF-Pro', 
            fontSize: 16,
            fontWeight: FontWeight.w600
          ),
        ),
      ),
      body: PDF(
        enableSwipe: true,
        swipeHorizontal: false, 
        autoSpacing: true, 
        pageFling: true, // เปิดเป็น true จะทำให้เลื่อนหน้าได้สมูทเหมือนไถ Feed Social
        nightMode: isDarkMode, 
        fitEachPage: true, 
        fitPolicy: FitPolicy.WIDTH,
      ).cachedFromUrl(
        pdfUrl,
        placeholder: (progress) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                value: progress / 100, // แสดงความคืบหน้าบนตัวหมุนด้วย
                color: isDarkMode ? Colors.white70 : const Color(0xFF4FA0FF)
              ),
              const SizedBox(height: 16),
              Text(
                'Loading PDF... ${progress.toInt()}%', // ปรับเป็นเลขจำนวนเต็มให้อ่านง่าย
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black87, 
                  fontFamily: 'SF-Pro',
                  fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
        ),
        errorWidget: (error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Cannot open file:\n$error', 
              textAlign: TextAlign.center, 
              style: const TextStyle(color: Colors.redAccent, fontFamily: 'SF-Pro'),
            ),
          ),
        ),
      ),
    );
  }
}