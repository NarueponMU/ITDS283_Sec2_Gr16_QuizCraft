import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'subject_detail_page.dart';

class SubjectPage extends StatefulWidget {
  const SubjectPage({super.key});

  @override
  State<SubjectPage> createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  String _searchQuery = "";
  late Stream<QuerySnapshot> _subjectStream;
  
  // 🔴 เพิ่ม Controller เพื่อเอาไว้กดปุ่ม X เคลียร์ข้อความได้
  final TextEditingController _searchController = TextEditingController();

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

  IconData _getIcon(String code) {
    switch (code) {
      case "ITDS120": return Icons.computer;
      case "ITDS124": return Icons.functions;
      case "ITDS191": return Icons.balance; 
      case "ITDS231": return Icons.wifi;
      case "ITDS261": return Icons.developer_mode;
      case "ITDS271": return Icons.security;
      default: return Icons.book;
    }
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

              // กรองข้อมูลการ์ดวิชาตามคำที่พิมพ์
              final filteredSubjects = allSubjects.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                final code = (data['code'] ?? '').toString().toLowerCase();
                final fullName = '$code $name'; 
                
                return fullName.contains(_searchQuery);
              }).toList();

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Subject', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')),
                    const SizedBox(height: 24),

                    // 🔴 SEARCH BAR: เปลี่ยนเป็นกล่องเดี่ยวๆ แบบคลีนๆ ไม่มี Dropdown
                    Container(
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
                          hintText: 'Search Course...',
                          hintStyle: const TextStyle(color: Colors.grey, fontFamily: 'SF-Pro'),
                          prefixIcon: const Icon(Icons.search, color: Colors.black54),
                          // 🔴 ถ้ามีการพิมพ์ข้อความ ให้โชว์ปุ่ม X สำหรับเคลียร์
                          suffixIcon: _searchQuery.isNotEmpty 
                              ? IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = ""; // รีเซ็ตคำค้นหา
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 🔴 ส่วนแสดงการ์ดวิชา (จะกรองและเด้งดึ๋งๆ ตามที่เราพิมพ์เป๊ะๆ)
                    Expanded(
                      child: filteredSubjects.isEmpty
                          ? const Center(
                              child: Text(
                                'No subjects found.', 
                                style: TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'SF-Pro')
                              )
                            )
                          : ListView.builder(
                              itemCount: filteredSubjects.length,
                              itemBuilder: (context, index) {
                                var subjectData = filteredSubjects[index].data() as Map<String, dynamic>;
                                String id = filteredSubjects[index].id;
                                String code = subjectData['code'] ?? '';
                                String name = subjectData['name'] ?? 'Unknown Subject';
                                String difficulty = subjectData['difficulty'] ?? 'Medium';

                                return _subjectItem(context, id, code, name, difficulty);
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _subjectItem(BuildContext context, String id, String code, String name, String difficulty) {
    Color diffColor;
    if (difficulty == 'Hard') {
      diffColor = Colors.red;
    } else if (difficulty == 'Medium') {
      diffColor = Colors.orange;
    } else {
      diffColor = Colors.green;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubjectDetailPage(subjectId: id, title: name), 
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
              child: Icon(_getIcon(code), size: 30, color: Colors.black),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro'), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(difficulty, style: TextStyle(color: diffColor, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ),
    );
  }
}