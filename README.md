# 📚 QuizCraft (DST Practice Platform)

**QuizCraft** คือแอปพลิเคชันบนมือถือที่พัฒนาด้วย Flutter ออกแบบมาเพื่อยกระดับประสบการณ์การเรียนรู้ของนักศึกษา ตัวแอปทำหน้าที่เป็นแพลตฟอร์มฝึกทำข้อสอบแบบอินเทอร์แอคทีฟ ที่รวบรวมทั้งชุดข้อสอบ เอกสารประกอบการเรียน และระบบติดตามความคืบหน้าไว้ในที่เดียว

โปรเจกต์นี้ตอบโจทย์เป้าหมายการพัฒนาที่ยั่งยืน **SDG 4: Quality Education (การศึกษาที่เท่าเทียมและมีคุณภาพ)** โดยการจัดหาแหล่งเรียนรู้และเครื่องมือฝึกฝนที่เข้าถึงง่าย เพื่อช่วยให้นักศึกษาเข้าใจบทเรียนและเตรียมตัวสอบได้ดียิ่งขึ้น

---

## ✨ Key Features

* **🔒 ระบบยืนยันตัวตน (Secure Authentication):** สมัครสมาชิกและเข้าสู่ระบบอย่างปลอดภัยด้วย Firebase Authentication
* **📝 ระบบข้อสอบอัจฉริยะ (Interactive Quiz System):** มีระบบตรวจคำตอบทันที (Instant Feedback), ระบบจับเวลา, และคำนวณคะแนนอัตโนมัติ เพื่อจำลองบรรยากาศการสอบจริง
* **📊 วิเคราะห์สถิติผู้เรียน (Performance Analysis):** ติดตามความคืบหน้าและดูแนวโน้มคะแนนสอบผ่านกราฟ (Data Visualization) ที่สวยงามและเข้าใจง่าย
* **📖 คลังเอกสาร (E-Book Integration):** มีระบบเปิดอ่านไฟล์ชีทเรียนและเอกสาร PDF ภายในตัวแอป
* **👤 จัดการโปรไฟล์ (Customizable Profiles):** ผู้ใช้สามารถอัปเดตข้อมูลส่วนตัวและอัปโหลดรูปโปรไฟล์ได้ (ผสานการทำงานร่วมกับ ImgBB API)
* **🌗 UI/UX อัจฉริยะ (Smart UI):** ดีไซน์ทันสมัยแบบ Glassmorphism พร้อมฟีเจอร์ลับ "เขย่ามือถือเพื่อสลับโหมด Dark/Light" (ใช้เซนเซอร์ Accelerometer)
<p align="center">
  <img width="200" alt="Screen 1" src="https://github.com/user-attachments/assets/472c1263-ec56-4715-bee4-e3543ad91af5" />
  <img width="200" alt="Screen 2" src="https://github.com/user-attachments/assets/e73a977e-e76d-44aa-9c1c-feafdea4cf72" />
  <img width="200" alt="Screen 3" src="https://github.com/user-attachments/assets/7d2ba27e-a053-4729-a7f9-489e1bc626a3" />
  <img width="200" height="1434" alt="IMG_7490" src="https://github.com/user-attachments/assets/83b05873-6f26-4bec-bbbc-0158866dc477" />
</p>

## 🛠️ Technology Stack

* **Frontend:** Flutter (Dart)
* **Backend as a Service (BaaS):** Firebase (Authentication, Cloud Firestore)
* **State Management:** Flutter Stateful/Stateless Widgets
* **แพ็กเกจหลักที่สำคัญ:**
    * `fl_chart` (สำหรับวาดกราฟสถิติ)
    * `flutter_cached_pdfview` (สำหรับระบบเปิดอ่าน PDF)
    * `shake` (สำหรับตรวจจับการเขย่ามือถือ)
    * `image_picker` & `http` (สำหรับจัดการรูปภาพและเชื่อมต่อ API)

## 👨‍💻 Project Information

แอปพลิเคชันนี้ถูกพัฒนาขึ้นเพื่อเป็นส่วนหนึ่งของรายวิชาเรียน

* **ผู้จัดทำ:** นฤพนธ์ สันติภาพชัย (Naruepon Santipapchai)
* **รหัสนักศึกษา:** ITDS242
* **สถาบัน:** มหาวิทยาลัยมหิดล (Mahidol University)

## 🚀 การติดตั้งและทดลองรัน (Getting Started)

หากต้องการรันโปรเจกต์นี้บนเครื่องของคุณ โปรดตรวจสอบให้แน่ใจว่าได้ติดตั้ง [Flutter](https://flutter.dev/docs/get-started/install) เรียบร้อยแล้ว

1.  **Clone repository นี้ลงเครื่อง**
    ```bash
    git clone [https://github.com/NarueponMU/quizcraft.git](https://github.com/NarueponMU/quizcraft.git)
    ```
2.  **เข้าไปที่โฟลเดอร์โปรเจกต์**
    ```bash
    cd quizcraft
    ```
3.  **ติดตั้ง dependencies ทั้งหมด**
    ```bash
    flutter pub get
    ```
4.  **รันแอปพลิเคชัน**
    ```bash
    flutter run
    ```

*(หมายเหตุ: หากต้องการรันแอป กรุณาตรวจสอบให้แน่ใจว่ามีการตั้งค่าไฟล์เชื่อมต่อ Firebase เช่น `google-services.json` หรือ `GoogleService-Info.plist` ไว้ในโปรเจกต์อย่างถูกต้องแล้ว)*
