import 'dart:convert';

import 'package:ai_business_post_maker/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'business_profile_screen.dart';
import 'brand_kit_screen.dart';
import 'subscription_screen.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
  });

  @override
  State<ProfileScreen> createState() =>
  _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {

  // =========================================================
  // COLORS
  // =========================================================

  static const Color primaryColor =
      Color(0xFF5B4BDB);

  static const Color backgroundColor =
      Color(0xFFF8F8FC);

  static const Color textColor =
      Color(0xFF1F2937);

  static const Color secondaryText =
      Color(0xFF6B7280);

  static const Color borderColor =
      Color(0xFFE5E7EB);

  // =========================================================
  // STORAGE
  // =========================================================

  final FlutterSecureStorage _storage =
      const FlutterSecureStorage();

  // =========================================================
  // USER
  // =========================================================

  String _userName = 'User';

  String _userEmail = '';

  // =========================================================
  // BUSINESS
  // =========================================================

  String _businessName = '';

  String _businessCategory = '';

  String? _businessLogoUrl;

  bool _hasBusinessProfile = false;

  // =========================================================
  // SUBSCRIPTION
  // =========================================================

  String _planName = 'Free';

  String _subscriptionStatus = 'active';

  String? _subscriptionEndDate;

  // =========================================================
  // AI USAGE
  // =========================================================

  int _usedAi = 0;

  int _aiLimit = 10;

  int _remainingAi = 10;

  double _usagePercentage = 0;

  // =========================================================
  // STATES
  // =========================================================

  bool _isLoading = true;

  bool _isLoggingOut = false;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _loadProfileData();
  }

  // =========================================================
  // LOAD EVERYTHING
  // =========================================================

  Future<void> _loadProfileData() async {

    setState(() {
      _isLoading = true;
    });

    await Future.wait([
      _loadUserProfile(),
      _loadBusinessProfile(),
      _loadSubscription(),
      _loadAiUsage(),
    ]);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  // =========================================================
  // USER PROFILE
  // =========================================================

  Future<void> _loadUserProfile() async {

    try {

      final token =
          await _storage.read(
        key: 'access_token',
      );

      if (token == null ||
          token.isEmpty) {
        return;
      }

      final response =
          await http.get(

        Uri.parse(
          'https://aibusinesspostmaker-production.up.railway.app/api/profile',
        
        ),

        headers: {
          'Authorization':
              'Bearer $token',
        },

      );

      if (response.statusCode != 200) {
        return;
      }

      final data =
          jsonDecode(response.body);

      if (data['success'] != true) {
        return;
      }

      final user =
          data['user'];

      if (!mounted) return;

      setState(() {

        _userName =
            user['name']?.toString() ??
                'User';

        _userEmail =
            user['email']?.toString() ??
                '';

      });

    } catch (e) {

      debugPrint(
        'PROFILE LOAD ERROR: $e',
      );

    }
  }

  // =========================================================
  // BUSINESS PROFILE
  // =========================================================

  Future<void> _loadBusinessProfile() async {

    try {

      final token =
          await _storage.read(
        key: 'access_token',
      );

      if (token == null ||
          token.isEmpty) {
        return;
      }

      final response =
          await http.get(

        Uri.parse(
          'https://aibusinesspostmaker-production.up.railway.app/api/business-profile',
        ),

        headers: {
          'Authorization':
              'Bearer $token',
        },

      );

      if (response.statusCode != 200) {

        if (!mounted) return;

        setState(() {
          _hasBusinessProfile = false;
        });

        return;
      }

      final data =
          jsonDecode(response.body);

      if (data['success'] != true ||
          data['business_profile'] == null) {

        if (!mounted) return;

        setState(() {
          _hasBusinessProfile = false;
        });

        return;
      }

      final profile =
          data['business_profile'];

      if (!mounted) return;

      setState(() {

        _hasBusinessProfile = true;

        _businessName =
            profile['business_name']
                ?.toString() ??
                '';

        _businessCategory =
            profile['category']
                ?.toString() ??
                '';

        _businessLogoUrl =
            profile['logo_url']
                ?.toString();

      });

    } catch (e) {

      debugPrint(
        'BUSINESS PROFILE ERROR: $e',
      );

    }
  }

  // =========================================================
  // SUBSCRIPTION
  // =========================================================

  Future<void> _loadSubscription() async {

    try {

      final token =
          await _storage.read(
        key: 'access_token',
      );

      if (token == null ||
          token.isEmpty) {
        return;
      }

      final response =
          await http.get(

        Uri.parse(
          'https://aibusinesspostmaker-production.up.railway.app/api/subscription',
        ),

        headers: {
          'Authorization':
              'Bearer $token',
        },

      );

      if (response.statusCode != 200) {
        return;
      }

      final data =
          jsonDecode(response.body);

      if (data['success'] != true) {
        return;
      }

      final subscription =
          data['subscription'];

      final plan =
          subscription['plan'];

      if (!mounted) return;

      setState(() {

        _planName =
            plan['name']?.toString() ??
                'Free';

        _subscriptionStatus =
            subscription['status']
                ?.toString() ??
                'active';

        _subscriptionEndDate =
            subscription['end_date']
                ?.toString();

      });

    } catch (e) {

      debugPrint(
        'SUBSCRIPTION LOAD ERROR: $e',
      );

    }
  }

  // =========================================================
  // AI USAGE
  // =========================================================

  Future<void> _loadAiUsage() async {

    try {

      final token =
          await _storage.read(
        key: 'access_token',
      );

      if (token == null ||
          token.isEmpty) {
        return;
      }

      final response =
          await http.get(

        Uri.parse(
          'https://aibusinesspostmaker-production.up.railway.app/api/ai-usage',
        ),

        headers: {
          'Authorization':
              'Bearer $token',
        },

      );

      if (response.statusCode != 200) {
        return;
      }

      final data =
          jsonDecode(response.body);

      if (data['success'] != true) {
        return;
      }

      if (!mounted) return;

      setState(() {

        _usedAi =
            int.tryParse(
                  data['used']
                          ?.toString() ??
                      '0',
                ) ??
                0;

        _aiLimit =
            int.tryParse(
                  data['limit']
                          ?.toString() ??
                      '10',
                ) ??
                10;

        _remainingAi =
            int.tryParse(
                  data['remaining']
                          ?.toString() ??
                      '0',
                ) ??
                0;

        _usagePercentage =
            double.tryParse(
                  data['percentage']
                          ?.toString() ??
                      '0',
                ) ??
                0;

        if (data['plan'] != null) {

          _planName =
              data['plan'].toString();

        }

      });

    } catch (e) {

      debugPrint(
        'AI USAGE ERROR: $e',
      );

    }
  }

  // =========================================================
  // SUBSCRIPTION SCREEN
  // =========================================================

  Future<void> _openSubscription() async {

    await Navigator.push(
      context,

      MaterialPageRoute(
        builder: (context) =>
            const SubscriptionScreen(),
      ),
    );

    await _loadSubscription();
    await _loadAiUsage();
  }

  // =========================================================
  // BUSINESS PROFILE
  // =========================================================

  Future<void> _openBusinessProfile() async {

    await Navigator.push(
      context,

      MaterialPageRoute(
        builder: (context) =>
            const BusinessProfileScreen(),
      ),
    );

    await _loadBusinessProfile();
  }

  // =========================================================
  // BRAND KIT
  // =========================================================

  Future<void> _openBrandKit() async {

    if (!_hasBusinessProfile) {

      _showMessage(
        'Please create your business profile first.',
      );

      return;
    }

    await Navigator.push(
      context,

      MaterialPageRoute(
        builder: (context) =>
            const BrandKitScreen(),
      ),
    );
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> _logout() async {

    final confirmed =
        await showDialog<bool>(

      context: context,

      builder: (context) {

        return AlertDialog(

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),

          title: const Text(
            'Logout',
          ),

          content: const Text(
            'Are you sure you want to logout?',
          ),

          actions: [

            TextButton(

              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),

              child: const Text(
                'Cancel',
              ),
            ),

            ElevatedButton(

              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    primaryColor,
                foregroundColor:
                    Colors.white,
              ),

              child: const Text(
                'Logout',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });

    await _storage.delete(
      key: 'access_token',
    );

    if (!mounted) return;

Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (context) => const LoginScreen()),
  (route) => false,
);
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message,
  ) {

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(
        content: Text(message),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      backgroundColor:
          backgroundColor,

      body: SafeArea(

        child: _isLoading

            ? const Center(
                child:
                    CircularProgressIndicator(
                  color:
                      primaryColor,
                ),
              )

            : RefreshIndicator(

                color:
                    primaryColor,

                onRefresh:
                    _loadProfileData,

                child:
                    SingleChildScrollView(

                  physics:
                      const AlwaysScrollableScrollPhysics(),

                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    30,
                  ),

                  child: Column(

                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      // =================================================
                      // HEADER
                      // =================================================


Row(

  children: [

    // Yeh back button yahan add kar dein
    IconButton(
      icon: const Icon(
        Icons.arrow_back,
        color: textColor,
      ),
      onPressed: () {
        Navigator.pop(context);
      },
    ),

    const SizedBox(
      width: 4,
    ),

    Container(

      width: 42,
      height: 42,

      decoration:
          BoxDecoration(

        color:
            const Color(
          0xFFF0EDFF,
        ),

        borderRadius:
            BorderRadius.circular(
          12,
        ),
      ),

      child:
          const Icon(
        Icons
            .person_rounded,
        color:
            primaryColor,
        size: 23,
      ),
    ),

    const SizedBox(
      width: 12,
    ),

    const Expanded(

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Text(

            'My Profile',

            style:
                TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.w800,
              color:
                  textColor,
            ),
          ),

          SizedBox(
            height: 2,
          ),

          Text(

            'Manage your account and preferences',

            style:
                TextStyle(
              fontSize: 11,
              color:
                  secondaryText,
            ),
          ),
        ],
      ),
    ),
  ],
),

                      const SizedBox(
                        height: 22,
                      ),

                      // =================================================
                      // USER CARD
                      // =================================================

                      _userCard(),

                      const SizedBox(
                        height: 16,
                      ),

                      // =================================================
                      // SUBSCRIPTION
                      // =================================================

                      _subscriptionCard(),

                      const SizedBox(
                        height: 16,
                      ),

                      // =================================================
                      // BUSINESS
                      // =================================================

                      _sectionTitle(
                        'Business',
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      _businessProfileCard(),

                      const SizedBox(
                        height: 10,
                      ),

                      _brandKitCard(),

                      const SizedBox(
                        height: 20,
                      ),

                      // =================================================
                      // AI USAGE
                      // =================================================

                      _sectionTitle(
                        'AI Usage',
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      _aiUsageCard(),

                      const SizedBox(
                        height: 20,
                      ),

                      // =================================================
                      // ACCOUNT
                      // =================================================

                      _sectionTitle(
                        'Account',
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      _logoutCard(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // =========================================================
  // USER CARD
  // =========================================================

  Widget _userCard() {

    final initial =
        _userName.isNotEmpty
            ? _userName[0].toUpperCase()
            : 'U';

    return Container(

      width: double.infinity,

      padding:
          const EdgeInsets.all(16),

      decoration:
          BoxDecoration(

        color: Colors.white,

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color: borderColor,
        ),

        boxShadow: [

          BoxShadow(
            color:
                Colors.black.withValues(alpha: 
              0.025,
            ),
            blurRadius: 12,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),

      child: Row(

        children: [

          Container(

            width: 58,
            height: 58,

            decoration:
                BoxDecoration(

              gradient:
                  const LinearGradient(

                begin:
                    Alignment.topLeft,

                end:
                    Alignment.bottomRight,

                colors: [

                  Color(0xFF6D5CE7),
                  Color(0xFF4D3DC4),

                ],
              ),

              borderRadius:
                  BorderRadius.circular(
                17,
              ),
            ),

            child: Center(

              child: Text(

                initial,

                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 13,
          ),

          Expanded(

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(

                  _userName,

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w700,
                    color: textColor,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(

                  _userEmail,

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
        ],
      ),
    );
  }

  // =========================================================
  // SUBSCRIPTION CARD
  // =========================================================

  Widget _subscriptionCard() {

    final isFree =
        _planName.toLowerCase() ==
            'free';

    return InkWell(

      onTap:
          _openSubscription,

      borderRadius:
          BorderRadius.circular(16),

      child: Container(

        width: double.infinity,

        padding:
            const EdgeInsets.all(16),

        decoration:
            BoxDecoration(

          gradient:
              const LinearGradient(

            begin:
                Alignment.topLeft,

            end:
                Alignment.bottomRight,

            colors: [

              Color(0xFFF0EDFF),
              Color(0xFFF8F8FC),

            ],
          ),

          borderRadius:
              BorderRadius.circular(
            16,
          ),

          border: Border.all(
            color:
                const Color(
              0xFFDCD6FF,
            ),
          ),
        ),

        child: Row(

          children: [

            Container(

              width: 45,
              height: 45,

              decoration:
                  BoxDecoration(

                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  13,
                ),
              ),

              child:
                  const Icon(
                Icons.workspace_premium_rounded,
                color:
                    primaryColor,
                size: 24,
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Row(

                    children: [

                      const Text(
                        'Subscription',
                        style:
                            TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              textColor,
                        ),
                      ),

                      const SizedBox(
                        width: 7,
                      ),

                      Container(

                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),

                        decoration:
                            BoxDecoration(

                          color:
                              primaryColor,

                          borderRadius:
                              BorderRadius
                                  .circular(
                            5,
                          ),
                        ),

                        child: Text(

                          _planName,

                          style:
                              const TextStyle(
                            fontSize: 8,
                            fontWeight:
                                FontWeight.w700,
                            color:
                                Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(

                    isFree
                        ? 'Upgrade your plan to unlock more features.'
                        : 'Your $_planName plan is active.',

                    maxLines: 2,

                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(
                      fontSize: 10.5,
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
                  secondaryText,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BUSINESS PROFILE CARD
  // =========================================================

  Widget _businessProfileCard() {

    return _actionCard(

      icon:
          Icons.storefront_outlined,

      title:
          _hasBusinessProfile
              ? (_businessName.isEmpty
                  ? 'Business Profile'
                  : _businessName)
              : 'Business Profile',

      subtitle:
          _hasBusinessProfile
              ? (_businessCategory.isEmpty
                  ? 'Manage your business details'
                  : _businessCategory)
              : 'Create and manage your business information',

      onTap:
          _openBusinessProfile,

      imageUrl:
          _businessLogoUrl,
    );
  }

  // =========================================================
  // BRAND KIT CARD
  // =========================================================

  Widget _brandKitCard() {

    return _actionCard(

      icon:
          Icons.palette_outlined,

      title:
          'Brand Kit',

      subtitle:
          'Manage logo, colors, fonts and contact information',

      onTap:
          _openBrandKit,
    );
  }

  // =========================================================
  // AI USAGE CARD
  // =========================================================

  Widget _aiUsageCard() {

    final progress =
        _usagePercentage.clamp(
      0.0,
      1.0,
    );

    return Container(

      width: double.infinity,

      padding:
          const EdgeInsets.all(16),

      decoration:
          BoxDecoration(

        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        border: Border.all(
          color: borderColor,
        ),
      ),

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              Container(

                width: 42,
                height: 42,

                decoration:
                    BoxDecoration(

                  color:
                      const Color(
                    0xFFF0EDFF,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    11,
                  ),
                ),

                child:
                    const Icon(
                  Icons.auto_awesome_rounded,
                  color:
                      primaryColor,
                  size: 21,
                ),
              ),

              const SizedBox(
                width: 11,
              ),

              Expanded(

                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(

                      'AI Generations',

                      style:
                          const TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            textColor,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(

                      '$_usedAi of $_aiLimit used this month',

                      style:
                          const TextStyle(
                        fontSize: 10.5,
                        color:
                            secondaryText,
                      ),
                    ),
                  ],
                ),
              ),

              Text(

                _planName,

                style:
                    const TextStyle(
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      primaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          ClipRRect(

            borderRadius:
                BorderRadius.circular(
              20,
            ),

            child:
                LinearProgressIndicator(

              value:
                  progress,

              minHeight: 7,

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

          const SizedBox(
            height: 8,
          ),

          Row(

            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

            children: [

              Text(

                '${(progress * 100).round()}% used',

                style:
                    const TextStyle(
                  fontSize: 9.5,
                  color:
                      secondaryText,
                ),
              ),

              Text(

                '$_remainingAi remaining',

                style:
                    const TextStyle(
                  fontSize: 9.5,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // LOGOUT CARD
  // =========================================================

  Widget _logoutCard() {

    return InkWell(

      onTap:
          _isLoggingOut
              ? null
              : _logout,

      borderRadius:
          BorderRadius.circular(14),

      child: Container(

        width: double.infinity,

        padding:
            const EdgeInsets.all(14),

        decoration:
            BoxDecoration(

          color: Colors.white,

          borderRadius:
              BorderRadius.circular(
            14,
          ),

          border: Border.all(
            color: borderColor,
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
                  0xFFFFF1F1,
                ),

                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),

              child:
                  const Icon(
                Icons.logout_rounded,
                color:
                    Colors.redAccent,
                size: 20,
              ),
            ),

            const SizedBox(
              width: 11,
            ),

            const Expanded(

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    'Log Out',

                    style:
                        TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          textColor,
                    ),
                  ),

                  SizedBox(
                    height: 3,
                  ),

                  Text(
                    'Sign out from your account',

                    style:
                        TextStyle(
                      fontSize: 10.5,
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
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // GENERIC ACTION CARD
  // =========================================================

  Widget _actionCard({

    required IconData icon,

    required String title,

    required String subtitle,

    required VoidCallback onTap,

    String? imageUrl,
  }) {

    return InkWell(

      onTap: onTap,

      borderRadius:
          BorderRadius.circular(
        14,
      ),

      child: Container(

        width: double.infinity,

        padding:
            const EdgeInsets.all(14),

        decoration:
            BoxDecoration(

          color: Colors.white,

          borderRadius:
              BorderRadius.circular(
            14,
          ),

          border: Border.all(
            color: borderColor,
          ),
        ),

        child: Row(

          children: [

            Container(

              width: 43,
              height: 43,

              decoration:
                  BoxDecoration(

                color:
                    const Color(
                  0xFFF0EDFF,
                ),

                borderRadius:
                    BorderRadius.circular(
                  11,
                ),
              ),

              child:
                  imageUrl != null &&
                          imageUrl.isNotEmpty

                      ? ClipRRect(

                          borderRadius:
                              BorderRadius.circular(
                            11,
                          ),

                          child:
                              Image.network(
                            imageUrl,
                            width: 43,
                            height: 43,
                            fit:
                                BoxFit.cover,

                            errorBuilder:
                                (
                              context,
                              error,
                              stackTrace,
                            ) {

                              return Icon(
                                icon,
                                color:
                                    primaryColor,
                                size: 21,
                              );
                            },
                          ),
                        )

                      : Icon(
                          icon,
                          color:
                              primaryColor,
                          size: 21,
                        ),
            ),

            const SizedBox(
              width: 11,
            ),

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
                          FontWeight.w700,
                      color:
                          textColor,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(

                    subtitle,

                    maxLines: 2,

                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(
                      fontSize: 10.5,
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

  // =========================================================
  // SECTION TITLE
  // =========================================================

  Widget _sectionTitle(
    String title,
  ) {

    return Text(

      title,

      style:
          const TextStyle(
        fontSize: 16,
        fontWeight:
            FontWeight.w700,
        color:
            textColor,
      ),
    );
  }
}