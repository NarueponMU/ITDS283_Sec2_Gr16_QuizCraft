import 'package:flutter/material.dart'; 
import 'pdf_viewer_page.dart';

class EbookDetailPage extends StatelessWidget {
  final String courseTitle;
  final String description;
  final List<String> pdfFiles;
  final bool isDarkMode;

  const EbookDetailPage({
    super.key,
    required this.courseTitle,
    required this.description,
    required this.pdfFiles,
    required this.isDarkMode,
  });

  Future<void> _openPdf(BuildContext context, String pdfString, String fileName) async {
    if (pdfString.startsWith('http://') || pdfString.startsWith('https://')) {
      // เปลี่ยนจากการเด้งออกนอกแอป เป็นการเปิดหน้า PdfViewerPage แทน!
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerPage(
            title: fileName,
            pdfUrl: pdfString,
            isDarkMode: isDarkMode,
          ),
        ),
      );
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening file: $pdfString\n(Get ready to connect the real link.)', style: const TextStyle(fontFamily: 'SF-Pro')),
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
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFF1B6DF9), 
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
                  // 1. ดึง URL เต็มๆ มาก่อน
                  String fullUrl = pdfFiles[index];
                  
                  // 2. สับเอาเฉพาะคำที่อยู่หลัง / ตัวสุดท้าย (นั่นคือชื่อไฟล์)
                  // และใช้ replaceAll แปลง %20 ให้กลับเป็นช่องว่าง
                  String fileName = fullUrl.split('/').last.replaceAll('%20', ' ');

                  // ถ้าชื่อไฟล์ดึงไม่ได้หรือไม่มีนามสกุล .pdf ให้ใช้คำว่า Document แทน
                  if (!fileName.toLowerCase().contains('.pdf')) {
                    fileName = 'Document ${index + 1}';
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                      ]
                    ),
                    clipBehavior: Clip.antiAlias, 
                    child: InkWell(
                      // 3. ตอนกดเปิด ให้ส่ง URL เต็มๆ ไปให้ระบบหลังบ้านเปิดทำงาน
                      onTap: () => _openPdf(context, fullUrl, fileName),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                // 4. โชว์แค่ชื่อไฟล์สวยๆ สั้นๆ บนหน้าจอ
                                fileName,
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
                            const Icon(Icons.download_rounded, color: Colors.black54),
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