import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';

import '../../services/api_service.dart';
import '../../services/hr_service.dart';

class FaceProfileApprovalPage extends StatefulWidget {
  const FaceProfileApprovalPage({super.key});

  @override
  State<FaceProfileApprovalPage> createState() => _FaceProfileApprovalPageState();
}

class _FaceProfileApprovalPageState extends State<FaceProfileApprovalPage> {
  final HrService _hrService = HrService();
  bool _loading = false;
  String? _error;
  List<FaceProfileRequest> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _hrService.fetchPendingFaceProfiles();
      setState(() {
        _items = data.map(FaceProfileRequest.fromMap).toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _approve(FaceProfileRequest item) async {
    try {
      await _hrService.approveFaceProfile(item.requestId);
      Fluttertoast.showToast(msg: 'hr.faceApprovals.approved'.tr());
      _load();
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  Future<void> _reject(FaceProfileRequest item) async {
    final controller = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('hr.faceApprovals.rejectTitle'.tr()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'hr.faceApprovals.rejectReason'.tr(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('hr.common.cancel'.tr())),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text('hr.faceApprovals.reject'.tr())),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _hrService.rejectFaceProfile(
        requestId: item.requestId,
        reason: controller.text,
      );
      Fluttertoast.showToast(msg: 'hr.faceApprovals.rejected'.tr());
      _load();
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/hr'),
        ),
        title: Text('hr.faceApprovals.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${'hr.common.error'.tr()}: $_error'),
                const SizedBox(height: 8),
                FilledButton(onPressed: _load, child: Text('hr.common.retry'.tr())),
              ],
            ),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 48),
          Center(child: Text('hr.faceApprovals.noPendingRequests'.tr())),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _items[index];
        return FaceProfileCard(
          item: item,
          onApprove: () => _approve(item),
          onReject: () => _reject(item),
        );
      },
    );
  }
}

class FaceProfileCard extends StatelessWidget {
  final FaceProfileRequest item;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const FaceProfileCard({
    super.key,
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Builder(
                  builder: (context) {
                    // Resolve URL trước để log và debug
                    final imageUrl = item.newFaceImageUrl;
                    final resolvedUrl = imageUrl.isNotEmpty 
                        ? ApiService.resolveUrl(imageUrl)
                        : '';
                    
                    if (kDebugMode) {
                      debugPrint('[FaceProfileCard] Image URL resolution:');
                      debugPrint('  - Original URL: $imageUrl');
                      debugPrint('  - Resolved URL: $resolvedUrl');
                      debugPrint('  - Base URL: ${ApiService.baseUrl}');
                    }
                    
                    // Sử dụng Container với ClipRRect và Image widget giống home page
                    // để có error handling tốt hơn
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey[300],
                        child: imageUrl.isNotEmpty
                            ? Image(
                                image: ApiService.resolveAvatarImage(
                                  imageUrl,
                                  defaultAsset: 'assets/images/doctor.png',
                                ),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  if (kDebugMode) {
                                    debugPrint('[FaceProfileCard] Failed to load image:');
                                    debugPrint('  - Original URL: $imageUrl');
                                    debugPrint('  - Resolved URL: $resolvedUrl');
                                    debugPrint('  - Error: $error');
                                    debugPrint('  - StackTrace: $stackTrace');
                                  }
                                  return Container(
                                    color: Colors.grey[300],
                                    child: Icon(
                                      Icons.person,
                                      size: 32,
                                      color: Colors.grey[600],
                                    ),
                                  );
                                },
                              )
                            : Icon(
                                Icons.person,
                                size: 32,
                                color: Colors.grey[600],
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.fullName, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(item.email, style: Theme.of(context).textTheme.bodySmall),
                      if (item.code.isNotEmpty)
                        Text('hr.faceApprovals.code'.tr(args: [item.code]), style: Theme.of(context).textTheme.bodySmall),
                      Text('hr.faceApprovals.requestedAt'.tr(args: [item.requestedAtText]),
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close_rounded, color: Colors.red),
                  label: Text('hr.faceApprovals.reject'.tr()),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text('hr.faceApprovals.approve'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FaceProfileRequest {
  final int requestId;
  final String fullName;
  final String email;
  final String code;
  final String newFaceImageUrl;
  final DateTime? requestedAt;

  FaceProfileRequest({
    required this.requestId,
    required this.fullName,
    required this.email,
    required this.code,
    required this.newFaceImageUrl,
    required this.requestedAt,
  });

  factory FaceProfileRequest.fromMap(Map<String, dynamic> map) {
    final user = map['user'] as Map<String, dynamic>?;
    final requestedAtRaw = map['requestedAt']?.toString();
    DateTime? requestedAt;
    if (requestedAtRaw != null && requestedAtRaw.isNotEmpty) {
      requestedAt = DateTime.tryParse(requestedAtRaw);
    }

    final newFaceImageUrl = map['newFaceImageUrl']?.toString() ?? '';
    
    // Debug: Log the image URL to see what backend is returning
    debugPrint('[FaceProfileRequest] Parsing request:');
    debugPrint('  - RequestId: ${map['requestId']}');
    debugPrint('  - UserId: ${user?['id']}');
    debugPrint('  - FullName: ${user?['fullName']}');
    debugPrint('  - newFaceImageUrl: $newFaceImageUrl');
    debugPrint('  - Raw map: $map');

    return FaceProfileRequest(
      requestId: int.parse(map['requestId']?.toString() ?? map['id']?.toString() ?? '0'),
      fullName: user?['fullName']?.toString() ?? 'N/A',
      email: user?['email']?.toString() ?? '',
      code: user?['code']?.toString() ?? '',
      newFaceImageUrl: newFaceImageUrl,
      requestedAt: requestedAt,
    );
  }

  String get requestedAtText {
    if (requestedAt == null) return 'N/A';
    return '${requestedAt!.year}-${requestedAt!.month.toString().padLeft(2, '0')}-${requestedAt!.day.toString().padLeft(2, '0')}';
  }
}

