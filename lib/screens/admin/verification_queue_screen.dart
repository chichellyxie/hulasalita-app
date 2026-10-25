import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../models/admin_models.dart';
import '../../repositories/admin_repository.dart';
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
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final v = _items[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: AppColors.navy, child: Icon(Icons.badge, color: Colors.white)),
                    title: Text(v.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${v.school ?? 'No school'}\n${v.email}'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final decided = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => VerificationDetailScreen(verification: v)),
                      );
                      if (decided == true) _load();
                    },
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

  @override
  Widget build(BuildContext context) {
    final v = widget.verification;

    return Scaffold(
      appBar: AppBar(title: Text(v.username)),
      body: SafeArea(
        child: Column(
          children: [
            ListTile(
              title: Text(v.school ?? 'No school'),
              subtitle: Text('${v.email}\nSubmitted: ${v.submittedAt?.substring(0, 10) ?? ''}'),
              isThreeLine: true,
            ),
            Expanded(
              child: FutureBuilder<Uint8List>(
                future: _image,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) return const LoadingView(label: 'Loading ID photo…');
                  if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                    return ErrorView(message: snapshot.error?.toString() ?? 'The ID photo is not available.', icon: Icons.broken_image);
                  }
                  return InteractiveViewer(child: Center(child: Image.memory(snapshot.data!)));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
                      onPressed: _busy ? null : () => _decide('rejected'),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : () => _decide('approved'),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
