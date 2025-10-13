import 'package:basicflutter/theme.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

//สร้าง widget เอง สำหรับค่าที่ไม่ค่อยมีการเปลี่ยนแปลง
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "My App",
      home: MyHomePage(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

//สร้าง widget เอง สำหรับค่าที่มีการเปลี่ยนแปลงบ่อย
class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int number = 0;

  @override
  Widget build(BuildContext context) {
    List<Widget> data = [];

    // ขกลุ่มข้อมูล Text widget
    for (var i = 0; i < 10; i++) {
      data.add(Text("รายการที่ ${i + 1}"));
    }

    return Scaffold(
      appBar: AppBar(title: Text("Chang Sure")),
      body: ListView.builder(
        itemCount: 15,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(title: Text("เมนูที่ ${index+1}"));
        },
      ),
    );
  }
}
