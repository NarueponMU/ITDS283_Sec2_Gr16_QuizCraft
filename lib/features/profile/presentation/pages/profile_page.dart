import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // 🔴 1. Import Storage
import 'package:image_picker/image_picker.dart'; // 🔴 2. Import Image Picker
import 'dart:io';
import 'edit_profile_page.dart';
import 'logout_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  final List<String> _avatarOptions = [
    'https://api.dicebear.com/7.x/adventurer/png?seed=Felix&backgroundColor=b6e3f4',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Aneka&backgroundColor=ffdfbf',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Mimi&backgroundColor=c0aede',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Jack&backgroundColor=d1d4f9',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Oliver&backgroundColor=b6e3f4',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Sophie&backgroundColor=ffdfbf',
    'https://api.dicebear.com/7.x/bottts/png?seed=Robot1&backgroundColor=c0aede',
    'https://api.dicebear.com/7.x/bottts/png?seed=Robot2&backgroundColor=d1d4f9',
  ];

  // 🔴 3. ฟังก์ชันสำหรับเปิดกล้องถ่ายรูป
  Future<void> _takePhoto() async {
    Navigator.pop(context); // ปิดหน้าต่าง Pop-up ก่อน
    
    final ImagePicker picker = ImagePicker();
    // เรียกใช้ Camera Sensor
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera, // เลือกเปิดกล้อง
      maxWidth: 500, // ย่อขนาดรูปลงหน่อย จะได้อัปโหลดไวๆ
      imageQuality: 80,
    );

    if (photo != null) {
      _uploadImageToFirebase(File(photo.path));
    }
  }

  // 🔴 4. ฟังก์ชันอัปโหลดรูปที่ถ่ายขึ้น Firebase Storage
  Future<void> _uploadImageToFirebase(File imageFile) async {
    if (currentUser == null) return;

    setState(() => _isLoading = true);
    try {
      // สร้างที่เก็บรูปใน Storage: profile_pictures/uid.jpg
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${currentUser!.uid}.jpg');

      // อัปโหลดไฟล์
      await storageRef.putFile(imageFile);
      
      // ดึงลิงก์ URL รูปที่อัปโหลดเสร็จแล้ว
      final String downloadUrl = await storageRef.getDownloadURL();

      // บันทึกลิงก์ URL ลงใน Firestore เหมือนรูป Avatar ปกติ
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({'photoUrl': downloadUrl});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 ถ่ายรูปโปรไฟล์สำเร็จ!', style: TextStyle(fontFamily: 'SF-Pro')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เกิดข้อผิดพลาดในการอัปโหลดรูป', style: TextStyle(fontFamily: 'SF-Pro')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ฟังก์ชันอัปเดตลิงก์รูป Avatar (ของเดิม)
  Future<void> _updateAvatar(String selectedUrl) async {
    if (currentUser == null) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({'photoUrl': selectedUrl});
    } catch (e) {
      // Error handling...
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔴 5. ปรับหน้าต่างเลือกรูป ให้มีปุ่มกล้องด้วย
  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Your Avatar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SF-Pro',
                ),
              ),
              const SizedBox(height: 20),
              
              // 🔴 ปุ่มถ่ายรูปจากกล้อง
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take a Photo', style: TextStyle(fontFamily: 'SF-Pro', fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0053CC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _takePhoto, // เรียกฟังก์ชันเปิดกล้อง
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text('OR CHOOSE AVATAR', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
              ),

              // ตารางรูป Avatar (ของเดิม)
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, 
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _avatarOptions.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context); 
                        _updateAvatar(_avatarOptions[index]); 
                      },
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(_avatarOptions[index]),
                        backgroundColor: Colors.grey[200],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SF-Pro',
                  ),
                ),
                const SizedBox(height: 30),

                if (currentUser != null)
                  StreamBuilder<DocumentSnapshot>( // 🔴 6. เปลี่ยน FutureBuilder เป็น StreamBuilder เพื่อให้รูปเปลี่ยนทันทีออโต้!
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser!.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      String fullName = 'Loading...';
                      String email = currentUser!.email ?? '';
                      String studentId = '';
                      String? photoUrl; 

                      if (snapshot.hasData && snapshot.data!.exists) {
                        var userData = snapshot.data!.data() as Map<String, dynamic>;
                        fullName = userData['fullName'] ?? 'Guest';
                        studentId = userData['studentId'] ?? '';
                        photoUrl = userData['photoUrl']; 
                      }

                      return Column(
                        children: [
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: _isLoading ? null : _showAvatarPicker, 
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 120,
                                          height: 120,
                                          child: CircularProgressIndicator(),
                                        )
                                      : CircleAvatar(
                                          radius: 60,
                                          backgroundColor: Colors.grey[300],
                                          backgroundImage: photoUrl != null
                                              ? NetworkImage(photoUrl)
                                              : null,
                                          child: photoUrl == null
                                              ? const Icon(Icons.person, size: 80, color: Colors.grey)
                                              : null,
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 5,
                                right: 5,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: photoUrl != null ? Colors.green : Colors.grey[800],
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const SizedBox(width: 5, height: 5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'SF-Pro',
                            ),
                          ),
                          Text(
                            email,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontFamily: 'SF-Pro',
                            ),
                          ),
                          if (studentId.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'ID: $studentId',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                                fontFamily: 'SF-Pro',
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),

                const SizedBox(height: 50),
                _buildProfileMenu(
                  icon: Icons.settings_outlined,
                  title: 'Edit Profile',
                  showArrow: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfilePage(),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _buildAccountSecurity(),
                const SizedBox(height: 30),
                _buildProfileMenu(
                  icon: Icons.logout,
                  title: 'Logout',
                  showArrow: false,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LogoutPage()),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileMenu({
    required IconData icon,
    required String title,
    required bool showArrow,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF-Pro',
              ),
            ),
          ),
          if (showArrow)
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 18,
            ),
        ],
      ),
    );
  }

  Widget _buildAccountSecurity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.white, size: 32),
            const SizedBox(width: 20),
            const Text(
              'Account Security',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF-Pro',
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.only(left: 52),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const LinearProgressIndicator(
                  value: 0.8,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Excellent',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontFamily: 'SF-Pro',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}