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
  final TextEditingController _searchController = TextEditingController();
  late Stream<QuerySnapshot> _subjectStream;

  @override
  void initState() {
    super.initState();
    // ดึงข้อมูลวิชาเรียงตามรหัสวิชาเพื่อให้ดูเป็นระเบียบ
    _subjectStream = FirebaseFirestore.instance.collection('subjects').orderBy('code').snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getIcon(String code) {
    if (code.contains('DS271')) return Icons.security;
    if (code.contains('DS231')) return Icons.wifi;
    if (code.contains('DS261')) return Icons.developer_mode;
    if (code.contains('DS124')) return Icons.functions;
    if (code.contains('DS120')) return Icons.computer;
    return Icons.menu_book_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF003E99), Color(0xFF0053CC), Color(0xFF227CFF)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 10),
                child: Text('Subject', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro')),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))], 
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                    style: const TextStyle(fontFamily: 'SF-Pro', color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Search Course...',
                      prefixIcon: const Icon(Icons.search, color: Colors.black54),
                      suffixIcon: _searchQuery.isNotEmpty 
                          ? IconButton(icon: const Icon(Icons.cancel, color: Colors.grey), onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = "");
                            })
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _subjectStream, 
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }

                    final subjects = snapshot.data?.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final fullName = '${data['code']} ${data['name']}'.toLowerCase();
                      return fullName.contains(_searchQuery);
                    }).toList() ?? [];

                    if (subjects.isEmpty) {
                      return const Center(child: Text('No subjects found.', style: TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'SF-Pro')));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: subjects.length,
                      itemBuilder: (context, index) {
                        var data = subjects[index].data() as Map<String, dynamic>;
                        return _subjectItem(
                          context, 
                          subjects[index].id, 
                          data['code'] ?? '', 
                          data['name'] ?? 'Unknown', 
                          data['difficulty'] ?? 'Medium'
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

  Widget _subjectItem(BuildContext context, String id, String code, String name, String difficulty) {
    Color diffColor = difficulty == 'Hard' ? Colors.red : (difficulty == 'Medium' ? Colors.orange : Colors.green);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material( // 🔴 1. ใช้ Material ครอบเพื่อให้ InkWell แสดงผลรอยกดได้
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        elevation: 4,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubjectDetailPage(subjectId: id, title: name))),
          child: Padding( // 🔴 2. ใช้ Padding แทน Container Margin เพื่อให้รอยกดเต็มพื้นที่การ์ด
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF0F4F8), borderRadius: BorderRadius.circular(15)),
                  child: Icon(_getIcon(code), size: 28, color: const Color(0xFF003E99)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'SF-Pro'), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(difficulty, style: TextStyle(color: diffColor, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'SF-Pro')),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.black26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}