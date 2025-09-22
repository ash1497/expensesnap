import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:receipt_application/models/image_model.dart';
import 'package:receipt_application/view_models/history_view_model.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/scheduler.dart';

class ImageViewModel extends ChangeNotifier {
  List<ImageModel> selectedImages = [];
  List<Map<String, String>> receiptDataList = [];
  List<String> processingStatuses = [];
  late IO.Socket socket;
  bool isAuthorized =
      false; // flag to allow user to upload images for processing
  bool isProcessedOnce =
      false; //flag to reset images if user uploads more images after processing once
  bool isHistorySaved =
      false; //flag to allow history to be saved upon successful processing
  String? authorizationError;
  String? confirmationToken; // To store the confirmation token for the session

  bool _isUploading =
      false; //flag to block out concurrent calls if a call has already been sent, until process is finished.

  bool get isUploading => _isUploading;

  // Update Company Name for a specific image
  void updateCompanyName(int index, String companyName) {
    selectedImages[index].companyName = companyName;
    notifyListeners();
  }

  // Update Meeting Info for a specific image
  void updateMeetingInfo(int index, String meetingInfo) {
    selectedImages[index].meetingInfo = meetingInfo;
    notifyListeners();
  }

  // Update Purpose of Expense for a specific image
  void updatePurposeOfExpense(int index, PurposeOfExpense purpose) {
    selectedImages[index].purposeOfExpense = purpose;
    notifyListeners();
  }

  // Public method to refresh listeners
  void refreshView() {
    notifyListeners();
  }

  ImageViewModel() {
    initializeSocket();
  }

  void safeNotifyListeners() {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      notifyListeners();
    }
  }

  // Initialize the WebSocket and set up event listeners
  void initializeSocket() {
    socket =
        IO.io('wss://harmless-smiling-locust.ngrok-free.app', <String, dynamic>{
      'transports': [
        'websocket'
      ], //Disabling this to ensure socket.io http fallback.
      'autoConnect': false,
      'pingInterval': 25000,
      'pingTimeout': 60000,
    });

    socket.connect();

    socket.on('connect', (_) {
      print('Connected to WebSocket');
    });

    socket.on('image_status', (data) {
      int imageIndex = data['image_index'];
      String status = data['status'];

      if (status == 'Success') {
        processingStatuses[imageIndex] = 'Success';
      } else if (status == 'Failed') {
        processingStatuses[imageIndex] = 'Failed';
        // Optionally log or display error information
        if (data.containsKey('error')) {
          print("Error for image $imageIndex: ${data['error']}");
        }
      }
      safeNotifyListeners();
    });

    socket.on('disconnect', (_) => print('Disconnected from WebSocket'));
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  void checkAuthorization() async {
    try {
      // Get Firebase ID token for the current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        authorizationError = "User not authenticated";
        safeNotifyListeners();
        return;
      }
      final idToken = await user.getIdToken();
      print("ID TOKEN: $idToken");

      // Send the authorization header to the backend
      final response = await http.post(
        Uri.parse('https://harmless-smiling-locust.ngrok-free.app/authorize'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        confirmationToken = responseBody['confirmation_token'];
        isAuthorized = true;
        authorizationError = null;
      } else {
        isAuthorized = false;
        authorizationError = "User not authorized. Please try again.";
      }
    } catch (e) {
      isAuthorized = false;
      authorizationError = "Error during authorization: $e";
    }

    safeNotifyListeners();
  }

  // Capture an image using the camera
  Future<void> captureImageWithCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      selectedImages.add(ImageModel(file: File(pickedFile.path)));
      processingStatuses.add("Pending");
      safeNotifyListeners();
    }
  }

  // Pick multiple images from the gallery
  Future<void> pickImagesFromGallery() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null) {
      if (isProcessedOnce) {
        resetImageViewModel();
      }

      for (var file in pickedFiles) {
        final fileName = file.path.split('/').last; // Extract file name

        // Check if the file name already exists in the selectedImages list
        if (!selectedImages
            .any((image) => image.file.path.split('/').last == fileName)) {
          selectedImages.add(ImageModel(file: File(file.path)));
          processingStatuses.add("Pending");
        }
      }

      processingStatuses = List.generate(
          selectedImages.length, (_) => "Processing...",
          growable: true);

      safeNotifyListeners();
    }
  }

  void updateImageAt(int index, File newImage) {
    selectedImages[index].file = newImage;
    safeNotifyListeners(); // Notify listeners to rebuild the UI
  }

  // Remove an image from the selected images list by index
  void removeImageAt(int index) {
    if (index < 0 || index >= selectedImages.length) {
      return; // Index out of bounds, do nothing
    }
    selectedImages.removeAt(index);
    processingStatuses.removeAt(index);
    // Optionally, clear receipt data if associated with the image
    if (receiptDataList.length > index) {
      receiptDataList.removeAt(index);
    }
    safeNotifyListeners();
  }

  // Upload images with progress and send them to the backend
  Future<void> uploadImagesWithProgress() async {
    if (confirmationToken == null || confirmationToken!.isEmpty) {
      authorizationError =
          "Authorization token missing. Please authorize again.";
      safeNotifyListeners();
      return;
    }

    if (_isUploading) return;

    receiptDataList.clear();
    processingStatuses = List.generate(
        selectedImages.length, (_) => "Processing...",
        growable: true);
    _isUploading = true;
    safeNotifyListeners();

    final uri =
        Uri.parse('https://harmless-smiling-locust.ngrok-free.app/upload');
    final request = http.MultipartRequest('POST', uri);

    // Add all images to the request
    for (var image in selectedImages) {
      final mimeType = _getMimeType(image.file.path);

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.file.path,
          contentType: MediaType(mimeType['type']!, mimeType['subtype']!),
        ),
      );
    }

    try {
      // Add confirmation token to Authorization header
      request.headers['Authorization'] = '$confirmationToken';
      confirmationToken = null;

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(responseData.body);
        final List<dynamic> results = jsonResponse['results'];
        for (var result in results) {
          receiptDataList.add(Map<String, String>.from(result['data']));
        }

        mapReceiptDataToImages();

        isAuthorized = false;
        _isUploading = false;
        isProcessedOnce = true;
        isHistorySaved = true;
        safeNotifyListeners();
      } else {
        print('Failed with status: ${response.statusCode}');
        print('Response: ${responseData.body}');
        processingStatuses = List.generate(
            selectedImages.length, (_) => "Failed",
            growable: true);
        safeNotifyListeners();
      }
    } catch (e, stackTrace) {
      print("Error during upload: $e");
      print("Stack trace: $stackTrace");
      processingStatuses =
          List.generate(selectedImages.length, (_) => "Failed", growable: true);
      safeNotifyListeners();
    }
  }

  Map<String, String> _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return {'type': 'image', 'subtype': 'jpeg'};
      case 'png':
        return {'type': 'image', 'subtype': 'png'};
      default:
        return {
          'type': 'application',
          'subtype': 'octet-stream'
        }; // Default fallback
    }
  }

  // Helper function to sanitize and parse values
  double sanitizeAndParse(String value) {
    final sanitizedValue =
        value.replaceAll(RegExp(r'[^0-9.]'), ''); // Remove invalid characters
    return sanitizedValue.isNotEmpty
        ? double.parse(sanitizedValue)
        : 0.0; // Parse or default to 0.0
  }

  // Helper function to parse tax based on type
  double parseTax(dynamic taxField, String taxType) {
    if (taxField is Map<String, dynamic>) {
      final value = taxField[taxType];
      if (value != null) {
        return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      }
    }
    if (taxField is String && !taxField.contains(RegExp(r'GST|PST|HST'))) {
      return taxType == "GST"
          ? double.tryParse(taxField.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0
          : 0.0;
    }
    if (taxField is String) {
      final sanitizedTaxString =
          taxField.replaceAll(RegExp(r'[^0-9.GPSTH]'), '');
      final match =
          RegExp('$taxType.*?([\\d.]+)').firstMatch(sanitizedTaxString);
      if (match != null) return double.parse(match.group(1)!);
    }
    return 0.0;
  }

  void mapReceiptDataToImages() {
    for (var receiptData in receiptDataList) {
      // Extract the index from the receipt data
      int idx = int.tryParse(receiptData['idx']?.toString() ?? '') ?? -1;

      // Ensure the index is within the bounds of selectedImages
      if (idx >= 0 && idx < selectedImages.length) {
        // Get the corresponding ImageModel instance
        ImageModel imageModel = selectedImages[idx];

        // Map the data from receiptData to imageModel
        imageModel.imageName =
            receiptData['imageName'] ?? imageModel.file.path.split('/').last;
        imageModel.validated =
            (receiptData['validated']?.toString().toLowerCase() == 'true');
        imageModel.storeName = receiptData['storeName'] ?? 'N/A';
        imageModel.date = receiptData['date'] ?? 'N/A';

        // Use sanitizeAndParse and parseTax functions to parse and assign values
        imageModel.subtotal = sanitizeAndParse(receiptData['subtotal'] ?? '0');

        var taxData = receiptData['tax'];
        if (taxData != null) {
          imageModel.gst = parseTax(taxData, 'GST');
          imageModel.pst = parseTax(taxData, 'PST');
          imageModel.hst = parseTax(taxData, 'HST');
        } else {
          // If tax data is not provided, default to zero
          imageModel.gst = 0.0;
          imageModel.pst = 0.0;
          imageModel.hst = 0.0;
        }

        imageModel.tip = sanitizeAndParse(receiptData['tip'] ?? '0');
        imageModel.total = sanitizeAndParse(receiptData['total'] ?? '0');
      } else {
        // Handle invalid index
        print(
            'Invalid idx $idx received from backend for receipt data: $receiptData');
      }
    }

    // Notify listeners to update the UI
    safeNotifyListeners();
  }

  double get totalSubtotal =>
      selectedImages.fold(0.0, (sum, image) => sum + (image.subtotal ?? 0.0));

  double get totalGST =>
      selectedImages.fold(0.0, (sum, image) => sum + (image.gst ?? 0.0));

  double get totalPST =>
      selectedImages.fold(0.0, (sum, image) => sum + (image.pst ?? 0.0));

  double get totalHST =>
      selectedImages.fold(0.0, (sum, image) => sum + (image.hst ?? 0.0));

  double get totalTip =>
      selectedImages.fold(0.0, (sum, image) => sum + (image.tip ?? 0.0));

  double get total =>
      selectedImages.fold(0.0, (sum, image) => sum + (image.total ?? 0.0));

  void updateSubtotal(int index, double subtotal) {
    selectedImages[index].subtotal = subtotal;
    notifyListeners();
  }

  void updateGST(int index, double gst) {
    selectedImages[index].gst = gst;
    notifyListeners();
  }

  void updatePST(int index, double pst) {
    selectedImages[index].pst = pst;
    notifyListeners();
  }

  void updateHST(int index, double hst) {
    selectedImages[index].hst = hst;
    notifyListeners();
  }

  void updateTip(int index, double tip) {
    selectedImages[index].tip = tip;
    notifyListeners();
  }

  void updateTotal(int index, double total) {
    selectedImages[index].total = total;
    notifyListeners();
  }

  void saveHistory(BuildContext context) {
    if (!isHistorySaved) {
      print("History saving skipped: isHistorySaved is false.");
      return;
    }

    print('Saving history at ${DateTime.now()}'); // Debug log

    final historyViewModel =
        Provider.of<HistoryViewModel>(context, listen: false);

    // Prepare the final data for history
    final List<Map<String, dynamic>> finalDataForHistory =
        selectedImages.map((image) {
      return {
        "Company Name": image.companyName ?? "N/A",
        "Meeting Info": image.meetingInfo ?? "N/A",
        "Purpose": image.purposeOfExpense?.toString().split('.').last ?? "N/A",
        "Image Name": image.imageName ?? "Unknown",
        "Store Name": image.storeName ?? "N/A",
        "Date": image.date ?? "N/A",
        "Subtotal": (image.subtotal ?? 0.0).toStringAsFixed(2),
        "GST": (image.gst ?? 0.0).toStringAsFixed(2),
        "PST": (image.pst ?? 0.0).toStringAsFixed(2),
        "HST": (image.hst ?? 0.0).toStringAsFixed(2),
        "Tip": (image.tip ?? 0.0).toStringAsFixed(2),
        "Total": (image.total ?? 0.0).toStringAsFixed(2),
      };
    }).toList();

    // Save the finalized data with a timestamp
    historyViewModel.saveDataTableToHistory(
        finalDataForHistory, selectedImages);

    // Reset the flag
    resetImageViewModel();
    print("History saved successfully with data: $finalDataForHistory");
    safeNotifyListeners();
  }

  void resetImageViewModel() {
    // Clear lists
    selectedImages = [];
    receiptDataList = [];
    processingStatuses = [];

    // Reset boolean flags
    isAuthorized = false;
    isProcessedOnce = false;
    isHistorySaved = false;

    // Reset strings or nullable variables
    authorizationError = null;
    confirmationToken = null;

    // Reset upload status
    _isUploading = false;

    // Notify listeners about the state change
    safeNotifyListeners();
  }
}
