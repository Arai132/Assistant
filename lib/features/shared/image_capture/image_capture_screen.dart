import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/database_provider.dart';
import '../../../services/secure_storage_service.dart';
import 'ai_description_service.dart';
import 'ocr_service.dart';

class ImageCaptureScreen extends ConsumerStatefulWidget {
  final String itemId;
  const ImageCaptureScreen({super.key, required this.itemId});

  @override
  ConsumerState<ImageCaptureScreen> createState() => _ImageCaptureScreenState();
}

class _ImageCaptureScreenState extends ConsumerState<ImageCaptureScreen> {
  File? _image;
  String _ocrText = '';
  String _aiDesc = '';
  bool _processingOcr = false;
  bool _processingAi = false;
  bool _hasApiKey = false;

  final _ocr = OcrService();
  final _titleCtrl = TextEditingController(text: 'Image note');

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  Future<void> _checkApiKey() async {
    final key = await SecureStorageService().getOpenAiKey();
    if (mounted) setState(() => _hasApiKey = key != null && key.isNotEmpty);
  }

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: source);
    if (xFile == null) return;
    final file = File(xFile.path);
    setState(() { _image = file; _processingOcr = true; });
    final text = await _ocr.extractText(file);
    if (mounted) setState(() { _ocrText = text; _processingOcr = false; });
  }

  Future<void> _describeWithAi() async {
    if (_image == null) return;
    setState(() => _processingAi = true);
    try {
      final key = await SecureStorageService().getOpenAiKey();
      final desc = await AiDescriptionService(apiKey: key!).describe(_image!);
      if (mounted) setState(() => _aiDesc = desc);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Description unavailable, using OCR only')),
        );
      }
    } finally {
      if (mounted) setState(() => _processingAi = false);
    }
  }

  Future<void> _save() async {
    if (_image == null) return;
    final repo = ref.read(attachmentRepositoryProvider);
    final attachId = await repo.saveAttachment(
      itemId: widget.itemId,
      sourceFile: _image!,
      type: AttachmentType.image,
    );
    final db = ref.read(databaseProvider);
    if (_ocrText.isNotEmpty) await db.attachmentsDao.updateOcrText(attachId, _ocrText);
    if (_aiDesc.isNotEmpty) await db.attachmentsDao.updateAiDescription(attachId, _aiDesc);
    if (_ocrText.isNotEmpty) await db.itemsDao.updateItemBody(widget.itemId, _ocrText);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _ocr.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Image')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_image == null) ...[
              FilledButton.icon(
                onPressed: () => _pick(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ] else ...[
              Image.file(_image!, height: 200, fit: BoxFit.cover),
              const SizedBox(height: 12),
              if (_processingOcr)
                const CircularProgressIndicator()
              else if (_ocrText.isNotEmpty) ...[
                Text('OCR Result', style: Theme.of(context).textTheme.titleSmall),
                Text(_ocrText),
              ],
              if (_hasApiKey && !_processingOcr) ...[
                const SizedBox(height: 8),
                _processingAi
                    ? const CircularProgressIndicator()
                    : OutlinedButton.icon(
                        onPressed: _describeWithAi,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Describe with AI'),
                      ),
                if (_aiDesc.isNotEmpty) ...[
                  Text('AI Description', style: Theme.of(context).textTheme.titleSmall),
                  Text(_aiDesc),
                ],
              ],
              const SizedBox(height: 16),
              FilledButton(onPressed: _save, child: const Text('Save')),
            ],
          ],
        ),
      ),
    );
  }
}
