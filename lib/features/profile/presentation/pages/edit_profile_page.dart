import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // 🔴 Import Storage
import 'package:image_picker/image_picker.dart'; // 🔴 Import Image Picker
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;
  bool _isFetching = true;
  String? _photoUrl;

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();

        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _nameController.text = userData['fullName'] ?? '';
            _emailController.text = currentUser!.email ?? '';
            _photoUrl = userData['photoUrl'];
            _isFetching = false;
          });
        }
      } catch (e) {
        setState(() => _isFetching = false);
      }
    }
  }

  // 🔴 ฟังก์ชันเปิดกล้อง (เหมือนหน้า Profile)
  Future<void> _takePhoto() async {
    Navigator.pop(context); 
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera, 
      maxWidth: 500,
      imageQuality: 80,
    );

    if (photo != null) {
      _uploadImageToFirebase(File(photo.path));
    }
  }

  // 🔴 ฟังก์ชันอัปโหลดรูปขึ้น Storage
  Future<void> _uploadImageToFirebase(File imageFile) async {
    if (currentUser == null) return;
    setState(() => _isLoading = true);
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${currentUser!.uid}.jpg');

      await storageRef.putFile(imageFile);
      final String downloadUrl = await storageRef.getDownloadURL();

      setState(() {
        _photoUrl = downloadUrl; // โชว์เป็นพรีวิวก่อน (ยังไม่เซฟลง Database)
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปโหลดรูปภาพ')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔴 เพิ่มปุ่มกล้องในหน้าต่างเลือก Avatar
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
              
              // 🔴 ปุ่มถ่ายรูป
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
                  onPressed: _takePhoto,
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
                        setState(() {
                          _photoUrl = _avatarOptions[index]; // พรีวิวรูป
                        });
                        Navigator.pop(context);
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

  Future<void> _saveChanges() async {
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> updateData = {};

      if (_nameController.text.isNotEmpty) {
        updateData['fullName'] = _nameController.text.trim();
      }
      if (_photoUrl != null) {
        updateData['photoUrl'] = _photoUrl;
      }

      // บันทึกข้อมูลที่แก้ไขลง Firestore
      if (updateData.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .update(updateData);
      }

      // ตรวจสอบการเปลี่ยนรหัสผ่าน
      if (_passwordController.text.isNotEmpty) {
        await currentUser!.updatePassword(_passwordController.text.trim());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profile updated successfully!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'SF-Pro',
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'An error occurred.';
      if (e.code == 'weak-password') {
        msg = 'The password must be at least 6 characters long.';
      }
      if (e.code == 'requires-recent-login') {
        msg = 'Please log out and log back in to change your password.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to save data',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'SF-Pro',
              ),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
          child: _isFetching
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                          const Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'SF-Pro',
                            ),
                          ),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                      const SizedBox(height: 40),

                      GestureDetector(
                        onTap: _showAvatarPicker,
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: _photoUrl != null
                                    ? NetworkImage(_photoUrl!)
                                    : null,
                                child: _photoUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.grey,
                                        size: 50,
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B6DF9), 
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 16,
                                ), 
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        _nameController.text.isNotEmpty
                            ? _nameController.text
                            : 'Student',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SF-Pro',
                        ),
                      ),
                      Text(
                        _emailController.text,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontFamily: 'SF-Pro',
                        ),
                      ),
                      const SizedBox(height: 40),

                      _buildTextField(
                        controller: _nameController,
                        prefixIcon: Icons.person_outline,
                        hintText: 'FULL NAME',
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _emailController,
                        prefixIcon: Icons.mail_outline,
                        hintText: 'EMAIL',
                        readOnly: true,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _passwordController,
                        prefixIcon: Icons.lock_outline,
                        hintText: 'NEW PASSWORD',
                        isPassword: true,
                      ),
                      const SizedBox(height: 40),

                      GestureDetector(
                        onTap: _isLoading ? null : _saveChanges,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF003380),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'SAVE CHANGES',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'SF-Pro',
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData prefixIcon,
    required String hintText,
    bool isPassword = false,
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: readOnly ? Colors.grey[300] : const Color(0xFFF2F5F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        readOnly: readOnly,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'SF-Pro',
          color: readOnly ? Colors.grey[600] : Colors.black87,
        ),
        onChanged: (value) {
          if (hintText == 'FULL NAME') {
            setState(() {});
          }
        },
        decoration: InputDecoration(
          prefixIcon: Icon(prefixIcon, color: Colors.grey[500], size: 24),
          suffixIcon: readOnly
              ? null
              : Icon(Icons.edit_outlined, color: Colors.grey[400], size: 20),
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontFamily: 'SF-Pro',
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    );
  }
}