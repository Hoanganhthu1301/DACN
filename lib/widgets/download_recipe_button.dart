import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import '../services/recipe_export_service.dart';

class DownloadRecipeButton extends StatefulWidget {
  final String foodId;
  const DownloadRecipeButton({super.key, required this.foodId});

  @override
  State<DownloadRecipeButton> createState() => _DownloadRecipeButtonState();
}

class _DownloadRecipeButtonState extends State<DownloadRecipeButton> {
  bool _busy = false;
  final _svc = RecipeExportService();

  Future<void> _saveAs(Uint8List bytes, String suggestedName) async {
    final params = SaveFileDialogParams(data: bytes, fileName: suggestedName);
    final savedPath = await FlutterFileDialog.saveFile(params: params);
    if (!mounted) return;
    if (savedPath != null && savedPath.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã lưu: $savedPath')));
    }
  }

  Future<void> _download() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final result = await _svc.exportFoodToPdfAndSave(foodId: widget.foodId);
      if (!mounted) return;

      // Hiển thị các lựa chọn còn lại
      showModalBottomSheet(
        context: context,
        builder: (_) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Xem trước trong ứng dụng'),
                onTap: () async {
                  Navigator.pop(context);
                  await Printing.layoutPdf(onLayout: (_) async => result.bytes);
                },
              ),
              ListTile(
                leading: const Icon(Icons.save_alt),
                title: const Text('Lưu vào ...'),
                onTap: () async {
                  Navigator.pop(context);
                  await _saveAs(result.bytes, result.suggestedName);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Đóng'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Lỗi khi xuất PDF: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Tải hướng dẫn (PDF)',
      onPressed: _busy ? null : _download,
      icon: _busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.download),
    );
  }
}
