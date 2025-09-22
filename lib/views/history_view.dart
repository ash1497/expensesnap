import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../view_models/history_view_model.dart';

class HistoryView extends StatelessWidget {
  // ignore: use_super_parameters
  const HistoryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final historyViewModel = Provider.of<HistoryViewModel>(context);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 177, 199, 176),
      appBar: AppBar(
        title: Text(
          'ExpenseSnap',
          style: GoogleFonts.robotoSerif(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        backgroundColor: const Color.fromARGB(255, 177, 199, 176),
        foregroundColor: Colors.black,
      ),
      body: historyViewModel.history.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...historyViewModel.history.map((entry) {
                      final timestamp = entry['timestamp'];
                      final data =
                          entry['data'] as List<Map<String, dynamic>>? ?? [];

                      // Skip rendering if the data list is empty
                      if (data.isEmpty) return const SizedBox.shrink();

                      // Sort the data by "Date" in ascending order
                      data.sort((a, b) =>
                          (a['Date'] ?? "").compareTo(b['Date'] ?? ""));

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: _buildHistoryCard(context, timestamp, data),
                      );
                      // ignore: unnecessary_to_list_in_spreads
                    }).toList(),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _clearHistory(context, historyViewModel),
                        icon: const Icon(Icons.delete),
                        label: const Text("Clear History"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 60, color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            "No history found.",
            style: GoogleFonts.roboto(
              fontSize: 18,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // Build a single history card with a DataTable
  Widget _buildHistoryCard(
      BuildContext context, String timestamp, List<Map<String, dynamic>> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Date/Time: $timestamp",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Export Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                // Access _exportToExcel from the HistoryViewModel
                final historyViewModel =
                    Provider.of<HistoryViewModel>(context, listen: false);
                historyViewModel.exportToExcel(context, timestamp, data);
              },
              icon: const Icon(Icons.download),
              label: const Text("Export"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Consistent with HomeView
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              columns: const [
                DataColumn(
                  label: Row(
                    children: [
                      Icon(Icons.business, size: 16),
                      SizedBox(width: 5),
                      Text("Company Name"),
                    ],
                  ),
                ),
                DataColumn(
                  label: Row(
                    children: [
                      Icon(Icons.info, size: 16),
                      SizedBox(width: 5),
                      Text("Meeting Info"),
                    ],
                  ),
                ),
                DataColumn(
                  label: Row(
                    children: [
                      Icon(Icons.assignment, size: 16),
                      SizedBox(width: 5),
                      Text("Purpose"),
                    ],
                  ),
                ),
                DataColumn(
                  label: Row(
                    children: [
                      Icon(Icons.image, size: 16),
                      SizedBox(width: 5),
                      Text("Image Name"),
                    ],
                  ),
                ),
                DataColumn(
                  label: Row(
                    children: [
                      Icon(Icons.store, size: 16),
                      SizedBox(width: 5),
                      Text("Store Name"),
                    ],
                  ),
                ),
                DataColumn(
                  label: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16),
                      SizedBox(width: 5),
                      Text("Date"),
                    ],
                  ),
                ),
                DataColumn(
                  label: Row(
                    children: [
                      Icon(Icons.attach_money, size: 16),
                      SizedBox(width: 5),
                      Text("Subtotal"),
                    ],
                  ),
                ),
                DataColumn(
                  label: Row(
                    children: [
                      Icon(Icons.attach_money, size: 16),
                      SizedBox(width: 5),
                      Text("GST"),
                    ],
                  ),
                ),
                DataColumn(
                  label: Row(
                    children: [
                      Icon(Icons.attach_money, size: 16),
                      SizedBox(width: 5),
                      Text("PST"),
                    ],
                  ),
                ),
                DataColumn(
                  label: Row(
                    children: [
                      Icon(Icons.attach_money, size: 16),
                      SizedBox(width: 5),
                      Text("HST"),
                    ],
                  ),
                ),
                DataColumn(
                  label: Row(
                    children: [
                      Icon(Icons.monetization_on, size: 16),
                      SizedBox(width: 5),
                      Text("Tip"),
                    ],
                  ),
                ),
                DataColumn(
                  label: Row(
                    children: [
                      Icon(Icons.calculate, size: 16),
                      SizedBox(width: 5),
                      Text("Total"),
                    ],
                  ),
                ),
              ],
              rows: data.map((row) {
                return DataRow(
                  cells: [
                    DataCell(Text(row["Company Name"] ?? "N/A")),
                    DataCell(Text(row["Meeting Info"] ?? "N/A")),
                    DataCell(Text(row["Purpose"] ?? "N/A")),
                    DataCell(Text(row["Image Name"] ?? "Unknown")),
                    DataCell(Text(row["Store Name"] ?? "N/A")),
                    DataCell(Text(row["Date"] ?? "N/A")),
                    DataCell(Text(row["Subtotal"].toStringAsFixed(2))),
                    DataCell(Text(row["GST"].toStringAsFixed(2))),
                    DataCell(Text(row["PST"].toStringAsFixed(2))),
                    DataCell(Text(row["HST"].toStringAsFixed(2))),
                    DataCell(Text(row["Tip"].toStringAsFixed(2))),
                    DataCell(Text(row["Total"].toStringAsFixed(2))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Clear history logic
  void _clearHistory(BuildContext context, HistoryViewModel historyViewModel) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Clear History"),
          content: const Text(
              "Are you sure you want to clear all history? This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                historyViewModel.clearHistory();
                Navigator.of(context).pop();
              },
              child: const Text("Clear", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
