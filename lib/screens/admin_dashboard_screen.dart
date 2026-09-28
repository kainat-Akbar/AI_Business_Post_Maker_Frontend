import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:file_picker/file_picker.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardState();
}

class _AdminDashboardState
    extends State<AdminDashboardScreen> {
  static const String baseUrl =
      "https://aibusinesspostmaker-production.up.railway.app";
  

  final FlutterSecureStorage _storage =
      const FlutterSecureStorage();

  bool isLoading = true;
  bool isRefreshing = false;

  String? errorMessage;

  Map<String, dynamic> dashboardData = {};

  List<dynamic> users = [];
  List<dynamic> templates = [];
  List<dynamic> categories = [];
  List<dynamic> plans = [];
  List<dynamic> reports = [];

  int selectedSection = 0;

  static const Color primaryBlue =
      Color(0xFF2563EB);

  static const Color darkBlue =
      Color(0xFF1D4ED8);

  static const Color lightBlue =
      Color(0xFFEFF6FF);

  static const Color background =
      Color(0xFFF7F9FC);

  static const Color textDark =
      Color(0xFF172033);

  static const Color textGrey =
      Color(0xFF6B7280);

  static const Color border =
      Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<String?> getToken() async {
    return _storage.read(
      key: "access_token",
    );
  }

  Future<Map<String, dynamic>> getRequest(
    String endpoint,
  ) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        "Admin login token not found.",
      );
    }

    final response = await http.get(
      Uri.parse("$baseUrl$endpoint"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        "Invalid server response.",
      );
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data["success"] == true) {
      return data;
    }

    throw Exception(
      data["message"] ??
          "Unable to load data.",
    );
  }

  Future<bool> putRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        "Admin login token not found.",
      );
    }

    final response = await http.put(
      Uri.parse("$baseUrl$endpoint"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        "Invalid server response.",
      );
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data["success"] == true) {
      return true;
    }

    throw Exception(
      data["message"] ??
          "Request failed.",
    );
  }

  Future<void> loadDashboard() async {
    try {
      if (!isRefreshing) {
        setState(() {
          isLoading = true;
          errorMessage = null;
        });
      }

      final dashboard =
          await getRequest(
        "/api/admin/dashboard",
      );

      final userData =
          await getRequest(
        "/api/admin/users",
      );

      final templateData =
          await getRequest(
        "/api/admin/templates",
      );

      final categoryData =
          await getRequest(
        "/api/admin/categories",
      );

      final planData =
          await getRequest(
        "/api/admin/subscription-plans",
      );

      final reportData =
          await getRequest(
        "/api/admin/reports",
      );

      if (!mounted) return;

      setState(() {
        dashboardData = dashboard;

        users =
            userData["users"] ?? [];

        templates =
            templateData["templates"] ?? [];

        categories =
            categoryData["categories"] ?? [];

        plans =
            planData["plans"] ?? [];

        reports =
            reportData["reports"] ?? [];

        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e
            .toString()
            .replaceFirst(
              "Exception: ",
              "",
            );
      });
    }
  }

  Future<void> refreshDashboard() async {
    if (isRefreshing) return;

    setState(() {
      isRefreshing = true;
    });

    await loadDashboard();

    if (!mounted) return;

    setState(() {
      isRefreshing = false;
    });
  }

  Future<void> changeUserStatus(
    int userId,
    String status,
  ) async {
    try {
      await putRequest(
        "/api/admin/users/$userId/status",
        {
          "status": status,
        },
      );

      if (!mounted) return;

      _showMessage(
        status == "blocked"
            ? "User blocked successfully."
            : "User unblocked successfully.",
      );

      await loadDashboard();
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst(
              "Exception: ",
              "",
            ),
        error: true,
      );
    }
  }

  Future<void> changeTemplateStatus(
    int templateId,
    bool isActive,
  ) async {
    try {
      await putRequest(
        "/api/admin/templates/$templateId",
        {
          "is_active": isActive,
        },
      );

      if (!mounted) return;

      _showMessage(
        isActive
            ? "Template activated."
            : "Template disabled.",
      );

      await loadDashboard();
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst(
              "Exception: ",
              "",
            ),
        error: true,
      );
    }
  }

  Future<void> changeTemplatePremium(
    int templateId,
    bool isPremium,
  ) async {
    try {
      await putRequest(
        "/api/admin/templates/$templateId",
        {
          "is_premium": isPremium,
        },
      );

      if (!mounted) return;

      _showMessage(
        isPremium
            ? "Template marked Premium."
            : "Template marked Free.",
      );

      await loadDashboard();
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst(
              "Exception: ",
              "",
            ),
        error: true,
      );
    }
  }

  Future<void> addCategory({
    required String name,
    required String description,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        "Admin login token not found.",
      );
    }

    final response = await http.post(
      Uri.parse(
        "$baseUrl/api/admin/categories",
      ),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "name": name.trim(),
        "description":
            description.trim(),
      }),
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        "Invalid server response.",
      );
    }

    if (response.statusCode == 201 &&
        data["success"] == true) {
      await loadDashboard();
      return;
    }

    throw Exception(
      data["message"] ??
          "Unable to create category.",
    );
  }

  Future<void> changeCategoryStatus(
    int categoryId,
    bool isActive,
  ) async {
    try {
      await putRequest(
        "/api/admin/categories/$categoryId/status",
        {
          "status": isActive ? "active" : "inactive",
        },
      );

      if (!mounted) return;

      _showMessage(
        isActive
            ? "Category activated."
            : "Category disabled.",
      );

      await loadDashboard();
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst(
              "Exception: ",
              "",
            ),
        error: true,
      );
    }
  }

  Future<void> changeReportStatus(
    int reportId,
    String status,
  ) async {
    try {
      await putRequest(
        "/api/admin/reports/$reportId",
        {
          "status": status,
        },
      );

      if (!mounted) return;

      _showMessage(
        "Report status updated.",
      );

      await loadDashboard();
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst(
              "Exception: ",
              "",
            ),
        error: true,
      );
    }
  }

  Future<void> createTemplate({
    required String name,
    required int categoryId,
    required bool isPremium,
    required String templateData,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        "Admin login token not found.",
      );
    }

    final request = http.MultipartRequest(
      "POST",
      Uri.parse(
        "$baseUrl/api/admin/templates",
      ),
    );

    request.headers[
        "Authorization"] =
        "Bearer $token";

    request.fields["name"] =
        name.trim();

    request.fields["category_id"] =
        categoryId.toString();

    request.fields["is_premium"] =
        isPremium.toString();

    request.fields["template_data"] =
        templateData.trim();

    if (imageBytes != null &&
        imageName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          "preview",
          imageBytes,
          filename: imageName,
        ),
      );
    }

    final streamed =
        await request.send();

    final response =
        await http.Response.fromStream(
      streamed,
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(
        response.body,
      );
    } catch (_) {
      throw Exception(
        "Invalid server response.",
      );
    }

    if (response.statusCode == 201 &&
        data["success"] == true) {
      await loadDashboard();
      return;
    }

    throw Exception(
      data["message"] ??
          "Unable to create template.",
    );
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor:
            error ? Colors.red : null,
        content: Text(message),
      ),
    );
  }

  Map<String, dynamic> _statistics() {
    final value =
        dashboardData["statistics"];

    if (value is Map<String, dynamic>) {
      return value;
    }

    final overview =
        dashboardData["overview"];

    if (overview
        is Map<String, dynamic>) {
      return overview;
    }

    return {};
  }

  Map<String, dynamic>
      _userStatistics() {
    final value =
        _statistics()["users"];

    if (value
        is Map<String, dynamic>) {
      return value;
    }

    return {};
  }

  Map<String, dynamic>
      _postStatistics() {
    final value =
        _statistics()["posts"];

    if (value
        is Map<String, dynamic>) {
      return value;
    }

    return {};
  }

  Map<String, dynamic>
      _aiStatistics() {
    final value =
        _statistics()["ai"];

    if (value
        is Map<String, dynamic>) {
      return value;
    }

    return {};
  }

  Map<String, dynamic>
      _subscriptionStatistics() {
    final value =
        _statistics()[
            "subscriptions"];

    if (value
        is Map<String, dynamic>) {
      return value;
    }

    return {};
  }

  Map<String, dynamic>
      _revenueStatistics() {
    final value =
        _statistics()["revenue"];

    if (value
        is Map<String, dynamic>) {
      return value;
    }

    return {};
  }

  String _userStat(
    String key,
  ) {
    return (_userStatistics()[key] ??
            0)
        .toString();
  }

  String _postTotal() {
    return (_postStatistics()["total"] ??
            0)
        .toString();
  }

  String _aiGenerations() {
    return (_aiStatistics()[
                "total_generations"] ??
            0)
        .toString();
  }

  String _activeSubscriptions() {
    return (_subscriptionStatistics()[
                "active"] ??
            0)
        .toString();
  }

  String _estimatedRevenue() {
    final value =
        _revenueStatistics()[
            "estimated"];

    return _toDouble(value)
        .toStringAsFixed(0);
  }

  String _adminName() {
    final admin =
        dashboardData["admin"];

    if (admin
        is Map<String, dynamic>) {
      return admin["name"]
              ?.toString() ??
          "Administrator";
    }

    return "Administrator";
  }

  int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString(),
        ) ??
        0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: LayoutBuilder(
        builder:
            (context, constraints) {
          final isMobile =
              constraints.maxWidth < 800;

          return Row(
            children: [
              if (!isMobile)
                _buildSidebar(),

              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(
                      isMobile,
                    ),
                    Expanded(
                      child:
                          _buildMainContent(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      drawer:
          MediaQuery.of(context)
                      .size
                      .width <
                  800
              ? Drawer(
                  child:
                      _buildSidebar(
                    closeDrawer: true,
                  ),
                )
              : null,
    );
  }

  Widget _buildSidebar({
    bool closeDrawer = false,
  }) {
    final items = [
      {
        "icon": Icons.dashboard_outlined,
        "title": "Overview",
      },
      {
        "icon": Icons.people_outline,
        "title": "Users",
      },
      {
        "icon": Icons.image_outlined,
        "title": "Templates",
      },
      {
        "icon": Icons.category_outlined,
        "title": "Categories",
      },
      {
        "icon":
            Icons.workspace_premium_outlined,
        "title": "Subscriptions",
      },
      {
        "icon":
            Icons.report_problem_outlined,
        "title": "Reports",
      },
    ];

    return Container(
      width: 235,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 25),

          const Text(
            "AI Business\nPost Maker",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primaryBlue,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 30),

          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder:
                  (context, index) {
                final selected =
                    selectedSection ==
                        index;

                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedSection =
                          index;
                    });

                    if (closeDrawer) {
                      Navigator.pop(
                        context,
                      );
                    }
                  },
                  child: Container(
                    margin:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration:
                        BoxDecoration(
                      color: selected
                          ? lightBlue
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius
                              .circular(
                        10,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          items[index]
                              ["icon"] as IconData,
                          color: selected
                              ? primaryBlue
                              : textGrey,
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Text(
                          items[index]
                              ["title"] as String,
                          style: TextStyle(
                            color: selected
                                ? primaryBlue
                                : textDark,
                            fontWeight:
                                selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    bool isMobile,
  ) {
    return Container(
      height: 72,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 22,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: border,
          ),
        ),
      ),
      child: Row(
        children: [
          if (isMobile)
            Builder(
              builder: (context) {
                return IconButton(
                  onPressed: () {
                    Scaffold.of(context)
                        .openDrawer();
                  },
                  icon: const Icon(
                    Icons.menu,
                  ),
                );
              },
            ),

          Expanded(
            child: Text(
              _sectionTitle(),
              style: const TextStyle(
                color: textDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          IconButton(
            onPressed:
                refreshDashboard,
            icon:
                isRefreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.refresh,
                      ),
          ),

          const SizedBox(width: 8),

          CircleAvatar(
            backgroundColor:
                lightBlue,
            child: Text(
              _initial(
                _adminName(),
              ),
              style:
                  const TextStyle(
                color: primaryBlue,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _sectionTitle() {
    switch (selectedSection) {
      case 1:
        return "Users";
      case 2:
        return "Templates";
      case 3:
        return "Categories";
      case 4:
        return "Subscriptions";
      case 5:
        return "Reports";
      default:
        return "Admin Dashboard";
    }
  }

  Widget _buildMainContent() {
    if (isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(
          color: primaryBlue,
        ),
      );
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    switch (selectedSection) {
      case 1:
        return _buildUsersSection();
      case 2:
        return _buildTemplatesSection();
      case 3:
        return _buildCategoriesSection();
      case 4:
        return _buildSubscriptionsSection();
      case 5:
        return _buildReportsSection();
      default:
        return _buildOverviewSection();
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 45,
            ),
            const SizedBox(
              height: 15,
            ),
            Text(
              errorMessage!,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: textGrey,
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            ElevatedButton(
              onPressed:
                  loadDashboard,
              child:
                  const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            "Overview",
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w600,
              color: textDark,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          LayoutBuilder(
            builder:
                (context, constraints) {
              int columns = 4;

              if (constraints
                      .maxWidth <
                  850) {
                columns = 2;
              }

              if (constraints
                      .maxWidth <
                  520) {
                columns = 1;
              }

              final cards = [
                _statCard(
                  "Total Users",
                  _userStat("total"),
                  Icons.people_outline,
                ),
                _statCard(
                  "Active Users",
                  _userStat("active"),
                  Icons.person_outline,
                ),
                _statCard(
                  "Total Posts",
                  _postTotal(),
                  Icons.article_outlined,
                ),
                _statCard(
                  "AI Generations",
                  _aiGenerations(),
                  Icons.auto_awesome_outlined,
                ),
                _statCard(
                  "Premium Users",
                  _userStat("premium"),
                  Icons.workspace_premium_outlined,
                ),
                _statCard(
                  "Active Subscriptions",
                  _activeSubscriptions(),
                  Icons.card_membership_outlined,
                ),
                _statCard(
                  "Estimated Revenue",
                  "Rs ${_estimatedRevenue()}",
                  Icons.payments_outlined,
                ),
                _statCard(
                  "Reports",
                  reports.length.toString(),
                  Icons.report_outlined,
                ),
              ];

              return GridView.count(
                crossAxisCount:
                    columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio:
                    2.3,
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                children: cards,
              );
            },
          ),

          const SizedBox(
            height: 25,
          ),

          _panel(
            title:
                "Most Used Templates",
            child:
                _buildMostUsedTemplates(),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(17),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        border:
            Border.all(
          color: border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration:
                BoxDecoration(
              color: lightBlue,
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              color: primaryBlue,
            ),
          ),
          const SizedBox(
            width: 13,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color: textGrey,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMostUsedTemplates() {
    final value =
        dashboardData[
            "most_used_templates"];

    final overview =
        dashboardData["overview"];

    dynamic list = value;

    if (list == null &&
        overview
            is Map<String, dynamic>) {
      list =
          overview[
              "most_used_templates"];
    }

    if (list is! List ||
        list.isEmpty) {
      return _emptyText(
        "No template usage data available.",
      );
    }

    return Column(
      children: [
        for (final item in list)
          ListTile(
            leading:
                const Icon(
              Icons.image_outlined,
              color: primaryBlue,
            ),
            title: Text(
              item["name"]?.toString() ??
                  "Template",
            ),
            trailing: Text(
              "${item["usage_count"] ?? 0} uses",
              style:
                  const TextStyle(
                color: textGrey,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUsersSection() {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(28),
      child: _panel(
        title: "User Management",
        child: users.isEmpty
            ? _emptyText(
                "No users found.",
              )
            : Column(
                children: [
                  for (final raw
                      in users)
                    _userTile(
                      Map<String,
                              dynamic>.from(
                        raw,
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _userTile(
    Map<String, dynamic> user,
  ) {
    final int? userId =
        _toInt(user["id"]);

    final status =
        user["status"]
                ?.toString()
                .toLowerCase() ??
            "active";

    final blocked =
        status == "blocked";

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
          const EdgeInsets.all(14),
      decoration:
          BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                lightBlue,
            child: Text(
              _initial(
                user["name"],
              ),
              style:
                  const TextStyle(
                color: primaryBlue,
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
                  user["name"]
                          ?.toString() ??
                      "User",
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                    color: textDark,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  user["email"]
                          ?.toString() ??
                      "",
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color: textGrey,
                  ),
                ),
              ],
            ),
          ),
          _statusChip(
            blocked
                ? "Blocked"
                : "Active",
            blocked
                ? Colors.red
                : Colors.green,
          ),
          const SizedBox(
            width: 10,
          ),
          if (userId != null)
            OutlinedButton(
              onPressed: () {
                changeUserStatus(
                  userId,
                  blocked
                      ? "active"
                      : "blocked",
                );
              },
              child: Text(
                blocked
                    ? "Unblock"
                    : "Block",
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTemplatesSection() {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(28),
      child: Column(
        children: [
          Align(
            alignment:
                Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed:
                  _showAddTemplateDialog,
              icon: const Icon(
                Icons.add,
              ),
              label: const Text(
                "Add Template",
              ),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          _panel(
            title:
                "Template Management",
            child: templates.isEmpty
                ? _emptyText(
                    "No templates available.",
                  )
                : Column(
                    children: [
                      for (final raw
                          in templates)
                        _templateTile(
                          Map<String,
                                  dynamic>.from(
                            raw,
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _templateTile(
    Map<String, dynamic> template,
  ) {
    final id =
        _toInt(template["id"]);

    final premium =
        template["is_premium"] ==
            true;

    final active =
        template["is_active"] ==
            true;

    final preview =
        template["preview_url"]
            ?.toString();

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(14),
      decoration:
          BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration:
                BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
            child:
                preview != null &&
                        preview.isNotEmpty
                    ? ClipRRect(
                        borderRadius:
                            BorderRadius
                                .circular(
                          10,
                        ),
                        child:
                            Image.network(
                          preview,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (
                            context,
                            error,
                            stack,
                          ) {
                            return const Icon(
                              Icons
                                  .image_outlined,
                              color:
                                  textGrey,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons
                            .image_outlined,
                        color:
                            textGrey,
                      ),
          ),
          const SizedBox(
            width: 14,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  template["name"]
                          ?.toString() ??
                      "Template",
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                    color: textDark,
                  ),
                ),
                const SizedBox(
                  height: 6,
                ),
                Wrap(
                  spacing: 7,
                  runSpacing: 5,
                  children: [
                    _statusChip(
                      premium
                          ? "Premium"
                          : "Free",
                      premium
                          ? Colors.indigo
                          : Colors.grey,
                    ),
                    _statusChip(
                      active
                          ? "Active"
                          : "Disabled",
                      active
                          ? Colors.green
                          : Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (id != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value ==
                    "premium") {
                  changeTemplatePremium(
                    id,
                    !premium,
                  );
                }

                if (value ==
                    "active") {
                  changeTemplateStatus(
                    id,
                    !active,
                  );
                }
              },
              itemBuilder:
                  (context) => [
                PopupMenuItem(
                  value: "premium",
                  child: Text(
                    premium
                        ? "Make Free"
                        : "Make Premium",
                  ),
                ),
                PopupMenuItem(
                  value: "active",
                  child: Text(
                    active
                        ? "Disable"
                        : "Activate",
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(28),
      child: Column(
        children: [
          Align(
            alignment:
                Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed:
                  _showAddCategoryDialog,
              icon: const Icon(
                Icons.add,
              ),
              label: const Text(
                "Add Category",
              ),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          _panel(
            title:
                "Category Management",
            child: categories.isEmpty
                ? _emptyText(
                    "No categories found.",
                  )
                : Column(
                    children: [
                      for (final raw
                          in categories)
                        _categoryTile(
                          Map<String,
                                  dynamic>.from(
                            raw,
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _categoryTile(
    Map<String, dynamic> category,
  ) {
    final id =
        _toInt(category["id"]);

    final active =
        category["is_active"] ==
            true;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
          const EdgeInsets.all(14),
      decoration:
          BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(
              color: lightBlue,
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
            child: const Icon(
              Icons.category_outlined,
              color: primaryBlue,
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
                  category["name"]
                          ?.toString() ??
                      "Category",
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                    color: textDark,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  category[
                              "description"]
                          ?.toString() ??
                      "",
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color: textGrey,
                  ),
                ),
              ],
            ),
          ),
          _statusChip(
            active
                ? "Active"
                : "Inactive",
            active
                ? Colors.green
                : Colors.red,
          ),
          if (id != null)
            Switch(
              value: active,
              activeThumbColor:
                  primaryBlue,
              onChanged: (value) {
                changeCategoryStatus(
                  id,
                  value,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsSection() {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(28),
      child: _panel(
        title:
            "Subscription Plans",
        child: plans.isEmpty
            ? _emptyText(
                "No subscription plans found.",
              )
            : Column(
                children: [
                  for (final raw
                      in plans)
                    _planTile(
                      Map<String,
                              dynamic>.from(
                        raw,
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _planTile(
    Map<String, dynamic> plan,
  ) {
    final _ =
        _toInt(plan["id"]);

    final price =
        _toDouble(
      plan["price"],
    );

    final limit =
        _toInt(
              plan[
                  "ai_generation_limit"],
            ) ??
            0;

    final premium =
        plan["premium_templates"] ==
            true;

    final ads =
        plan["advertisements"] ==
            true;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration:
                BoxDecoration(
              color: lightBlue,
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: const Icon(
              Icons
                  .workspace_premium_outlined,
              color: primaryBlue,
            ),
          ),
          const SizedBox(
            width: 14,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  plan["name"]
                          ?.toString() ??
                      "Plan",
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 16,
                    color: textDark,
                  ),
                ),
                const SizedBox(
                  height: 6,
                ),
                Text(
                  "AI limit: $limit",
                  style:
                      const TextStyle(
                    color: textGrey,
                  ),
                ),
                const SizedBox(
                  height: 7,
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    _statusChip(
                      premium
                          ? "Premium Templates"
                          : "Free Templates",
                      premium
                          ? Colors.indigo
                          : Colors.grey,
                    ),
                    _statusChip(
                      ads
                          ? "Ads"
                          : "No Ads",
                      ads
                          ? Colors.orange
                          : Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            "Rs ${price.toStringAsFixed(0)}",
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
              fontSize: 17,
              color: primaryBlue,
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildReportsSection() {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(28),
      child: _panel(
        title:
            "Content Reports",
        child: reports.isEmpty
            ? _emptyText(
                "No reports found.",
              )
            : Column(
                children: [
                  for (final raw
                      in reports)
                    _reportTile(
                      Map<String,
                              dynamic>.from(
                        raw,
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _reportTile(
    Map<String, dynamic> report,
  ) {
    final id =
        _toInt(report["id"]);

    final status =
        report["status"]
                ?.toString() ??
            "pending";

    const statuses = [
      "pending",
      "reviewed",
      "resolved",
      "rejected",
    ];

    final value =
        statuses.contains(status)
            ? status
            : "pending";

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(15),
      decoration:
          BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons
                    .report_problem_outlined,
                color: Colors.orange,
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  report[
                              "report_type"]
                          ?.toString() ??
                      "Report",
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ),
              _statusChip(
                status,
                _reportColor(
                  status,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            "User: ${report["user_name"] ?? "Unknown"}",
            style:
                const TextStyle(
              color: textGrey,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            "Reason: ${report["reason"] ?? "No reason provided"}",
            style:
                const TextStyle(
              color: textGrey,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Align(
            alignment:
                Alignment.centerRight,
            child:
                DropdownButton<String>(
              value: value,
              items: const [
                DropdownMenuItem(
                  value: "pending",
                  child:
                      Text("Pending"),
                ),
                DropdownMenuItem(
                  value: "reviewed",
                  child:
                      Text("Reviewed"),
                ),
                DropdownMenuItem(
                  value: "resolved",
                  child:
                      Text("Resolved"),
                ),
                DropdownMenuItem(
                  value: "rejected",
                  child:
                      Text("Rejected"),
                ),
              ],
              onChanged: (newValue) {
                if (newValue ==
                        null ||
                    id == null) {
                  return;
                }

                changeReportStatus(
                  id,
                  newValue,
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _showAddCategoryDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    bool saving = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogBuildContext, setDialogState) {
              final _ =
                  MediaQuery.of(dialogBuildContext).size.width;

              return AlertDialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                title: const Text("Add Category"),
                content: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 420,
                    maxHeight:
                        MediaQuery.of(dialogBuildContext).size.height * 0.55,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          enabled: !saving,
                          decoration: const InputDecoration(
                            labelText: "Category Name",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: descriptionController,
                          enabled: !saving,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: "Description",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () {
                            Navigator.of(dialogContext).pop();
                          },
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (nameController.text.trim().isEmpty) {
                              _showMessage(
                                "Category name is required.",
                                error: true,
                              );
                              return;
                            }

                            setDialogState(() {
                              saving = true;
                            });

                            try {
                              await addCategory(
                                name: nameController.text.trim(),
                                description:
                                    descriptionController.text.trim(),
                              );

                              if (!mounted || !dialogBuildContext.mounted) {
                                return;
                              }

                              Navigator.of(dialogContext).pop();

                              _showMessage(
                                "Category added successfully.",
                              );
                            } catch (e) {
                              if (!dialogBuildContext.mounted) {
                                return;
                              }

                              setDialogState(() {
                                saving = false;
                              });

                              if (!mounted) return;

                              _showMessage(
                                e.toString().replaceFirst(
                                  "Exception: ",
                                  "",
                                ),
                                error: true,
                              );
                            }
                          },
                    child: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("Add"),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      // showDialog can complete while the reverse route animation is still
      // using the TextFields. Delay disposal until that animation is finished.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      nameController.dispose();
      descriptionController.dispose();
    }
  }


  Future<void> _showAddTemplateDialog() async {
    final nameController = TextEditingController();
    final templateDataController = TextEditingController(text: "{}");

    int? selectedCategoryId;
    bool isPremium = false;
    bool saving = false;

    Uint8List? imageBytes;
    String? imageName;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogBuildContext, setDialogState) {
              return AlertDialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                title: const Text("Add Template"),
                content: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 500,
                    maxHeight:
                        MediaQuery.of(dialogBuildContext).size.height * 0.68,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          enabled: !saving,
                          decoration: const InputDecoration(
                            labelText: "Template Name",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<int>(
                          initialValue: selectedCategoryId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: "Category",
                            border: OutlineInputBorder(),
                          ),
                          items: categories.map((raw) {
                            final map = Map<String, dynamic>.from(raw);
                            final id = _toInt(map["id"]);

                            if (id == null) {
                              return null;
                            }

                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(
                                map["name"]?.toString() ?? "Category",
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).whereType<DropdownMenuItem<int>>().toList(),
                          onChanged: saving
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    selectedCategoryId = value;
                                  });
                                },
                        ),
                        const SizedBox(height: 14),

                        // Template image picker.
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: saving
                                ? null
                                : () async {
                                    try {
                                      final file = await FilePicker.pickFile(
  type: FileType.image,
);

if (file == null) {
  return;
}

if (!dialogBuildContext.mounted) {
  return;
}

final bytes = await file.readAsBytes();

if (!dialogBuildContext.mounted) {
  return;
}

if (bytes.isEmpty) {
  _showMessage(
    "Unable to read selected image.",
    error: true,
  );
  return;
}

setDialogState(() {
  imageBytes = bytes;
  imageName = file.name;
});
                                    } catch (_) {
                                      if (!dialogBuildContext.mounted) {
                                        return;
                                      }

                                      _showMessage(
                                        "Unable to select template image.",
                                        error: true,
                                      );
                                    }
                                  },
                            icon: const Icon(
                              Icons.upload_file_outlined,
                            ),
                            label: Flexible(
                              child: Text(
                                imageName ?? "Choose Template Image",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: isPremium,
                          title: const Text(
                            "Premium Template",
                            overflow: TextOverflow.ellipsis,
                          ),
                          onChanged: saving
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    isPremium = value ?? false;
                                  });
                                },
                        ),

                        const SizedBox(height: 10),

                        TextField(
                          controller: templateDataController,
                          enabled: !saving,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: "Template Data JSON",
                            hintText: '{"product_image_box":...}',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () {
                            Navigator.of(dialogContext).pop();
                          },
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (nameController.text.trim().isEmpty) {
                              _showMessage(
                                "Template name is required.",
                                error: true,
                              );
                              return;
                            }

                            if (selectedCategoryId == null) {
                              _showMessage(
                                "Please select a category.",
                                error: true,
                              );
                              return;
                            }

                            try {
                              jsonDecode(
                                templateDataController.text.trim().isEmpty
                                    ? "{}"
                                    : templateDataController.text.trim(),
                              );
                            } catch (_) {
                              _showMessage(
                                "Template Data JSON is invalid.",
                                error: true,
                              );
                              return;
                            }

                            setDialogState(() {
                              saving = true;
                            });

                            try {
                              await createTemplate(
                                name: nameController.text.trim(),
                                categoryId: selectedCategoryId!,
                                isPremium: isPremium,
                                templateData:
                                    templateDataController.text.trim(),
                                imageBytes: imageBytes,
                                imageName: imageName,
                              );

                              if (!mounted || !dialogBuildContext.mounted) {
                                return;
                              }

                              Navigator.of(dialogContext).pop();

                              _showMessage(
                                "Template added successfully.",
                              );
                            } catch (e) {
                              if (!dialogBuildContext.mounted) {
                                return;
                              }

                              setDialogState(() {
                                saving = false;
                              });

                              if (!mounted) return;

                              _showMessage(
                                e.toString().replaceFirst(
                                  "Exception: ",
                                  "",
                                ),
                                error: true,
                              );
                            }
                          },
                    child: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Add Template",
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      // Wait for the dialog's reverse animation before disposing controllers.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      nameController.dispose();
      templateDataController.dispose();
    }
  }

  Widget _panel({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border:
            Border.all(
          color: border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
                const TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          child,
        ],
      ),
    );
  }

  Widget _statusChip(
    String text,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withValues(alpha: .10),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight:
              FontWeight.w600,
        ),
      ),
    );
  }

  Widget _emptyText(
    String text,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 25,
      ),
      child: Center(
        child: Text(
          text,
          textAlign:
              TextAlign.center,
          style:
              const TextStyle(
            color: textGrey,
          ),
        ),
      ),
    );
  }

  Color _reportColor(
    String status,
  ) {
    switch (status) {
      case "reviewed":
        return Colors.blue;
      case "resolved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _initial(
    dynamic name,
  ) {
    final value =
        name?.toString() ?? "";

    if (value.isEmpty) {
      return "?";
    }

    return value
        .substring(0, 1)
        .toUpperCase();
  }
}