//import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfSaveResult {
  final String? saved; // path '/storage/..' hoặc URI 'content://..'
  final Uint8List bytes; // dùng cho preview khi mở
  final String suggestedName;
  PdfSaveResult({
    required this.saved,
    required this.bytes,
    required this.suggestedName,
  });
}

class RecipeExportService {
  final _db = FirebaseFirestore.instance;

  Future<PdfSaveResult> exportFoodToPdfAndSave({required String foodId}) async {
    // Lấy dữ liệu
    final doc = await _db.collection('foods').doc(foodId).get();
    if (!doc.exists) throw Exception('Không tìm thấy món ăn');
    final data = doc.data() as Map<String, dynamic>;

    final name = (data['name'] ?? 'Món ăn').toString();
    final calories = (data['calories'] ?? '').toString();
    final diet = (data['diet'] ?? '').toString();
    final ingredients = (data['ingredients'] ?? '').toString();
    final instructions = (data['instructions'] ?? '').toString();
    final imageUrl = (data['image_url'] ?? '').toString();

    // Ảnh
    Uint8List? imageBytes;
    if (imageUrl.isNotEmpty) {
      try {
        final res = await http.get(Uri.parse(imageUrl));
        if (res.statusCode == 200) {
          imageBytes = Uint8List.fromList(res.bodyBytes);
        }
      } catch (e) {
        if (kDebugMode) print('[PDF] load image error: $e');
      }
    }

    // Load font (fallback nếu lỗi)
    pw.Font? fontBase;
    pw.Font? fontBold;
    try {
      fontBase = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
      );
      fontBold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
      );
    } catch (e) {
      if (kDebugMode) print('[PDF] load font error: $e');
    }

    final pdf = (fontBase != null && fontBold != null)
        ? pw.Document(
            theme: pw.ThemeData.withFont(base: fontBase, bold: fontBold),
          )
        : pw.Document();

    pw.Widget buildHeader() => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          name,
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        if (calories.isNotEmpty || diet.isNotEmpty)
          pw.Padding(
            padding: pw.EdgeInsets.only(top: 4),
            child: pw.Text(
              [
                if (calories.isNotEmpty) 'Calo: $calories kcal',
                if (diet.isNotEmpty) 'Chế độ ăn: $diet',
              ].join('  |  '),
              style: pw.TextStyle(fontSize: 12),
            ),
          ),
      ],
    );

    pw.Widget buildSectionTitle(String t) => pw.Padding(
      padding: pw.EdgeInsets.only(top: 16, bottom: 6),
      child: pw.Text(
        t,
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
    );

    final ingredientLines = ingredients
        .split(RegExp(r'[\n\r,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final instructionLines = instructions
        .split(RegExp(r'[\n\r]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    pdf.addPage(
      pw.MultiPage(
        margin: pw.EdgeInsets.all(24),
        build: (context) => [
          buildHeader(),
          if (imageBytes != null) ...[
            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Image(
                pw.MemoryImage(imageBytes),
                width: PdfPageFormat.a4.availableWidth,
                height: 200,
                fit: pw.BoxFit.cover,
              ),
            ),
          ],
          buildSectionTitle('Nguyên liệu'),
          if (ingredientLines.isEmpty)
            pw.Text('Không có')
          else
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (final line in ingredientLines)
                  pw.Bullet(text: line, style: pw.TextStyle(fontSize: 12)),
              ],
            ),
          buildSectionTitle('Hướng dẫn'),
          if (instructionLines.isEmpty)
            pw.Text('Không có hướng dẫn.')
          else
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < instructionLines.length; i++)
                  pw.Padding(
                    padding: pw.EdgeInsets.only(bottom: 6),
                    child: pw.Text(
                      '${i + 1}. ${instructionLines[i]}',
                      style: pw.TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );

    final bytes = await pdf.save();

    // Lưu vào Downloads
    final safeName = _sanitizeFileName(name.isEmpty ? 'recipe' : name);
    final fileName = '$safeName.pdf';

    final String saved = await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      mimeType: MimeType.pdf,
    );

    if (kDebugMode) print('[PDF] saved: $saved');
    return PdfSaveResult(
      saved: saved.isNotEmpty ? saved : null,
      bytes: Uint8List.fromList(bytes),
      suggestedName: fileName,
    );
  }

  String _sanitizeFileName(String input) {
    final s = input
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return s.isEmpty ? 'recipe' : s;
  }
}
