import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pramern/features/home/home_controller.dart';
import 'package:pramern/features/form/form_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    loadUserData();
    fetchEvaluationTasks();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: dotenv.env['ANDROID_BANNER_AD_UNIT_ID']!,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          debugPrint('Ad failed to load: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
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

  void _handleLogout() async {
    await _homeController.logout();

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<void> fetchEvaluationTasks() async {
    setState(() => isLoading = true);
    try {
      setState(() async {
        final tasks = await _homeController.fetchEvaluationData();

        allTasks = tasks ?? [];
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching evaluation tasks: $e');
      setState(() => isLoading = false);
    }
  }

  String getPicture(String path) {
    return path.isNotEmpty ? "${dotenv.env['API_URL']}$path" : "No Image";
  }

  List<Map<String, dynamic>> get filteredTasks {
    if (selectedTab == 1) {
      return allTasks
          .where((task) => task['assign_status'] == 'complete')
          .toList();
    } else if (selectedTab == 2) {
      return allTasks;
    }
    return allTasks
        .where((task) => task['assign_status'] == 'incomplete')
        .toList();
  }

  void _onTaskTap(Map<String, dynamic> task) {
  debugPrint('Tapped on task: ${task['eval_template_id']}');
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => FormScreen(formId: task['eval_template_id'], assignId: task['assign_id'], assigneeId: task['assignee_id']),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
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
            if (_isAdLoaded && _bannerAd != null)
              SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: profilePicture != "No Image" && profilePicture.isNotEmpty
                  ? NetworkImage(profilePicture)
                  : const AssetImage('assets/images/person-placeholder.png') as ImageProvider,
            ),
            const SizedBox(width: 12),
            Text(
              firstName.isNotEmpty ? "$firstName $lastName" : "ชื่อ นามสกุล",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.red),
          onPressed: _handleLogout,
          tooltip: 'Logout',
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
              color: isSelected
                  ? const Color(0xFF7367F0)
                  : const Color(0xFFEEEEEE),
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
              Icon(Icons.assignment_outlined,
                  size: 60, color: Colors.grey[400]),
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
    final bool isCompleted = task['assign_status'] == 'complete';
    final bool isPending = task['assign_status'] == 'incomplete';

    return GestureDetector(
      onTap: () => {
        if(isPending) {
          _onTaskTap(task)
        }
      },
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
                task['eval_name'],
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
                      task['assignee'],
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withOpacity(0.1)
                      : isPending
                          ? const Color(0xFF7367F0).withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  isCompleted
                      ? 'เสร็จสิ้น'
                      : isPending
                          ? 'ยังไม่ดำเนินการ'
                          : 'ไม่ทราบสถานะ',
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
