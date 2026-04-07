import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shake/shake.dart'; // Import แพ็กเกจ shake
import 'ebook_detail_page.dart';

class EbookPage extends StatefulWidget {
  const EbookPage({super.key});

  @override
  State<EbookPage> createState() => _EbookPageState();
}

class _EbookPageState extends State<EbookPage> {
  bool isYear1Selected = true;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  late Stream<QuerySnapshot> _subjectStream;

  // ตัวแปรสำหรับ Dark Mode และตัวจับการเขย่า
  bool isDarkMode = false;
  ShakeDetector? detector;

  @override
  void initState() {
    super.initState();
    _subjectStream = FirebaseFirestore.instance.collection('subjects').snapshots();
    detector = ShakeDetector.autoStart(
      onPhoneShake: (_) {
        setState(() {
          isDarkMode = !isDarkMode; // สลับโหมด มืด/สว่าง
        });
        
        // เด้งแจ้งเตือนสวยๆ ให้ผู้ใช้รู้
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isDarkMode ? '🌙 Night Shift' : '☀️ Day Shift',
                style: const TextStyle(fontFamily: 'SF-Pro', fontSize: 16),
              ),
              backgroundColor: isDarkMode ? const Color(0xFF4FA0FF) : const Color(0xFFFFB03A),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      shakeThresholdGravity: 2.7, 
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    detector?.stopListening(); // ปิดเซ็นเซอร์เมื่อออกจากหน้านี้ (ประหยัดแบต)
    super.dispose();
  }

  bool _isMatchYear(String code, bool wantYear1) {
    if (code.isEmpty) return false;
    final match = RegExp(r'\d').firstMatch(code);
    if (match != null) {
      String firstDigit = match.group(0)!;
      if (wantYear1 && firstDigit == '1') return true;
      if (!wantYear1 && firstDigit == '2') return true;
    }
    return false; 
  }

  @override
  Widget build(BuildContext context) {
    // กำหนดสีพื้นหลังหลักตามโหมด
    final bgColors = isDarkMode 
        ? [const Color(0xFF121212), const Color(0xFF1E1E1E), const Color(0xFF2C2C2C)] // สี Dark Mode
        : [const Color(0xFF003E99), const Color(0xFF0053CC), const Color(0xFF227CFF)]; // สี Light Mode (น้ำเงินเดิม)

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: AnimatedContainer( // ใช้ AnimatedContainer ให้ตอนเปลี่ยนสีมันค่อยๆ เฟด (Smooth)
        duration: const Duration(milliseconds: 500),
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bgColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Header 
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context), 
                    ),
                    Expanded(
                      child: Center(
                        // ใช้ GestureDetector มาครอบ Text เพื่อทำปุ่มลัดจำลองการเขย่า
                        child: GestureDetector(
                          onLongPress: () {
                            setState(() {
                              isDarkMode = !isDarkMode;
                            });
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isDarkMode ? '🌙 Night Shift' : '☀️ Day Shift',
                                    style: const TextStyle(fontFamily: 'SF-Pro', fontSize: 16),
                                  ),
                                  backgroundColor: isDarkMode ? const Color(0xFF4FA0FF) : const Color(0xFFFFB03A),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'E-Book',
                            style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), 
                  ],
                ),
              ),

              // 2. Search Bar 
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF333333) : Colors.white, // เปลี่ยนสีกล่องค้นหา
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))], 
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                    style: TextStyle(fontFamily: 'SF-Pro', color: isDarkMode ? Colors.white : Colors.black87, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Search Book...',
                      hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.grey, fontFamily: 'SF-Pro'),
                      prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.white54 : Colors.black54),
                      suffixIcon: _searchQuery.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = ""); 
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Tabs (Year 1 / Year 2)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Expanded(child: _buildTab('Year 1', isYear1Selected, () => setState(() => isYear1Selected = true))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTab('Year 2', !isYear1Selected, () => setState(() => isYear1Selected = false), selectedColor: const Color(0xFFE46CF4))), 
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. List of Courses 
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _subjectStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('Course not found', style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'SF-Pro')));
                    }

                    final allSubjects = snapshot.data!.docs;

                    final filteredSubjects = allSubjects.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = (data['name'] ?? '').toString().toLowerCase();
                      final code = (data['code'] ?? '').toString();
                      final fullName = '${code.toLowerCase()} $name'; 
                      
                      bool matchYear = _isMatchYear(code, isYear1Selected);
                      bool matchSearch = fullName.contains(_searchQuery);

                      return matchYear && matchSearch;
                    }).toList();

                    if (filteredSubjects.isEmpty) {
                      return const Center(
                        child: Text('No E-Books found.', style: TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'SF-Pro'))
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: filteredSubjects.length,
                      itemBuilder: (context, index) {
                        var subjectData = filteredSubjects[index].data() as Map<String, dynamic>;
                        String code = subjectData['code'] ?? '';
                        String name = subjectData['name'] ?? 'Unknown Subject';
                        String description = subjectData['description'] ?? 'Course material for $name. Tap to view documents and PDFs.';
                        
                        List<String> pdfs = [];
                        if (subjectData['pdfLinks'] != null) {
                           pdfs = List<String>.from(subjectData['pdfLinks']);
                        }

                        return _buildCourseCard(
                          context: context,
                          code: code,
                          title: name,
                          description: description,
                          pdfs: pdfs,
                          isDarkMode: isDarkMode,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String title, bool isSelected, VoidCallback onTap, {Color selectedColor = const Color(0xFFFFD15C)}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300), 
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? selectedColor 
              : (isDarkMode ? const Color(0xFF333333) : Colors.white.withOpacity(0.9)), // สลับสีตามโหมด
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected 
              ? [BoxShadow(color: selectedColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))] 
              : [],
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected 
                  ? Colors.black87 
                  : (isDarkMode ? Colors.white70 : Colors.black54), // สลับสีตัวหนังสือตามโหมด
              fontFamily: 'SF-Pro'
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard({
    required BuildContext context, 
    required String code, 
    required String title,
    required String description,   
    required List<String> pdfs,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EbookDetailPage(
              courseTitle: title,
              description: description,
              pdfFiles: pdfs,
              isDarkMode: isDarkMode,
            ),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white, // สีการ์ดตามโหมด
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
        ),
        clipBehavior: Clip.antiAlias, 
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: 140, 
              color: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFE2E6EC), // สีพื้นหลังรูป
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.menu_book_rounded, size: 60, color: Colors.black26), 
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.more_horiz, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF1E293B), // สีนี้เข้มอยู่แล้ว เข้ากับทั้ง 2 โหมด
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          code,
                          style: const TextStyle(color: Color(0xFFFFB03A), fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro'),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: const TextStyle(color: Color(0xFF4FA0FF), fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'SF-Pro'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis, 
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18), 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}