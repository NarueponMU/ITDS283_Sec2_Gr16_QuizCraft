import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // 🔴 Import url_launcher สำหรับเปิดไฟล์

class EbookDetailPage extends StatelessWidget {
  final String courseTitle;
  final String description;
  final List<String> pdfFiles;

  const EbookDetailPage({
    super.key,
    required this.courseTitle,
    required this.description,
    required this.pdfFiles,
  });

  // 🔴 ฟังก์ชันสำหรับเปิด PDF
  Future<void> _openPdf(BuildContext context, String pdfString) async {
    // เช็คว่าสตริงที่ส่งมาเป็น URL ของจริงหรือไม่ (เริ่มด้วย http)
    if (pdfString.startsWith('http://') || pdfString.startsWith('https://')) {
      final Uri url = Uri.parse(pdfString);
      try {
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          throw Exception('Could not launch $url');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ไม่สามารถเปิดไฟล์ PDF ได้', style: TextStyle(fontFamily: 'SF-Pro')),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } else {
      // 🌟 ถ้ายังไม่ใช่ URL (เป็นแค่ชื่อไฟล์จำลอง) ให้ขึ้นแจ้งเตือนไปก่อน
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('กำลังเปิดไฟล์: $pdfString\n(เตรียมพร้อมเชื่อมต่อลิงก์จริงจาก Firebase)', style: const TextStyle(fontFamily: 'SF-Pro')),
            backgroundColor: const Color(0xFF4FA0FF),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B6DF9), 
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 1. Header 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Text(
                      courseTitle,
                      style: const TextStyle(
                        color: Color(0xFFFFB03A), 
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SF-Pro', 
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Course Description Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20.0),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F5F8), 
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF4FA0FF), width: 3), 
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Course Description',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: 'SF-Pro',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5, 
                      fontFamily: 'SF-Pro',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. PDF Files List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemCount: pdfFiles.length,
                itemBuilder: (context, index) {
                  // 🔴 เปลี่ยนมาใช้ InkWell ครอบ เพื่อให้กดได้และมีเอฟเฟกต์
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                      ]
                    ),
                    clipBehavior: Clip.antiAlias, // ตัดขอบ InkWell ไม่ให้ล้น
                    child: InkWell(
                      onTap: () => _openPdf(context, pdfFiles[index]), // 🔴 เรียกใช้ฟังก์ชันเปิด PDF
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 🔴 เพิ่มไอคอน PDF ให้ดูสวยงามขึ้น
                            const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                pdfFiles[index],
                                style: const TextStyle(
                                  color: Color(0xFF4FA0FF), 
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'SF-Pro',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.download_rounded, color: Colors.black54), // เปลี่ยนไอคอนเป็นรูปดาวน์โหลด
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ], 
        ),
      ),
    );
  }
}