import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({
    super.key,
  });

  @override
  State<SubscriptionScreen> createState() =>
      _SubscriptionScreenState();
}

class _SubscriptionScreenState
    extends State<SubscriptionScreen> {
  // ==========================================================
  // THEME
  // ==========================================================

  static const Color primaryColor =
      Color(0xFF5B4BDB);

  static const Color backgroundColor =
      Color(0xFFF8F8FC);

  static const Color textColor =
      Color(0xFF1F2937);

  static const Color secondaryText =
      Color(0xFF6B7280);

  static const Color lightPurple =
      Color(0xFFF0EDFF);

  // ==========================================================
  // STORAGE + BILLING
  // ==========================================================

  final FlutterSecureStorage _storage =
      const FlutterSecureStorage();

  final InAppPurchase _inAppPurchase =
      InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>?
      _purchaseSubscription;

  // ==========================================================
  // STATE
  // ==========================================================

  bool _isLoading = true;
  bool _isPurchasing = false;
  bool _isRestoring = false;

  bool _storeAvailable = false;

  String _currentPlan = 'Free';

  String? _currentStatus;

  String? _subscriptionEndDate;

  List<Map<String, dynamic>> _plans = [];

  final Set<String> _productIds = {
    'pro_monthly',
    'business_monthly',
  };

  Map<String, ProductDetails> _products = {};

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _initializeBilling();

    _loadSubscriptionData();
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _purchaseSubscription?.cancel();

    super.dispose();
  }

  // ==========================================================
  // BILLING INITIALIZATION
  // ==========================================================

  Future<void> _initializeBilling() async {
    try {
      _storeAvailable =
          await _inAppPurchase.isAvailable();

      if (!_storeAvailable) {
        if (mounted) {
          setState(() {});
        }

        return;
      }

      _purchaseSubscription =
          _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () {},
        onError: (error) {
          if (mounted) {
            _showMessage(
              'Purchase error occurred.',
              isError: true,
            );
          }
        },
      );

      final response =
          await _inAppPurchase.queryProductDetails(
        _productIds,
      );

      if (response.error != null) {
        debugPrint(
          'Google Play product error: '
          '${response.error}',
        );
      }

      if (mounted) {
        setState(() {
          _products = {
            for (final product
                in response.productDetails)
              product.id: product,
          };
        });
      }
    } catch (e) {
      debugPrint(
        'BILLING INITIALIZATION ERROR: $e',
      );
    }
  }

  // ==========================================================
  // LOAD ALL SUBSCRIPTION DATA
  // ==========================================================

  Future<void> _loadSubscriptionData() async {
    await Future.wait([
      _loadPlans(),
      _loadCurrentSubscription(),
    ]);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  // ==========================================================
  // LOAD PLANS
  // ==========================================================

  Future<void> _loadPlans() async {
    try {
      final token =
          await _storage.read(
        key: 'access_token',
      );

      if (token == null || token.isEmpty) {
        return;
      }

      final response = await http.get(
        Uri.parse(
          'https://aibusinesspostmaker-production.up.railway.app/api/subscription/plans',
        ),
        headers: {
          'Authorization': 'Bearer $token',
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

      final List<dynamic> serverPlans =
          data['plans'] ?? [];

      if (!mounted) return;

      setState(() {
        _plans = serverPlans
            .map(
              (plan) => Map<String, dynamic>.from(
                plan,
              ),
            )
            .toList();
      });
    } catch (e) {
      debugPrint(
        'LOAD PLANS ERROR: $e',
      );
    }
  }

  // ==========================================================
  // LOAD CURRENT SUBSCRIPTION
  // ==========================================================

  Future<void> _loadCurrentSubscription() async {
    try {
      final token =
          await _storage.read(
        key: 'access_token',
      );

      if (token == null || token.isEmpty) {
        return;
      }

      final response = await http.get(
        Uri.parse(
          'https://aibusinesspostmaker-production.up.railway.app/api/subscription',
        ),
        headers: {
          'Authorization': 'Bearer $token',
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

      if (subscription == null) {
        return;
      }

      final plan =
          subscription['plan'];

      if (!mounted) return;

      setState(() {
        _currentPlan =
            plan?['name']?.toString() ??
                'Free';

        _currentStatus =
            subscription['status']
                ?.toString();

        _subscriptionEndDate =
            subscription['end_date']
                ?.toString();
      });
    } catch (e) {
      debugPrint(
        'LOAD CURRENT SUBSCRIPTION ERROR: $e',
      );
    }
  }

  // ==========================================================
  // PURCHASE
  // ==========================================================

  Future<void> _purchasePlan(
    Map<String, dynamic> plan,
  ) async {
    if (_isPurchasing) {
      return;
    }

    final planName =
        plan['name']?.toString() ?? '';

    if (planName == 'Free') {
      _showMessage(
        'Free plan is already available.',
      );

      return;
    }

    final productId =
        plan['google_product_id']
            ?.toString();

    if (productId == null ||
        productId.isEmpty) {
      _showMessage(
        'Google Play product is not configured.',
        isError: true,
      );

      return;
    }

    if (!_storeAvailable) {
      _showMessage(
        'Google Play is currently unavailable.',
        isError: true,
      );

      return;
    }

    final product =
        _products[productId];

    if (product == null) {
      _showMessage(
        'Subscription product is not available from Google Play yet.',
        isError: true,
      );

      return;
    }

    setState(() {
      _isPurchasing = true;
    });

    try {
      final purchaseParam =
          PurchaseParam(
        productDetails: product,
      );

      await _inAppPurchase
          .buyNonConsumable(
        purchaseParam: purchaseParam,
      );
    } catch (e) {
      debugPrint(
        'PURCHASE ERROR: $e',
      );

      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });

        _showMessage(
          'Unable to start purchase.',
          isError: true,
        );
      }
    }
  }

  // ==========================================================
  // PURCHASE UPDATE HANDLER
  // ==========================================================

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
  ) async {
    for (final purchase
        in purchases) {
      try {
        if (purchase.status ==
            PurchaseStatus.pending) {
          if (mounted) {
            setState(() {
              _isPurchasing = true;
            });
          }

          continue;
        }

        if (purchase.status ==
            PurchaseStatus.error) {
          if (mounted) {
            setState(() {
              _isPurchasing = false;
            });

            _showMessage(
              purchase.error?.message ??
                  'Purchase failed.',
              isError: true,
            );
          }

          if (purchase.pendingCompletePurchase) {
            await _inAppPurchase
                .completePurchase(
              purchase,
            );
          }

          continue;
        }

        if (purchase.status ==
            PurchaseStatus.purchased ||
            purchase.status ==
                PurchaseStatus.restored) {
          await _verifyPurchaseWithBackend(
            purchase,
          );
        }

        if (purchase.pendingCompletePurchase) {
          await _inAppPurchase
              .completePurchase(
            purchase,
          );
        }
      } catch (e) {
        debugPrint(
          'PURCHASE UPDATE ERROR: $e',
        );

        if (mounted) {
          setState(() {
            _isPurchasing = false;
          });
        }
      }
    }
  }

  // ==========================================================
  // VERIFY PURCHASE WITH BACKEND
  // ==========================================================

  Future<void> _verifyPurchaseWithBackend(
    PurchaseDetails purchase,
  ) async {
    try {
      final token =
          await _storage.read(
        key: 'access_token',
      );

      if (token == null || token.isEmpty) {
        return;
      }

      final productId =
          purchase.productID;

      String planName = '';

      if (productId ==
          'pro_monthly') {
        planName = 'Pro';
      }

      if (productId ==
          'business_monthly') {
        planName = 'Business';
      }

      if (planName.isEmpty) {
        throw Exception(
          'Unknown subscription product.',
        );
      }

      final purchaseToken =
          purchase.verificationData
              .serverVerificationData;

      if (purchaseToken.isEmpty) {
        throw Exception(
          'Purchase token is empty.',
        );
      }

      final response = await http.post(
        Uri.parse(
          'https://aibusinesspostmaker-production.up.railway.app/api/subscription/verify',
        ),
        headers: {
          'Authorization':
              'Bearer $token',
          'Content-Type':
              'application/json',
        },
        body: jsonEncode({
          'plan_name': planName,
          'purchase_token':
              purchaseToken,
        }),
      );

      final data =
          jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data['success'] == true) {
        if (mounted) {
          setState(() {
            _isPurchasing = false;
          });
        }

        await _loadSubscriptionData();

        if (!mounted) return;

        _showMessage(
          '$planName plan activated successfully!',
        );

        return;
      }

      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });

        _showMessage(
          data['message']?.toString() ??
              'Subscription verification failed.',
          isError: true,
        );
      }
    } catch (e) {
      debugPrint(
        'VERIFY PURCHASE ERROR: $e',
      );

      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });

        _showMessage(
          'Could not verify subscription with server.',
          isError: true,
        );
      }
    }
  }

  // ==========================================================
  // RESTORE PURCHASE
  // ==========================================================

  Future<void> _restorePurchase() async {
    if (_isRestoring) {
      return;
    }

    if (!_storeAvailable) {
      _showMessage(
        'Google Play is currently unavailable.',
        isError: true,
      );

      return;
    }

    setState(() {
      _isRestoring = true;
    });

    try {
      await _inAppPurchase
          .restorePurchases();

      await Future.delayed(
        const Duration(
          seconds: 2,
        ),
      );

      await _loadSubscriptionData();

      if (!mounted) return;

      setState(() {
        _isRestoring = false;
      });

      _showMessage(
        'Restore request completed.',
      );
    } catch (e) {
      debugPrint(
        'RESTORE ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _isRestoring = false;
      });

      _showMessage(
        'Unable to restore purchases.',
        isError: true,
      );
    }
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
        backgroundColor:
            isError
                ? Colors.red.shade700
                : primaryColor,
        behavior:
            SnackBarBehavior.floating,
        margin:
            const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ==========================================================
  // GET PLAN
  // ==========================================================

  Map<String, dynamic>?
      _getPlan(String name) {
    for (final plan in _plans) {
      if (plan['name']
              ?.toString() ==
          name) {
        return plan;
      }
    }

    return null;
  }

  // ==========================================================
  // PRICE
  // ==========================================================

  String _getPrice(
    Map<String, dynamic> plan,
  ) {
    final planName =
        plan['name']?.toString() ??
            '';

    if (planName == 'Free') {
      return 'Free';
    }

    final productId =
        plan['google_product_id']
            ?.toString();

    final product =
        productId == null
            ? null
            : _products[productId];

    if (product != null) {
      return product.price;
    }

    return 'Loading...';
  }

  // ==========================================================
  // CURRENT PLAN CHECK
  // ==========================================================

  bool _isCurrentPlan(
    String planName,
  ) {
    return _currentPlan ==
        planName;
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          backgroundColor,

      appBar: AppBar(
        backgroundColor:
            backgroundColor,
        elevation: 0,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: textColor,
          ),
        ),

        title: const Text(
          'Subscription',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),

      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : RefreshIndicator(
              color: primaryColor,

              onRefresh:
                  _loadSubscriptionData,

              child:
                  SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),

                padding:
                    const EdgeInsets.fromLTRB(
                  18,
                  6,
                  18,
                  30,
                ),

                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    _buildHeader(),

                    const SizedBox(
                      height: 18,
                    ),

                    _buildCurrentPlanCard(),

                    const SizedBox(
                      height: 24,
                    ),

                    const Text(
                      'Choose Your Plan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w800,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    const Text(
                      'Create more content with the plan that fits your business.',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            secondaryText,
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    ..._buildPlanCards(),

                    const SizedBox(
                      height: 18,
                    ),

                    _buildRestoreCard(),

                    const SizedBox(
                      height: 16,
                    ),

                    const Text(
                      'Subscriptions are managed through Google Play.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            Color(0xFF5B4BDB),
            Color(0xFF7668E8),
          ],
        ),

        borderRadius:
            BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color:
                primaryColor
                    .withValues(alpha: .18),
            blurRadius: 18,
            offset:
                const Offset(0, 7),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,

            decoration:
                BoxDecoration(
              color:
                  Colors.white
                      .withValues(alpha: 
                0.18,
              ),
              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),

            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),

          const SizedBox(
            width: 13,
          ),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  'Unlock More AI Power',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Generate more posts and unlock premium business tools.',
                  style: TextStyle(
                    color:
                        Colors.white70,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // CURRENT PLAN
  // ==========================================================

  Widget _buildCurrentPlanCard() {
    final plan =
        _getPlan(_currentPlan);

    final limit =
        plan?['ai_generation_limit']
                ?.toString() ??
            '10';

    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(14),

        border: Border.all(
          color:
              const Color(0xFFE5E7EB),
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,

            decoration:
                BoxDecoration(
              color: lightPurple,
              borderRadius:
                  BorderRadius.circular(
                11,
              ),
            ),

            child: const Icon(
              Icons.workspace_premium_rounded,
              color: primaryColor,
              size: 22,
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
                const Text(
                  'Current Plan',
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        secondaryText,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  _currentPlan,
                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w800,
                    color: textColor,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  '$limit AI generations / month',
                  style:
                      const TextStyle(
                    fontSize: 10,
                    color:
                        secondaryText,
                  ),
                ),
              ],
            ),
          ),
// Agar end date available hai toh yeh show ho jaye ga
if (_subscriptionEndDate != null) ...[
  const SizedBox(height: 3),
  Text(
    'Expires on: $_subscriptionEndDate',
    style: const TextStyle(
      fontSize: 10,
      color: secondaryText,
    ),
  ),
],
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),

            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFEAF8EF),
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),

            child: Text(
              _currentStatus ==
                          'active' ||
                      _currentStatus == null
                  ? 'Active'
                  : _currentStatus!,
              style:
                  const TextStyle(
                color:
                    Color(0xFF18864B),
                fontSize: 9,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PLAN CARDS
  // ==========================================================

  List<Widget> _buildPlanCards() {
    final names = [
      'Free',
      'Pro',
      'Business',
    ];

    return names
        .map(
          (name) {
            final plan =
                _getPlan(name);

            if (plan == null) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 14,
              ),
              child:
                  _buildPlanCard(
                plan,
              ),
            );
          },
        )
        .toList();
  }

  // ==========================================================
  // SINGLE PLAN CARD
  // ==========================================================

  Widget _buildPlanCard(
    Map<String, dynamic> plan,
  ) {
    final name =
        plan['name']
                ?.toString() ??
            '';

    final isCurrent =
        _isCurrentPlan(name);

    final isPro =
        name == 'Pro';

    final isBusiness =
        name == 'Business';

    final limit =
        plan['ai_generation_limit']
                ?.toString() ??
            '10';

    final price =
        _getPrice(plan);

    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color: isCurrent ||
                  isPro
              ? primaryColor
              : const Color(
                  0xFFE5E7EB,
                ),
          width:
              isCurrent || isPro
                  ? 1.4
                  : 1,
        ),

        boxShadow:
            isCurrent || isPro
                ? [
                    BoxShadow(
                      color:
                          primaryColor
                              .withValues(alpha: 
                        0.08,
                      ),
                      blurRadius: 14,
                      offset:
                          const Offset(
                        0,
                        5,
                      ),
                    ),
                  ]
                : null,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          if (isPro ||
              isBusiness)
            Container(
              width:
                  double.infinity,

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 7,
              ),

              decoration:
                  BoxDecoration(
                color:
                    primaryColor,
                borderRadius:
                    const BorderRadius
                        .vertical(
                  top:
                      Radius.circular(
                    15,
                  ),
                ),
              ),

              child: Text(
                isPro
                    ? 'MOST POPULAR'
                    : 'FOR GROWING BUSINESSES',
                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontSize: 9,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing:
                      0.5,
                ),
              ),
            ),

          Padding(
            padding:
                const EdgeInsets.all(
              15,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.w800,
                          color:
                              textColor,
                        ),
                      ),
                    ),

                    if (isCurrent)
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal:
                              8,
                          vertical:
                              5,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              lightPurple,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                        ),
                        child:
                            const Text(
                          'CURRENT',
                          style:
                              TextStyle(
                            color:
                                primaryColor,
                            fontSize:
                                8,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(
                  height: 8,
                ),

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style:
                          const TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.w900,
                        color:
                            primaryColor,
                      ),
                    ),

                    if (name !=
                        'Free')
                      const Padding(
                        padding:
                            EdgeInsets.only(
                          left: 4,
                          bottom: 3,
                        ),
                        child:
                            Text(
                          '/ month',
                          style:
                              TextStyle(
                            fontSize:
                                10,
                            color:
                                secondaryText,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  '$limit AI generations per month',
                  style:
                      const TextStyle(
                    fontSize: 10,
                    color:
                        secondaryText,
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                _featureRow(
                  'AI post generation',
                  true,
                ),

                _featureRow(
                  'Premium templates',
                  plan['premium_templates'] ==
                      true,
                ),

                _featureRow(
                  'HD downloads',
                  plan['hd_downloads'] ==
                      true,
                ),

                _featureRow(
                  'Brand Kit',
                  plan['brand_kit_access'] ==
                      true,
                ),

                _featureRow(
                  'Advanced AI options',
                  plan['advanced_ai_options'] ==
                      true,
                ),

                _featureRow(
                  'Multiple businesses',
                  plan['multiple_business_profiles'] ==
                      true,
                ),

                _featureRow(
                  'Advanced marketing tools',
                  plan['advanced_marketing_tools'] ==
                      true,
                ),

                _featureRow(
                  'No advertisements',
                  plan['advertisements'] !=
                      true,
                ),

                const SizedBox(
                  height: 14,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height: 45,

                  child:
                      ElevatedButton(
                    onPressed:
                        isCurrent ||
                                _isPurchasing
                            ? null
                            : () {
                                _purchasePlan(
                                  plan,
                                );
                              },

                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          isCurrent
                              ? const Color(
                                  0xFFE5E7EB,
                                )
                              : primaryColor,

                      foregroundColor:
                          isCurrent
                              ? secondaryText
                              : Colors.white,

                      disabledBackgroundColor:
                          isCurrent
                              ? const Color(
                                  0xFFE5E7EB,
                                )
                              : primaryColor
                                  .withValues(alpha: 
                                  0.55,
                                ),

                      elevation: 0,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),

                    child:
                        _isPurchasing &&
                                !isCurrent
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : Text(
                                isCurrent
                                    ? 'Current Plan'
                                    : name ==
                                            'Free'
                                        ? 'Free Plan'
                                        : 'Upgrade to $name',
                                style:
                                    const TextStyle(
                                  fontSize:
                                      12,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // FEATURE ROW
  // ==========================================================

  Widget _featureRow(
    String title,
    bool enabled,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 8,
      ),

      child: Row(
        children: [
          Icon(
            enabled
                ? Icons.check_circle_rounded
                : Icons.remove_circle_outline_rounded,

            size: 16,

            color: enabled
                ? const Color(
                    0xFF22A05A,
                  )
                : const Color(
                    0xFFD1D5DB,
                  ),
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              title,
              style:
                  TextStyle(
                fontSize: 11,
                color: enabled
                    ? textColor
                    : secondaryText,
                fontWeight:
                    enabled
                        ? FontWeight.w500
                        : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // RESTORE CARD
  // ==========================================================

  Widget _buildRestoreCard() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color:
            const Color(0xFFFDFDFF),

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
            width: 38,
            height: 38,

            decoration:
                BoxDecoration(
              color: lightPurple,
              borderRadius:
                  BorderRadius.circular(
                9,
              ),
            ),

            child: const Icon(
              Icons.restore_rounded,
              color: primaryColor,
              size: 20,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Already subscribed?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w700,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Restore your Google Play subscription.',
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        secondaryText,
                  ),
                ),
              ],
            ),
          ),

          TextButton(
            onPressed:
                _isRestoring
                    ? null
                    : _restorePurchase,

            style:
                TextButton.styleFrom(
              foregroundColor:
                  primaryColor,
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 8,
              ),
            ),

            child:
                _isRestoring
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              primaryColor,
                        ),
                      )
                    : const Text(
                        'Restore',
                        style:
                            TextStyle(
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}