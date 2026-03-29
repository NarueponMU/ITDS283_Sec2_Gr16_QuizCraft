import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';

class PdfViewerPage extends StatelessWidget {
  final String title;
  final String pdfUrl;
  final bool isDarkMode; // 1. สร้างตัวแปรรับไม้ต่อ (isDarkMode)

  const PdfViewerPage({
    super.key,
    required this.title,
    required this.pdfUrl,
    required this.isDarkMode, // 2. รับค่าเข้ามาใน Constructor
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // เปลี่ยนสีพื้นหลังขอบๆ (Area ที่ไม่ใช่ PDF) ตามโหมด
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF2F5F8), 
      appBar: AppBar(
        // เปลี่ยนสีแถบ AppBar ตามโหมด
        backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFF003E99), 
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          title, 
          style: const TextStyle(color: Colors.white, fontFamily: 'SF-Pro', fontSize: 16),
        ),
      ),
      body: PDF(
        enableSwipe: true,
        swipeHorizontal: false, 
        
        // 1. เปลี่ยน autoSpacing เป็น true เพื่อให้มีช่องว่างระหว่างหน้าสไลด์นิดนึง จะได้ดูไม่อึดอัด
        autoSpacing: true, 
        pageFling: false,
        nightMode: isDarkMode, 

        // 2. เพิ่ม 2 บรรทัดนี้ เพื่อบังคับให้ PDF ขยายเต็มความกว้างหน้าจอเสมอ!
        fitEachPage: true, 
        fitPolicy: FitPolicy.WIDTH,

      ).cachedFromUrl(
        pdfUrl,
        placeholder: (progress) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: isDarkMode ? Colors.white70 : const Color(0xFF4FA0FF)),
              const SizedBox(height: 16),
              Text(
                'Loading PDF... $progress%', 
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black87, 
                  fontFamily: 'SF-Pro'
                ),
              ),
            ],
          ),
        ),
        errorWidget: (error) => Center(
          child: Text(
            'Error loading file:\n$error', 
            textAlign: TextAlign.center, 
            style: const TextStyle(color: Colors.redAccent, fontFamily: 'SF-Pro'),
          ),
        ),
      ),
    );
  }
}