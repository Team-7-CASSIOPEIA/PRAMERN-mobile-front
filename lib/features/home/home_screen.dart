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
  bool isLoading = true;
  List<Map<String, dynamic>> allTasks = [];

  @override
  void initState() {
    super.initState();
    loadUserData();
    fetchEvaluationTasks();
  }

  Future<void> loadUserData() async {
    try {
      final userData = await _homeController.fetchUserData();
      if (userData != null) {
        setState(() {
          firstName = userData['first_name']!;
          lastName = userData['last_name']!;
          profilePicture = getPicture(userData['profile_picture']!);
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchEvaluationTasks() async {
    setState(() => isLoading = true);
    try {
      // Simulated API response (as per your original code)
      await Future.delayed(const Duration(milliseconds: 800));
      final fetchedTasks = [
        {
          'title': 'ประเมินรอบครั้งที่ 1/2567',
          'status': 'ยังไม่ดำเนินการ',
          'person': 'บรรจงธรรม โชคชัย',
          'daysLeft': 6,
          'id': '1'
        },
        {
          'title': 'ประเมินรอบครั้งที่ 1/2567',
          'status': 'เสร็จสิ้น',
          'person': 'บรรจงธรรม โชคชัย',
          'daysLeft': 6,
          'id': '2'
        },
        {
          'title': 'ประเมินรอบครั้งที่ 1/2567',
          'status': 'ยังไม่ดำเนินการ',
          'person': 'บรรจงธรรม โชคชัย',
          'daysLeft': 6,
          'id': '3'
        },
        {
          'title': 'ประเมินรอบครั้งที่ 1/2567',
          'status': 'เสร็จสิ้น',
          'person': 'บรรจงธรรม โชคชัย',
          'daysLeft': 6,
          'id': '4'
        },
      ];

      setState(() {
        allTasks = fetchedTasks;
        isLoading = false;
      });

      // Commenting out the actual API call to avoid errors
      /*
      final tasks = await _homeController.fetchEvaluationTasks();
      setState(() {
        allTasks = tasks;
        isLoading = false;
      });
      */
    } catch (e) {
      debugPrint('Error fetching evaluation tasks: $e');
      setState(() => isLoading = false);
    }
  }

  String getPicture(String path) {
    return path.isNotEmpty ? "http://localhost:3000$path" : "No Image";
  }

  List<Map<String, dynamic>> get filteredTasks {
    if (selectedTab == 1) {
      return allTasks.where((task) => task['status'] == 'เสร็จสิ้น').toList();
    } else if (selectedTab == 2) {
      return allTasks;
    }
    return allTasks.where((task) => task['status'] == 'ยังไม่ดำเนินการ').toList();
  }

  void _onTaskTap(Map<String, dynamic> task) {
    debugPrint('Tapped on task: ${task['id']}');
    // Example navigation (commented out to avoid errors):
    // Navigator.push(context, MaterialPageRoute(builder: (context) => TaskDetailScreen(taskId: task['id'])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF7367F0)))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    _buildTabBar(),
                    const SizedBox(height: 16),
                    Expanded(
                      child: RefreshIndicator(
                        color: const Color(0xFF7367F0),
                        onRefresh: () async {
                          await fetchEvaluationTasks();
                        },
                        child: filteredTasks.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                itemCount: filteredTasks.length,
                                itemBuilder: (context, index) {
                                  return _buildTaskCard(filteredTasks[index]);
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundImage: profilePicture != "No Image" && profilePicture.isNotEmpty
              ? NetworkImage(profilePicture)
              : const AssetImage('assets/images/person-placeholder.png') as ImageProvider,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            firstName.isNotEmpty ? "$firstName $lastName" : "ชื่อ นามสกุล",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTabButton('ยังไม่ดำเนินการ', 0),
          const SizedBox(width: 8),
          _buildTabButton('เสร็จสิ้น', 1),
          const SizedBox(width: 8),
          _buildTabButton('ทั้งหมด', 2),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = selectedTab == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => selectedTab = index);
          },
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF7367F0) : const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.3,
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'ไม่มีรายการประเมิน${selectedTab == 0 ? "ที่ยังไม่ดำเนินการ" : selectedTab == 1 ? "ที่เสร็จสิ้น" : ""}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final bool isCompleted = task['status'] == 'เสร็จสิ้น';
    final Color statusColor = isCompleted ? Colors.green : const Color(0xFF7367F0);
    final bool isPending = task['status'] == 'ยังไม่ดำเนินการ';

    return GestureDetector(
      onTap: () => _onTaskTap(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task['title'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'ผู้ถูกประเมิน: ',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  Expanded(
                    child: Text(
                      task['person'],
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text(
                    'ระยะเวลาที่เหลือ: ',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  Text(
                    '${task['daysLeft']} วัน',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withOpacity(0.1)
                      : isPending
                          ? const Color(0xFF7367F0).withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  task['status'],
                  style: TextStyle(
                    color: isCompleted
                        ? Colors.green
                        : isPending
                            ? const Color(0xFF7367F0)
                            : Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}