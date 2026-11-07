import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants.dart';
import '../../../core/validators.dart';
import '../../../core/theme.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/incident_providers.dart';

class SubmitIncidentScreen extends ConsumerStatefulWidget {
  const SubmitIncidentScreen({super.key, this.initialCategory});
  final IncidentCategory? initialCategory;

  @override
  ConsumerState<SubmitIncidentScreen> createState() =>
      _SubmitIncidentScreenState();
}

class _SubmitIncidentScreenState extends ConsumerState<SubmitIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _picker = ImagePicker();

  IncidentCategory? _category;
  File? _image;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      // imageQuality + maxWidth compress the photo before it is uploaded.
      final x = await _picker.pickImage(
          source: source, imageQuality: 70, maxWidth: 1280);
      if (x != null) setState(() => _image = File(x.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not get photo: $e')));
    }
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(submitControllerProvider.notifier).submit(
          title: _title.text,
          description: _description.text,
          category: _category!,
          location: _location.text,
          image: _image,
        );
    if (ok && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted. Thank you!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(submitControllerProvider, (prev, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Submit failed: ${next.error}')));
      }
    });
    final submitting = ref.watch(submitControllerProvider).isLoading;
    final progress = ref.watch(uploadProgressProvider);
    if (ref.watch(isStaffProvider)) {
      return Scaffold(
        appBar: AppBar(title: const Text('New report')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              "Staff accounts can't submit reports",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('New report')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          onPressed: submitting ? null : _submit,
          icon: submitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.send_rounded),
          label: const Text('Submit report'),
        ),
      ),
      body: AbsorbPointer(
        absorbing: submitting,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Category',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: AppColors.muted)),
                const SizedBox(height: 8),
                FormField<IncidentCategory>(
                  initialValue: _category,
                  validator: (c) =>
                      c == null ? 'Please choose a category' : null,
                  builder: (field) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            for (final c in IncidentCategory.values)
                              ChoiceChip(
                                avatar: Icon(c.icon, size: 18),
                                label: Text(c.label),
                                selected: _category == c,
                                onSelected: (_) {
                                  setState(() => _category = c);
                                  field.didChange(c);
                                },
                              )
                          ],
                        ),
                        if (field.hasError)
                          Padding(
                              padding: const EdgeInsets.only(top: 6, left: 12),
                              child: Text(field.errorText!,
                                  style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                      fontSize: 12))),
                      ]),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _title,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: Validators.title,
                ),
                TextFormField(
                  controller: _location,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'e.g. Block B, Room 204',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                  validator: Validators.location,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  maxLines: 5,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                      labelText: 'Description', alignLabelWithHint: true),
                  validator: Validators.description,
                ),
                const SizedBox(height: 8),
                if (_image != null)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_image!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover),
                      ),
                      IconButton.filled(
                        onPressed: () => setState(() => _image = null),
                        icon: const Icon(Icons.close),
                        tooltip: 'Remove photo',
                      ),
                    ],
                  )
                else
                  InkWell(
                    onTap: _showPickerSheet,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 110,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.outline),
                        borderRadius: BorderRadius.circular(14),
                        color: AppColors.surface,
                      ),
                      child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_rounded,
                                color: AppColors.primary, size: 28),
                            SizedBox(height: 6),
                            Text('Add a photo (optional)'),
                          ]),
                    ),
                  ),
                const SizedBox(height: 24),
                if (submitting && _image != null) ...[
                  LinearProgressIndicator(
                      value: progress > 0 ? progress : null),
                  const SizedBox(height: 4),
                  Text(
                      'Uploading photo... ${(progress * 100).toStringAsFixed(0)}%',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
