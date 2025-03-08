import 'package:flutter/material.dart';
import 'package:pramern_mobile_front/features/home/home_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String firstName = '';
  String lastName = '';
  String profilePicture = '';
  final HomeController _homeController = HomeController();
  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

Future<void> loadUserData() async {
  final userData = await _homeController.fetchUserData();
  if (userData != null) {
    setState(() { 
      firstName = userData['first_name']!;
      lastName = userData['last_name']!;
      profilePicture = getPicture(userData['profile_picture']!);
    });
  }
}

String getPicture(String path) {
  return path.isNotEmpty ? "http://localhost:3000$path" : "No Image"; 
}

  final List<Map<String, dynamic>> tasks = [
    {'title': 'ประเมินรอบครั้งที่ 1/2567', 'status': 'ยังไม่ดำเนินการ'},
    {'title': 'ประเมินรอบครั้งที่ 2/2567', 'status': 'เสร็จสิ้น'},
    {'title': 'ประเมินรอบครั้งที่ 3/2567', 'status': 'ยังไม่ดำเนินการ'},
    {'title': 'ประเมินรอบครั้งที่ 4/2567', 'status': 'ทั้งหมด'},
  ];

  List<Map<String, dynamic>> get filteredTasks {
    if (selectedTab == 1) {
      return tasks.where((task) => task['status'] == 'เสร็จสิ้น').toList();
    } else if (selectedTab == 2) {
      return tasks;
    }
    return tasks.where((task) => task['status'] == 'ยังไม่ดำเนินการ').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Ensuring the background is white
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Section
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: profilePicture != "No Image" && profilePicture.isNotEmpty
                      ? NetworkImage(profilePicture)
                      : AssetImage('assets/images/person-placeholder.png') as ImageProvider,
                ),
                const SizedBox(width: 10),
                Text(
                  firstName.isNotEmpty ? "$firstName $lastName" : "ชื่อ นามสกุล",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Tab Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTabButton('ยังไม่ดำเนินการ', 0),
                _buildTabButton('เสร็จสิ้น', 1),
                _buildTabButton('ทั้งหมด', 2),
              ],
            ),
            const SizedBox(height: 20),
            // Task List
            Expanded(
              child: ListView.builder(
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  return _buildTaskCard(filteredTasks[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: selectedTab == index ? const Color(0xFF7367F0) : Colors.grey[300],
        foregroundColor: selectedTab == index ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () {
        setState(() => selectedTab = index);
      },
      child: Text(title, style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text('ผู้ถูกประเมิน: บรรจงธรรม โชคชัย',
                style: TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 5),
            const Text('ระยะเวลาที่เหลือ: 6 วัน',
                style: TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 10),
            Chip(
              label: Text(task['status']),
              backgroundColor: task['status'] == 'ยังไม่ดำเนินการ' ? const Color(0xFF7367F0) : Colors.green,
              labelStyle: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
