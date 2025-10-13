import 'package:flutter/material.dart';
import 'package:changsure/core/button/primary_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _onStartPressed() {
    // เมื่อกดปุ่ม จะเปลี่ยนไปยังหน้าใหม่
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: PrimaryButton(
              text: 'เริ่มต้นใช้งาน',
              onPressed: _onStartPressed, // เรียกฟังก์ชันเมื่อกด
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ สร้างหน้าถัดไปไว้ทดสอบ
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1E88E5);
    const Color googleButtonColor = Colors.white;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'ลงชื่อเข้าสู่ระบบ',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              'กรุณากรอกชื่อผู้ใช้และรหัสผ่าน',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            const Text(
              'ชื่อผู้ใช้',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                // ข้อความภายในช่องกรอก
                hintText: 'Somchai1234Zaza',
                // กำหนดขอบเขตและมุมโค้งมน
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                // ปรับขอบเขตเมื่อโฟกัส (เพื่อให้เป็นสีน้ำเงินตามรูป)
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: primaryBlue, width: 2.0),
                ),
                // เพิ่ม padding ภายใน
                contentPadding: EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 12.0,
                ),
              ),
              // ตัวอย่างการใส่ค่าเริ่มต้น
              controller: TextEditingController(text: 'Somchai1234Zaza'),
            ),
            const SizedBox(height: 20),

            // ### ช่องกรอกรหัสผ่าน (Password) ###
            const Text(
              'รหัสผ่าน',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              obscureText: true, // ซ่อนรหัสผ่าน
              decoration: InputDecoration(
                hintText: '********',
                // ข้อความภายในช่องกรอก
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: primaryBlue, width: 2.0),
                ),
                // Icon แสดง/ซ่อนรหัสผ่าน
                suffixIcon: IconButton(
                  icon: const Icon(Icons.visibility_off, color: Colors.grey),
                  onPressed: () {
                    // TODO: ใส่ Logic สลับการแสดงรหัสผ่าน
                  },
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 12.0,
                ),
              ),
              controller: TextEditingController(text: '********'),
            ),
            const SizedBox(height: 10),

            // ลืมรหัสผ่าน
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // TODO: Logic ไปหน้าลืมรหัสผ่าน
                },
                child: const Text(
                  'Forgot Password ?',
                  style: TextStyle(color: Color(0xFF4096FF)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ### ปุ่มเข้าสู่ระบบ (Login Button) ###
            Align(
              alignment: Alignment.centerRight,
              child: PrimaryButton(
                text: 'เริ่มต้นใช้งาน',
                onPressed: () {
                  // กดแล้วไปไหน
                }
              ),
            ),

            const SizedBox(height: 20),

            // ### ส่วน "หรือ" (OR Divider) ###
            const Row(
              children: <Widget>[
                Expanded(child: Divider(color: Colors.grey)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text('หรือ', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 20),

            // ### ปุ่มเข้าสู่ระบบด้วย Google ###
            OutlinedButton(
              onPressed: () {
                // TODO: Logic เข้าสู่ระบบด้วย Google
              },
              style: OutlinedButton.styleFrom(
                // กำหนดขนาด
                minimumSize: const Size(double.infinity, 56),
                // กำหนดมุมโค้งมน
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                // สีขอบและขอบเขต
                side: const BorderSide(color: Colors.grey, width: 1.0),
                backgroundColor: googleButtonColor,
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Icon Google (ต้องเพิ่ม Asset เอง หรือใช้ package)
                  // ตัวอย่างใช้ Icon มาตรฐานแทน
                  const Icon(Icons.g_mobiledata, color: Colors.blue, size: 30),
                  const SizedBox(width: 10),
                  const Text(
                    'เข้าสู่ระบบด้วย Google',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // ตั้งค่าสีตัวอักษร
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),

            // ### ส่วนลงทะเบียน (Sign Up) ###
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'ยังไม่มีบัญชีผู้ใช้?',
                  style: TextStyle(fontSize: 16),
                ),
                // TextButton สำหรับลงทะเบียน
                TextButton(
                  onPressed: () {
                    // TODO: Logic ไปหน้าลงทะเบียน
                  },
                  child: const Text(
                    'ลงทะเบียนเลย',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue, // ตั้งค่าสี
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
