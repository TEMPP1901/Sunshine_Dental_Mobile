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
      Fluttertoast.showToast(msg: 'Đã duyệt');
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
        title: const Text('Từ chối yêu cầu'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Lý do (tùy chọn)',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Từ chối')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _hrService.rejectFaceProfile(
        requestId: item.requestId,
        reason: controller.text,
      );
      Fluttertoast.showToast(msg: 'Đã từ chối');
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
        title: const Text('Face Profile Approvals'),
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
                Text('Lỗi: $_error'),
                const SizedBox(height: 8),
                FilledButton(onPressed: _load, child: const Text('Thử lại')),
              ],
            ),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 48),
          Center(child: Text('Không có yêu cầu chờ duyệt')),
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
                CircleAvatar(
                  radius: 28,
                  backgroundImage: ApiService.resolveAvatarImage(item.newFaceImageUrl),
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
                        Text('Mã: ${item.code}', style: Theme.of(context).textTheme.bodySmall),
                      Text('Yêu cầu: ${item.requestedAtText}',
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
                  label: const Text('Từ chối'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Duyệt'),
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

    return FaceProfileRequest(
      requestId: int.parse(map['requestId']?.toString() ?? map['id']?.toString() ?? '0'),
      fullName: user?['fullName']?.toString() ?? 'N/A',
      email: user?['email']?.toString() ?? '',
      code: user?['code']?.toString() ?? '',
      newFaceImageUrl: map['newFaceImageUrl']?.toString() ?? '',
      requestedAt: requestedAt,
    );
  }

  String get requestedAtText {
    if (requestedAt == null) return 'N/A';
    return '${requestedAt!.year}-${requestedAt!.month.toString().padLeft(2, '0')}-${requestedAt!.day.toString().padLeft(2, '0')}';
  }
}

