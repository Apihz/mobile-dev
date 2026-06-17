import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/task.dart';
import '../../../state/team_state.dart';
import '../services/ai_extract_service.dart';
import 'ai_preview_screen.dart';

/// Entry screen for AI task extraction: pick a PDF or paste text, choose the
/// overall start date + deadline, then extract.
class AiImportScreen extends StatefulWidget {
  final String projectId;

  const AiImportScreen({super.key, required this.projectId});

  @override
  State<AiImportScreen> createState() => _AiImportScreenState();
}

class _AiImportScreenState extends State<AiImportScreen> {
  final _textController = TextEditingController();
  final _service = AiExtractService();
  static final _ymd = DateFormat('d MMM yyyy');

  Uint8List? _pdfBytes;
  String? _pdfName;
  DateTime _startDate = DateTime.now();
  DateTime _deadline = DateTime.now().add(const Duration(days: 14));
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null) return;
    // Keep PDFs modest — they are sent inline (no Cloud Storage on Spark).
    if (file!.bytes!.lengthInBytes > 15 * 1024 * 1024) {
      _showError('That PDF is too large (max ~15 MB). Try a smaller file.');
      return;
    }
    setState(() {
      _pdfBytes = file.bytes;
      _pdfName = file.name;
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _deadline,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_deadline.isBefore(_startDate)) _deadline = _startDate;
      } else {
        _deadline = picked;
      }
    });
  }

  Future<void> _extract() async {
    final text = _textController.text.trim();
    if (_pdfBytes == null && text.isEmpty) {
      _showError('Add a PDF or paste some text first.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final members = context.read<TeamState>().members;
      final List<Task> tasks = await _service.extractTasks(
        text: text.isEmpty ? null : text,
        pdfBytes: _pdfBytes,
        startDate: _startDate,
        deadline: _deadline,
        members: members,
      );

      if (!mounted) return;
      if (tasks.isEmpty) {
        _showError('No tasks could be extracted. Try a clearer brief.');
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AiPreviewScreen(
            projectId: widget.projectId,
            tasks: tasks,
          ),
        ),
      );
    } catch (e) {
      _showError('Extraction failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Task Import')),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Add an assignment brief',
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Upload a PDF or paste text. (Export Word docs to PDF.)',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // PDF picker
            OutlinedButton.icon(
              onPressed: _pickPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(_pdfName ?? 'Choose PDF'),
            ),
            if (_pdfName != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() {
                        _pdfBytes = null;
                        _pdfName = null;
                      }),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Remove PDF'),
                ),
              ),

            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              maxLines: 8,
              minLines: 4,
              style: const TextStyle(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Or paste the brief text here...',
                hintStyle: const TextStyle(color: AppColors.muted),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _DateTile(
                    label: 'Start date',
                    value: _ymd.format(_startDate),
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateTile(
                    label: 'Deadline',
                    value: _ymd.format(_deadline),
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _isLoading ? null : _extract,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isLoading ? 'Extracting...' : 'Extract tasks'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
