import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:receipt_application/models/image_model.dart';
import 'package:share_plus/share_plus.dart';
import '../localdb/database_helper.dart';

class HistoryViewModel extends ChangeNotifier {
  List<Map<String, dynamic>> history = [];

  HistoryViewModel() {
    _initialize();
  }

  Future<void> _initialize() async {
    await loadHistory();
  }

  Future<void> saveDataTableToHistory(
      List<Map<String, dynamic>> receiptDataList,
      List<ImageModel> images) async {
    final initTimestamp = DateTime.now();
    final timestamp = DateFormat('MM/dd/yyyy hh:mm a').format(initTimestamp);

    // Prepare history data
    final historyData = receiptDataList
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final receiptData = entry.value;

          // Skip if the image or receipt data is incomplete
          if (index >= images.length || receiptData.isEmpty) return null;

          return {
            "Company Name": images[index].companyName ?? "N/A",
            "Meeting Info": images[index].meetingInfo ?? "N/A",
            "Purpose":
                images[index].purposeOfExpense?.toString().split('.').last ??
                    "N/A",
            "Image Name": receiptData["Image Name"] ?? "Unknown",
            "Store Name": receiptData["Store Name"] ?? "N/A",
            "Date": receiptData["Date"] ?? "N/A",
            "Subtotal": double.tryParse(receiptData["Subtotal"] ?? "0") ?? 0.0,
            "GST": double.tryParse(receiptData["GST"] ?? "0") ?? 0.0,
            "PST": double.tryParse(receiptData["PST"] ?? "0") ?? 0.0,
            "HST": double.tryParse(receiptData["HST"] ?? "0") ?? 0.0,
            "Tip": double.tryParse(receiptData["Tip"] ?? "0") ?? 0.0,
            "Total": double.tryParse(receiptData["Total"] ?? "0") ?? 0.0,
          };
        })
        .where((entry) => entry != null)
        .toList();

    // Sort history data by the "Date" field
    historyData.sort((a, b) {
      final dateA = DateTime.tryParse(a?["Date"] ?? "") ?? DateTime.now();
      final dateB = DateTime.tryParse(b?["Date"] ?? "") ?? DateTime.now();
      return dateA.compareTo(dateB); // Ascending order
    });

    // Convert history data to JSON
    final jsonHistory = jsonEncode(historyData);

    // Save to SQLite
    await DatabaseHelper.instance.addHistoryRecord(timestamp, jsonHistory);

    await loadHistory(); // Refresh state
  }

  Future<void> loadHistory() async {
    final rawHistory = await DatabaseHelper.instance.getAllHistory();
    history = rawHistory
        .map((entry) {
          final data = jsonDecode(entry['table_data']);
          final formattedData = (data is List && data.isNotEmpty)
              ? data.cast<Map<String, dynamic>>()
              : null;

          if (formattedData == null || formattedData.isEmpty) return null;

          return {
            'timestamp': entry['timestamp'],
            'data': formattedData,
          };
        })
        .where((entry) => entry != null)
        .cast<Map<String, dynamic>>()
        .toList();

    notifyListeners();
  }

  Future<void> exportToExcel(
      BuildContext context, timestamp, List<Map<String, dynamic>> data) async {
    try {
      final excel = Excel.createExcel(); // Create a new Excel file
      final sheet = excel['Sheet1']; // Add a sheet

      // Add header row
      sheet.appendRow([
        TextCellValue("Company Name"),
        TextCellValue("Meeting Info"),
        TextCellValue("Purpose"),
        TextCellValue("Image Name"),
        TextCellValue("Store Name"),
        TextCellValue("Date"),
        TextCellValue("Subtotal"),
        TextCellValue("GST"),
        TextCellValue("PST"),
        TextCellValue("HST"),
        TextCellValue("Tip"),
        TextCellValue("Total"),
      ]);

      // Add data rows
      for (final row in data) {
        sheet.appendRow([
          TextCellValue(row["Company Name"] ?? "N/A"),
          TextCellValue(row["Meeting Info"] ?? "N/A"),
          TextCellValue(row["Purpose"] ?? "N/A"),
          TextCellValue(row["Image Name"] ?? "Unknown"),
          TextCellValue(row["Store Name"] ?? "N/A"),
          TextCellValue(row["Date"] ?? "N/A"),
          DoubleCellValue(
              double.tryParse(row["Subtotal"]?.toString() ?? '0') ?? 0),
          DoubleCellValue(double.tryParse(row["GST"]?.toString() ?? '0') ?? 0),
          DoubleCellValue(double.tryParse(row["PST"]?.toString() ?? '0') ?? 0),
          DoubleCellValue(double.tryParse(row["HST"]?.toString() ?? '0') ?? 0),
          DoubleCellValue(double.tryParse(row["Tip"]?.toString() ?? '0') ?? 0),
          DoubleCellValue(
              double.tryParse(row["Total"]?.toString() ?? '0') ?? 0),
        ]);
      }

      // Encode the file in memory
      final excelBytes = excel.encode();
      if (excelBytes == null) {
        throw Exception("Failed to encode Excel file.");
      }

      // Share the file from memory
      final xFile = XFile.fromData(
        Uint8List.fromList(excelBytes),
        name: "Receipt_Data_$timestamp.xlsx",
        mimeType:
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      );

      await Share.shareXFiles([xFile], text: 'Here is your exported file!');
    } catch (e) {
      debugPrint('Error during export or sharing: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to export or share the file.")),
        );
      }
    }
  }

  Future<void> clearHistory() async {
    await DatabaseHelper.instance.clearHistory();
    history = [];
    notifyListeners();
  }
}
