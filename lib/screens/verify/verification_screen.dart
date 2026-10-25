import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
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
      body = 'The administrator could not verify your school ID. Please upload a clear photo where your name, school and ID number are readable.';
      icon = Icons.error_outline;
    } else if (waiting) {
      title = 'Waiting for verification';
      body = 'Your school ID is being reviewed. You can play as soon as the administrator approves your account.';
      icon = Icons.hourglass_top;
    } else {
      title = 'Verify that you are a student';
      body = 'Upload a photo of your school ID. It is seen only by the administrator and deleted after review.';
      icon = Icons.badge_outlined;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('HulaSalita'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _checkStatus,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Icon(icon, size: 72, color: rejected ? Colors.red.shade400 : AppColors.navy),
              const SizedBox(height: 16),
              Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(body, textAlign: TextAlign.center),
              if (user != null) ...[
                const SizedBox(height: 8),
                Text('${user.username} · ${user.school?.name ?? ''}',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
              ],
              const SizedBox(height: 24),
              if (_photo != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_photo!, height: 220, fit: BoxFit.cover),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: auth.busy ? null : () => _pick(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: auth.busy ? null : () => _pick(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: (_photo == null || auth.busy) ? null : _upload,
                icon: auth.busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.cloud_upload),
                label: Text(waiting ? 'Replace uploaded ID' : 'Upload school ID'),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: auth.busy ? null : _checkStatus,
                icon: const Icon(Icons.refresh),
                label: const Text('Check my status'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
