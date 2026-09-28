import 'dart:convert';
import 'profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import 'business_profile_screen.dart';
import 'create_post_screen.dart';
import 'projects_history_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.userName = 'User',
  });

  final String userName;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryColor = Color(0xFF5B4BDB);
  static const Color backgroundColor = Color(0xFFF8F8FC);
  static const Color textColor = Color(0xFF1F2937);
  static const Color secondaryText = Color(0xFF6B7280);

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  bool _hasBusinessProfile = false;

  String _businessName = '';
  String _businessCategory = '';
  String? _businessLogoUrl;

  bool _isLoadingProjects = true;
  List<dynamic> _recentProjects = [];

  // Today's Idea
  String _todaysIdea = 'Loading today\'s idea...';
  String? _todaysIdeaImageUrl;
  String? _todaysIdeaSourceType;
  String? _todaysIdeaSourceUrl;
  bool _isLoadingIdea = true;

  // AI Usage
  bool _isLoadingUsage = true;
  int _usedAiCredits = 0;
  int _totalAiCredits = 50;

  @override
  void initState() {
    super.initState();

    _loadBusinessProfile().then((_) {
      _loadTodaysIdea();
    });

    _loadRecentProjects();
    _loadAiUsage();
  }

  // ------------------------------------------------------------
  // BUSINESS PROFILE
  // ------------------------------------------------------------

  Future<void> _loadBusinessProfile() async {
    try {
      final token = await _storage.read(key: 'access_token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        return;
      }

      final response = await http.get(
        Uri.parse(
          'https://aibusinesspostmaker-production.up.railway.app/api/business-profile',
          
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true &&
            data['business_profile'] != null) {
          final profile = data['business_profile'];

          if (!mounted) return;

          setState(() {
            _hasBusinessProfile = true;

            _businessName =
                profile['business_name']?.toString() ?? '';

            _businessCategory =
                profile['category']?.toString() ?? '';

            _businessLogoUrl =
                profile['logo_url']?.toString();

            _isLoading = false;
          });

          return;
        }
      }

      if (!mounted) return;

      setState(() {
        _hasBusinessProfile = false;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  // ------------------------------------------------------------
  // RECENT PROJECTS
  // ------------------------------------------------------------

  Future<void> _loadRecentProjects() async {
    try {
      final token = await _storage.read(key: 'access_token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;

        setState(() {
          _isLoadingProjects = false;
        });

        return;
      }

      final response = await http.get(
        Uri.parse(
          'https://aibusinesspostmaker-production.up.railway.app/api/projects',

        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!mounted) return;

        setState(() {
          if (data is List) {
            _recentProjects = data;
          } else if (data is Map) {
            _recentProjects =
                data['projects'] ??
                data['posts'] ??
                [];
          }

          _isLoadingProjects = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          _isLoadingProjects = false;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingProjects = false;
      });
    }
  }


Future<void> _loadTodaysIdea() async {
    try {
      final token = await _storage.read(key: 'access_token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoadingIdea = false;
        });
        return;
      }

      final response = await http.get(
        
        Uri.parse('https://aibusinesspostmaker-production.up.railway.app/api/today-idea'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!mounted) return;
// Yeh line API response aate hi laga dein
setState(() {
  // 1. Idea ka text
  _todaysIdea = data['idea']?['idea']?.toString() ?? 'Create a fresh post...';
  
  // 2. Image URL (agar backend bhej raha ho)
  _todaysIdeaImageUrl = data['idea']?['image_url']?.toString(); 
  
  // 3. Backend se aane wala asli Target URL (No fake links)
  _todaysIdeaSourceUrl = data['idea']?['target_url']?.toString(); 
  
  // 4. Backend se aane wala asli Platform/Source Type (e.g., youtube, instagram)
  _todaysIdeaSourceType = data['idea']?['platform']?.toString() ?? 'Instagram'; 
  
  _isLoadingIdea = false;
});
}else {
        if (!mounted) return;
        setState(() {
          _todaysIdea = 'Create a fresh post based on what is trending in your business category.';
          _isLoadingIdea = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _todaysIdea = 'Create a fresh post based on what is trending in your business category.';
        _isLoadingIdea = false;
      });
    }
  }

  // ------------------------------------------------------------
  // OPEN SOURCE LINK (YouTube / Instagram)
  // ------------------------------------------------------------
  Future<void> _openIdeaSource() async {
    final url = _todaysIdeaSourceUrl;

    if (url == null || url.trim().isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the source link.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the source link.')),
      );
    }
  }

  // ------------------------------------------------------------
  // SOURCE ICON & NAME HELPERS
  // ------------------------------------------------------------
  IconData _getSourceIcon() {
    final source = (_todaysIdeaSourceType ?? '').toLowerCase();
    if (source.contains('youtube')) return Icons.play_circle_fill_rounded;
    if (source.contains('facebook')) return Icons.facebook_rounded;
    if (source.contains('instagram')) return Icons.camera_alt_rounded;
    if (source.contains('google')) return Icons.search_rounded;
    return Icons.open_in_new_rounded;
  }

  String _getSourceName() {
    final source = (_todaysIdeaSourceType ?? '').toLowerCase();
    if (source.contains('youtube')) return 'YouTube';
    if (source.contains('facebook')) return 'Facebook';
    if (source.contains('instagram')) return 'Instagram';
    if (source.contains('google')) return 'Google';
    return 'View Source';
  }


  
  // ------------------------------------------------------------
  // AI USAGE
  // ------------------------------------------------------------

  Future<void> _loadAiUsage() async {
    try {
      final token = await _storage.read(key: 'access_token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;

        setState(() {
          _isLoadingUsage = false;
        });

        return;
      }

      final response = await http.get(
        Uri.parse(
          'https://aibusinesspostmaker-production.up.railway.app/api/ai-usage',
      
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!mounted) return;

        setState(() {
          _usedAiCredits =
              int.tryParse(
                    data['used']?.toString() ?? '0',
                  ) ??
                  0;

_totalAiCredits = int.tryParse(data['limit']?.toString() ?? '50') ?? 50;


          _isLoadingUsage = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          _isLoadingUsage = false;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingUsage = false;
      });
    }
  }

  // ------------------------------------------------------------

  // ------------------------------------------------------------
  // BUSINESS PROFILE
  // ------------------------------------------------------------

  Future<void> _openBusinessProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const BusinessProfileScreen(),
      ),
    );

    if (result == true) {
      await _loadBusinessProfile();
      await _loadTodaysIdea();
    }
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,

        title: const Text(
          'AI Business Post Maker',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),

        actions: const [],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            4,
            20,
            20,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // ------------------------------------------------
              // WELCOME
              // ------------------------------------------------

              RichText(
                text: TextSpan(
                  text: 'Welcome back, ',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: textColor,
                  ),
                  children: [
                    TextSpan(
                      text: widget.userName,
                      style: const TextStyle(
                        color: primaryColor, // Yahan aap apna pasandeeda highlight color de sakte hain
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Ready to create your next stunning post?',
                style: TextStyle(
                  fontSize: 13,
                  color: secondaryText,
                ),
              ),

              const SizedBox(height: 20),
              // ------------------------------------------------
              // BUSINESS PROFILE
              // ------------------------------------------------

              _isLoading
                  ? _loadingBusinessCard()
                  : _hasBusinessProfile
                      ? _businessCard()
                      : _setupBusinessCard(),

              const SizedBox(height: 18),

              // ------------------------------------------------
              // CREATE POST
              // ------------------------------------------------

              SizedBox(
                width: double.infinity,
                height: 50,

                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const CreatePostScreen(),
                      ),
                    );

                    _loadRecentProjects();
                    _loadAiUsage();
                  },

                  icon: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 19,
                  ),

                  label: const Text(
                    'Create New Post',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(11),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ------------------------------------------------
              // RECENT PROJECTS
              // ------------------------------------------------

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                children: [
                  const Text(
                    'Recent Projects',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),

                  TextButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ProjectHistoryScreen(),
                        ),
                      );

                      _loadRecentProjects();
                    },

                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize:
                          const Size(40, 30),
                    ),

                    child: const Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              _isLoadingProjects
                  ? Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(16),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              const Color(0xFFE5E7EB),
                        ),
                      ),

                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,

                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    )
                  : _recentProjects.isNotEmpty
                      ? _buildLatestProjectCard(
                          _recentProjects.first,
                        )
                      : _buildEmptyProjectCard(),

              const SizedBox(height: 20),

              // ------------------------------------------------
              // TODAY'S IDEA
              // ------------------------------------------------

              const Text(
                "Today Idea",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 8),

              _buildTodaysIdeaCard(),

              const SizedBox(height: 14),

              // ------------------------------------------------
              // AI USAGE
              // ------------------------------------------------

              _buildAiUsageCard(),
            ],
          ),
        ),
      ),

      // --------------------------------------------------------
      // BOTTOM NAVIGATION
      // --------------------------------------------------------
bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedItemColor: primaryColor,
        unselectedItemColor: const Color(0xFF9CA3AF),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (index) async {
          if (index == 1) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreatePostScreen(),
              ),
            );

            _loadRecentProjects();
            _loadAiUsage();
          }

          if (index == 2) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProjectHistoryScreen(),
              ),
            );

            _loadRecentProjects();
          }

          if (index == 3) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(),
              ),
            );
            _loadRecentProjects();
            _loadAiUsage();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home_outlined,
              size: 21,
            ),
            activeIcon: Icon(
              Icons.home_rounded,
              size: 21,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.auto_awesome_outlined,
              size: 21,
            ),
            activeIcon: Icon(
              Icons.auto_awesome_rounded,
              size: 21,
            ),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.folder_outlined,
              size: 21,
            ),
            activeIcon: Icon(
              Icons.folder_rounded,
              size: 21,
            ),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person_outline_rounded,
              size: 21,
            ),
            activeIcon: Icon(
              Icons.person_rounded,
              size: 21,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
// ============================================================
  // TODAY'S IDEA CARD (Compact with Image Thumbnail)
  // ============================================================

  Widget _buildTodaysIdeaCard() {
    final hasSource =
        _todaysIdeaSourceUrl != null &&
        _todaysIdeaSourceUrl!.trim().isNotEmpty;
    
    final hasImage =
        _todaysIdeaImageUrl != null &&
        _todaysIdeaImageUrl!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFDCD6FF),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: .05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // TOP ROW: Category & Source Pill Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EDFF),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      _businessCategory.isNotEmpty
                          ? 'FOR YOUR ${_businessCategory.toUpperCase()}'
                          : 'RECOMMENDED POST',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),

                if (hasSource) ...[
                  const SizedBox(width: 7),
                  InkWell(
                    onTap: _openIdeaSource,
                    borderRadius: BorderRadius.circular(7),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F7FF),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: const Color(0xFFE4DFFF),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getSourceIcon(),
                            size: 13,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getSourceName(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 10),

            // MIDDLE SECTION: Thumbnail Image + Idea Text (Side-by-Side)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImage) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _todaysIdeaImageUrl!,
                      width: 65,
                      height: 65,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0EDFF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.image_not_supported_rounded,
                            size: 22,
                            color: primaryColor,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    _isLoadingIdea ? "Loading today's inspiration..." : _todaysIdea,
                   textAlign: TextAlign.start,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),


            // ACTION BUTTONS (Single Row)
            Row(
              children: [
                if (hasSource) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openIdeaSource,
                      icon: Icon(
                        _getSourceIcon(),
                        size: 14,
                      ),
                      label: Text(
                        'View ${_getSourceName()}',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: const BorderSide(
                          color: Color(0xFFDCD6FF),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreatePostScreen(),
                        ),
                      );

                      _loadRecentProjects();
                      _loadAiUsage();
                    },
                    icon: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                    ),
                    label: const Text(
                      'Create Post',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
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


                
          
  // ============================================================
  // AI USAGE CARD
  // ============================================================

  Widget _buildAiUsageCard() {
    final total =
        _totalAiCredits <= 0
            ? 100
            : _totalAiCredits;

    final used =
        _usedAiCredits.clamp(
      0,
      total,
    );

    final remaining =
        total - used;

    final progress =
        total == 0
            ? 0.0
            : used / total;

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'AI subscription and usage details will be available in your Profile.',
            ),
          ),
        );
      },

      borderRadius:
          BorderRadius.circular(12),

      child: Container(
        width: double.infinity,

        padding:
            const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 12,
        ),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(12),

          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),

        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,

              decoration: BoxDecoration(
                color:
                    const Color(0xFFF0EDFF),
                borderRadius:
                    BorderRadius.circular(9),
              ),

              child: const Icon(
                Icons.auto_awesome_rounded,
                color: primaryColor,
                size: 19,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  const Text(
                    'AI Usage',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          FontWeight.w700,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 5),

                  if (_isLoadingUsage)
                    const SizedBox(
                      width: 18,
                      height: 18,

                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryColor,
                      ),
                    )
                  else ...[
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),

                      child:
                          LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,

                        backgroundColor:
                            const Color(
                          0xFFEDEBF7,
                        ),

                        valueColor:
                            const AlwaysStoppedAnimation<
                                Color>(
                          primaryColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '$used used • $remaining remaining',
                      style:
                          const TextStyle(
                        fontSize: 9.5,
                        color:
                            secondaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            const Icon(
              Icons.chevron_right_rounded,
              color:
                  Color(0xFF9CA3AF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RECENT PROJECT CARD
  // ============================================================

  Widget _buildLatestProjectCard(
    dynamic project,
  ) {
    final title =
        project['title'] ??
        project['caption'] ??
        'Untitled Project';

    final subtitle =
        project['created_at'] ??
        project['date'] ??
        'Saved post';

    final String? projectImageUrl =
        project['image_url'] ??
        project['imageUrl'] ??
        project['banner_url'];

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const ProjectHistoryScreen(),
          ),
        );

        _loadRecentProjects();
      },

      borderRadius:
          BorderRadius.circular(12),

      child: Container(
        width: double.infinity,

        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(12),

          border: Border.all(
            color:
                const Color(0xFFE5E7EB),
          ),
        ),

        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,

              decoration: BoxDecoration(
                color:
                    const Color(0xFFF0EDFF),
                borderRadius:
                    BorderRadius.circular(10),

                border: Border.all(
                  color:
                      const Color(0xFFE5E7EB),
                ),
              ),

              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),

                child: projectImageUrl !=
                            null &&
                        projectImageUrl
                            .isNotEmpty
                    ? Image.network(
                        projectImageUrl,
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,

                        errorBuilder:
                            (
                              context,
                              error,
                              stackTrace,
                            ) {
                          return const Icon(
                            Icons.image_rounded,
                            color:
                                primaryColor,
                            size: 20,
                          );
                        },
                      )
                    : const Icon(
                        Icons.image_rounded,
                        color:
                            primaryColor,
                        size: 20,
                      ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(
                      fontSize: 11,
                      color:
                          secondaryText,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color:
                  Color(0xFF9CA3AF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY PROJECT CARD
  // ============================================================

  Widget _buildEmptyProjectCard() {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const ProjectHistoryScreen(),
          ),
        );

        _loadRecentProjects();
      },

      borderRadius:
          BorderRadius.circular(12),

      child: Container(
        width: double.infinity,

        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(12),

          border: Border.all(
            color:
                const Color(0xFFE5E7EB),
          ),
        ),

        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,

              decoration: BoxDecoration(
                color:
                    const Color(0xFFF0EDFF),
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),

              child: const Icon(
                Icons.image_outlined,
                color: primaryColor,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            const Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    'No projects yet',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                      color: textColor,
                    ),
                  ),

                  SizedBox(height: 3),

                  Text(
                    'Your saved posts will appear here.',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          secondaryText,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color:
                  Color(0xFF9CA3AF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOADING BUSINESS CARD
  // ============================================================

  Widget _loadingBusinessCard() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),

        border: Border.all(
          color:
              const Color(0xFFE5E7EB),
        ),
      ),

      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,

            child:
                CircularProgressIndicator(
              strokeWidth: 2,
              color: primaryColor,
            ),
          ),

          SizedBox(width: 12),

          Text(
            'Loading business profile...',
            style: TextStyle(
              fontSize: 12,
              color: secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SETUP BUSINESS CARD
  // ============================================================

  Widget _setupBusinessCard() {
    return InkWell(
      onTap:
          _openBusinessProfile,

      borderRadius:
          BorderRadius.circular(12),

      child: Container(
        width: double.infinity,

        padding:
            const EdgeInsets.all(13),

        decoration: BoxDecoration(
          color:
              const Color(0xFFF0EDFF),

          borderRadius:
              BorderRadius.circular(12),

          border: Border.all(
            color:
                const Color(0xFFDCD6FF),
          ),
        ),

        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,

              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),

              child: const Icon(
                Icons.business_outlined,
                color: primaryColor,
                size: 20,
              ),
            ),

            const SizedBox(width: 11),

            const Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    'Set Up Your Business',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w700,
                      color: textColor,
                    ),
                  ),

                  SizedBox(height: 3),

                  Text(
                    'Add your business details to get started.',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          secondaryText,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: primaryColor,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUSINESS CARD
  // ============================================================

  Widget _businessCard() {
    return InkWell(
      onTap:
          _openBusinessProfile,

      borderRadius:
          BorderRadius.circular(12),

      child: Container(
        width: double.infinity,

        padding:
            const EdgeInsets.all(13),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(12),

          border: Border.all(
            color:
                const Color(0xFFE5E7EB),
          ),
        ),

        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,

              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFF0EDFF,
                ),

                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),

              child:
                  _businessLogoUrl !=
                              null &&
                          _businessLogoUrl!
                              .isNotEmpty
                      ? ClipRRect(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),

                          child:
                              Image.network(
                            _businessLogoUrl!,
                            width: 40,
                            height: 40,
                            fit:
                                BoxFit.cover,

                            errorBuilder:
                                (
                                  context,
                                  error,
                                  stackTrace,
                                ) {
                              return const Icon(
                                Icons
                                    .business_outlined,
                                color:
                                    primaryColor,
                                size: 20,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons
                              .business_outlined,
                          color:
                              primaryColor,
                          size: 20,
                        ),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    _businessName.isEmpty
                        ? 'Business Name'
                        : _businessName,

                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w700,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    _businessCategory
                            .isEmpty
                        ? 'Business Category'
                        : _businessCategory,

                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(
                      fontSize: 11,
                      color:
                          secondaryText,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color:
                  Color(0xFF9CA3AF),
              size: 21,
            ),
          ],
        ),
      ),
    );
  }
}