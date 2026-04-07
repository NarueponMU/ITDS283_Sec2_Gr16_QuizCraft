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
            content: Text('Opening file: $pdfString', style: const TextStyle(fontFamily: 'SF-Pro')),
            backgroundColor: const Color(0xFF4FA0FF),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // กำหนดสีตามโหมด
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF2F5F8);
    final itemColor = isDarkMode ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFF1B6DF9), 
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      courseTitle,
                      style: const TextStyle(
                        color: Color(0xFFFFB03A), 
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SF-Pro', 
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ใช้ Expanded ครอบทับ เพื่อให้ทั้งหน้าเลื่อนขึ้นลงได้หากเนื้อหาเยอะ
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  // Course Description Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor, 
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF4FA0FF), width: 2), 
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Course Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontFamily: 'SF-Pro',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                            height: 1.5, 
                            fontFamily: 'SF-Pro',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Documents',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro'),
                  ),
                  const SizedBox(height: 12),

                  // รายการไฟล์ PDF
                  ...List.generate(pdfFiles.length, (index) {
                    String fullUrl = pdfFiles[index];
                    
                    // 🔴 แก้ไขลอจิกการดึงชื่อไฟล์ให้คลีนขึ้น
                    String fileName = Uri.decodeFull(fullUrl).split('/').last.split('?').first;
                    if (!fileName.toLowerCase().contains('.pdf')) {
                      fileName = 'Document ${index + 1}';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: itemColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                        ]
                      ),
                      clipBehavior: Clip.antiAlias, 
                      child: InkWell(
                        onTap: () => _openPdf(context, fullUrl, fileName),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  fileName,
                                  style: TextStyle(
                                    color: const Color(0xFF4FA0FF), 
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'SF-Pro',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ], 
        ),
      ),
    );
  }
}