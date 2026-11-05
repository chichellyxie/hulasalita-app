import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../models/admin_models.dart';
import '../../repositories/admin_repository.dart';
import '../../widgets/app_header.dart';
import '../../widgets/error_view.dart';

class VerificationQueueScreen extends StatefulWidget {
  const VerificationQueueScreen({super.key});

  @override
  State<VerificationQueueScreen> createState() => _VerificationQueueScreenState();
}

class _VerificationQueueScreenState extends State<VerificationQueueScreen> {
  List<AdminVerification> _items = [];
  bool _loading = true;
  String? _error;

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
      final page = await context.read<AdminRepository>().verifications();
      _items = page.items;
    } on ApiException catch (e) {
      _error = e.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _items.isEmpty) return const LoadingView();
    if (_error != null && _items.isEmpty) return ErrorView(message: _error!, onRetry: _load);

    return RefreshIndicator(
      onRefresh: _load,
      child: _items.isEmpty
          ? ListView(children: const [
              SizedBox(height: 120),
              Icon(Icons.inbox, size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text('No school IDs waiting for review.', textAlign: TextAlign.center),
            ])
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: _items.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SectionLabel('${_items.length} waiting · oldest first'),
                        const Spacer(),
                        const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.muted),
                        const SizedBox(width: 4),
                        const Text('Photos are private', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
                  );
                }
                final v = _items[i - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: i == 1 ? AppColors.gold : AppColors.line, width: i == 1 ? 2 : 1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () async {
                        final decided = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(builder: (_) => VerificationDetailScreen(verification: v)),
                        );
                        if (decided == true) _load();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 23,
                              backgroundColor: AppColors.navySoft,
                              child: Text(v.username.isNotEmpty ? v.username[0].toUpperCase() : '?',
                                  style: displayStyle(size: 20)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(v.username, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                  Text(v.school ?? 'No school', style: const TextStyle(fontSize: 13, color: Color(0xFF3A4060))),
                                  Text('${v.email} · ${v.submittedAt?.substring(0, 10) ?? ''}',
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                                ],
                              ),
                            ),
                            const Pill(label: 'Review', background: AppColors.navy, foreground: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// Shows the private ID photo and lets the admin approve or reject.
/// The server deletes the photo right after the decision.
class VerificationDetailScreen extends StatefulWidget {
  const VerificationDetailScreen({super.key, required this.verification});

  final AdminVerification verification;

  @override
  State<VerificationDetailScreen> createState() => _VerificationDetailScreenState();
}

class _VerificationDetailScreenState extends State<VerificationDetailScreen> {
  late Future<Uint8List> _image;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _image = context.read<AdminRepository>().verificationDocument(widget.verification.id);
  }

  Future<void> _decide(String decision) async {
    final approve = decision == 'approved';
    final ok = await confirmDialog(
      context,
      title: approve ? 'Approve this student?' : 'Reject this ID?',
      message: approve
          ? '${widget.verification.username} will be able to play. The ID photo will be deleted.'
          : '${widget.verification.username} will be asked to upload a new ID. This photo will be deleted.',
      confirmLabel: approve ? 'Approve' : 'Reject',
    );
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    try {
      await context.read<AdminRepository>().decide(widget.verification.id, decision);
      if (!mounted) return;
      showSnack(context, approve ? 'Student approved.' : 'ID rejected.');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSnack(context, e.message, error: true);
    }
  }

  final Set<int> _checked = {};

  static const _checklist = [
    'School name matches the one chosen',
    'Photo is clear and readable',
    'ID is for the current school year',
  ];

  @override
  Widget build(BuildContext context) {
    final v = widget.verification;

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: v.username,
            subtitle: 'Submitted ${v.submittedAt?.substring(0, 10) ?? ''}',
            showBack: true,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        _info('School chosen', v.school ?? 'No school'),
                        const SizedBox(height: 6),
                        _info('Email', v.email),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 260,
                    color: AppColors.ink,
                    child: FutureBuilder<Uint8List>(
                      future: _image,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(child: CircularProgressIndicator(color: Colors.white));
                        }
                        if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text('The ID photo is not available.', style: TextStyle(color: Colors.white70)),
                          );
                        }
                        return InteractiveViewer(child: Center(child: Image.memory(snapshot.data!)));
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Pinch to zoom', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionLabel('Checklist'),
                        for (var i = 0; i < _checklist.length; i++)
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: AppColors.correct,
                            value: _checked.contains(i),
                            onChanged: (on) => setState(() {
                              if (on == true) {
                                _checked.add(i);
                              } else {
                                _checked.remove(i);
                              }
                            }),
                            title: Text(_checklist[i], style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            foregroundColor: AppColors.wrong,
                            side: const BorderSide(color: Color(0xFFB23A3A), width: 2),
                          ),
                          onPressed: _busy ? null : () => _decide('rejected'),
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.correct),
                          onPressed: _busy ? null : () => _decide('approved'),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('The photo is deleted right after your decision.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value) => Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w700)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          ),
        ],
      );
}
