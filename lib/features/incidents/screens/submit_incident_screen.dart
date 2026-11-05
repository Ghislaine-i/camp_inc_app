import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants.dart';
import '../../../core/validators.dart';
import '../providers/incident_providers.dart';

class SubmitIncidentScreen extends ConsumerStatefulWidget {
  const SubmitIncidentScreen({super.key});

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

    return Scaffold(
      appBar: AppBar(title: const Text('Report an issue')),
      body: AbsorbPointer(
        absorbing: submitting,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _title,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: Validators.title,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<IncidentCategory>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    for (final c in IncidentCategory.values)
                      DropdownMenuItem(
                        value: c,
                        child: Row(children: [
                          Icon(c.icon, size: 20),
                          const SizedBox(width: 8),
                          Text(c.label),
                        ]),
                      ),
                  ],
                  onChanged: (c) => setState(() => _category = c),
                  validator: (c) =>
                      c == null ? 'Please choose a category' : null,
                ),
                const SizedBox(height: 16),
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
                  OutlinedButton.icon(
                    onPressed: _showPickerSheet,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Attach a photo (optional)'),
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
                FilledButton.icon(
                  onPressed: submitting ? null : _submit,
                  icon: submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: const Text('Submit report'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
