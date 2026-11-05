import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/error_view.dart';

/// Pending / rejected students: upload the school ID and wait for review.
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _picker = ImagePicker();
  File? _photo;

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, maxWidth: 1600, imageQuality: 80);
      if (file != null) setState(() => _photo = File(file.path));
    } catch (e) {
      if (mounted) showSnack(context, 'Could not open the camera or gallery.', error: true);
    }
  }

  Future<void> _upload() async {
    final photo = _photo;
    if (photo == null) return;
    try {
      await context.read<AuthProvider>().uploadSchoolId(photo.path);
      if (!mounted) return;
      setState(() => _photo = null);
      showSnack(context, 'School ID uploaded. Please wait for the administrator.');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.fieldError('id_image') ?? e.message, error: true);
    }
  }

  Future<void> _checkStatus() async {
    try {
      await context.read<AuthProvider>().refreshUser();
      if (!mounted) return;
      final status = context.read<AuthProvider>().status;
      if (status == AuthStatus.pending) showSnack(context, 'Still waiting for review.');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final rejected = auth.status == AuthStatus.rejected;
    final waiting = !rejected && (user?.hasUploadedId ?? false);

    final String title;
    final String body;
    final IconData icon;
    if (rejected) {
      title = 'School ID not accepted';
      body = 'Please upload a clear photo where your name, school and ID number are readable.';
      icon = Icons.error_outline_rounded;
    } else if (waiting) {
      title = 'Almost there!';
      body = 'Your school ID is being reviewed.';
      icon = Icons.hourglass_top_rounded;
    } else {
      title = 'Verify that you are a student';
      body = 'Upload a photo of your school ID.';
      icon = Icons.badge_outlined;
    }

    // 0 = upload ID, 1 = admin review
    final current = waiting ? 1 : 0;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _checkStatus,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            AppHeader(
              title: 'HulaSalita',
              actions: [
                HeaderButton(
                  icon: Icons.logout_rounded,
                  tooltip: 'Log out',
                  onPressed: () => context.read<AuthProvider>().logout(),
                ),
              ],
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: rejected ? AppColors.wrongSoft : AppColors.gold,
                    child: Icon(icon, size: 30, color: rejected ? AppColors.wrong : AppColors.ink),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: displayStyle(size: 22, color: Colors.white)),
                        Text(body, style: const TextStyle(color: Color(0xFFC9CDF2), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          _step(1, 'Account created', done: true),
                          _step(2, rejected ? 'Upload a new school ID' : 'School ID uploaded', done: current > 0, active: current == 0, error: rejected),
                          _step(3, 'Admin review', subtitle: 'Usually within 1–2 school days', active: current == 1),
                          _step(4, 'Start playing!', last: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (user != null)
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.navySoft,
                          child: Text(user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
                        ),
                        title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text(user.school?.name ?? ''),
                      ),
                    ),
                  const SizedBox(height: 14),
                  if (_photo != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(_photo!, height: 200, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: auth.busy ? null : () => _pick(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera_rounded),
                          label: const Text('Camera'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: auth.busy ? null : () => _pick(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_rounded),
                          label: const Text('Gallery'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: (_photo == null || auth.busy) ? null : _upload,
                    icon: auth.busy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.cloud_upload_rounded),
                    label: Text(waiting ? 'Replace uploaded ID' : 'Upload school ID'),
                  ),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: auth.busy ? null : _checkStatus,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Check my status'),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.goldSoft, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionLabel('While you wait · Bugtong', color: Color(0xFF6B4600)),
                        const SizedBox(height: 6),
                        Text('Isang butil ng palay,\nsakop ang buong bahay.', style: displayStyle(size: 19, weight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        const Text("Think about it — you can answer it once you're verified!",
                            style: TextStyle(fontSize: 13, color: Color(0xFF4A3A12))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Your ID photo is seen only by the administrator and deleted after review.',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One row of the status timeline.
  Widget _step(int n, String label, {String? subtitle, bool done = false, bool active = false, bool error = false, bool last = false}) {
    final Color circle = error ? AppColors.wrong : done ? AppColors.correct : active ? AppColors.gold : Colors.transparent;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: circle,
              shape: BoxShape.circle,
              border: (done || active || error) ? null : Border.all(color: const Color(0xFFC3C8E4), width: 2),
            ),
            child: done
                ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                : Text('$n', style: TextStyle(fontWeight: FontWeight.w800, color: error ? Colors.white : active ? AppColors.ink : AppColors.muted)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: active ? AppColors.navy : (done ? AppColors.ink : AppColors.muted),
                    )),
                if (subtitle != null && active) Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
