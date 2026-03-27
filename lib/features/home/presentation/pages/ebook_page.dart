import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // สร้าง Stream สำหรับดึงข้อมูลวิชาทั้งหมดจาก Firebase
  late Stream<QuerySnapshot> _subjectStream;

  @override
  void initState() {
    super.initState();
    _subjectStream = FirebaseFirestore.instance.collection('subjects').snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ฟังก์ชันแยกแยะ Year 1 และ Year 2 จากรหัสวิชา (เช่น ITDS120 -> 1 = Year 1)
  bool _isMatchYear(String code, bool wantYear1) {
    if (code.isEmpty) return false;
    
    // หาวิธีดึงตัวเลขตัวแรกออกมาจากรหัสวิชา (เช่น ITDS120 -> เลข 1)
    final match = RegExp(r'\d').firstMatch(code);
    if (match != null) {
      String firstDigit = match.group(0)!;
      if (wantYear1 && firstDigit == '1') return true;
      if (!wantYear1 && firstDigit == '2') return true;
    }
    return false; // ถ้าไม่ใช่ทั้งคู่ ให้ถือว่าไม่ตรงเงื่อนไข
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF003E99), Color(0xFF0053CC), Color(0xFF227CFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Header (ปุ่ม Back + หัวข้อ)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context), 
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'E-Book',
                          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), 
                  ],
                ),
              ),

              // 2. Search Bar แบบคลีนๆ (ไม่มี Dropdown)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))], 
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    style: const TextStyle(fontFamily: 'SF-Pro', color: Colors.black87, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Search Book...',
                      hintStyle: const TextStyle(color: Colors.grey, fontFamily: 'SF-Pro'),
                      prefixIcon: const Icon(Icons.search, color: Colors.black54),
                      suffixIcon: _searchQuery.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = ""; 
                                });
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
                    Expanded(child: _buildTab('Year 1', isYear1Selected, () {
                      setState(() => isYear1Selected = true);
                    })),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTab('Year 2', !isYear1Selected, () {
                      setState(() => isYear1Selected = false);
                    }, selectedColor: const Color(0xFFE46CF4))), // สีชมพูอมม่วง
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. List of Courses (ดึงจาก Firebase และกรองข้อมูล)
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _subjectStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล', style: TextStyle(color: Colors.white, fontFamily: 'SF-Pro')));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('ไม่พบรายวิชา', style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'SF-Pro')));
                    }

                    final allSubjects = snapshot.data!.docs;

                    // 🔴 กรองข้อมูล 2 ชั้น: ชั้นแรกเช็ค Year, ชั้นสองเช็คคำค้นหา
                    final filteredSubjects = allSubjects.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = (data['name'] ?? '').toString().toLowerCase();
                      final code = (data['code'] ?? '').toString();
                      final fullName = '${code.toLowerCase()} $name'; 
                      
                      // 1. เช็คว่าเป็น Year 1 หรือ Year 2 ตามที่เลือกแท็บไว้หรือไม่
                      bool matchYear = _isMatchYear(code, isYear1Selected);
                      
                      // 2. เช็คคำค้นหา
                      bool matchSearch = fullName.contains(_searchQuery);

                      return matchYear && matchSearch;
                    }).toList();

                    if (filteredSubjects.isEmpty) {
                      return const Center(
                        child: Text(
                          'No E-Books found.', 
                          style: TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'SF-Pro')
                        )
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: filteredSubjects.length,
                      itemBuilder: (context, index) {
                        var subjectData = filteredSubjects[index].data() as Map<String, dynamic>;
                        String code = subjectData['code'] ?? '';
                        String name = subjectData['name'] ?? 'Unknown Subject';
                        
                        // สมมติข้อมูล Description และ PDF ไว้ก่อน (ในอนาคตคุณสามารถเพิ่มฟิลด์นี้ใน Firebase ได้)
                        String description = subjectData['description'] ?? 'Course material for $name. Tap to view documents and PDFs.';
                        List<String> pdfs = [
                          '${code}_Lecture_01.pdf',
                          '${code}_Summary_Notes.pdf',
                        ];

                        return _buildCourseCard(
                          context: context,
                          code: code,
                          title: name,
                          description: description,
                          pdfs: pdfs,
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
        duration: const Duration(milliseconds: 300), // เพิ่มเอฟเฟกต์ตอนกดเปลี่ยนแท็บนิดนึง
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.white.withOpacity(0.9), 
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
              color: isSelected ? Colors.black87 : Colors.black54,
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
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
        ),
        clipBehavior: Clip.antiAlias, 
        child: Column(
          children: [
            Container(
              height: 140, // ปรับความสูงรูปลงนิดนึงให้พอดีจอ
              color: const Color(0xFFE2E6EC), // สีเทาอ่อนให้ดูคลีน
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.menu_book_rounded, size: 60, color: Colors.black26), // เปลี่ยนไอคอนเป็นรูปหนังสือ
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
              color: const Color(0xFF1E293B), // ปรับสีดำให้ดูพรีเมียมขึ้น (Slate 800)
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
                  const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18), // เปลี่ยนเป็นลูกศรเล็กๆ ดูทันสมัย
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}