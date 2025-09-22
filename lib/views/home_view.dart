import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:receipt_application/models/image_model.dart';
import 'package:receipt_application/view_models/image_view_model.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';

// ignore: use_key_in_widget_constructors
class HomeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ImageViewModel>(context);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 177, 199, 176),
      appBar: AppBar(
        title: Text(
          'ExpenseSnap',
          style: GoogleFonts.robotoSerif(
              fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: const Color.fromARGB(255, 177, 199, 176),
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (viewModel.selectedImages.isEmpty) ...[
                _buildEmptyState(),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showActionsSheet(context, viewModel);
                    },
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text("Add Images"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color.fromARGB(255, 11, 61, 68),
                      minimumSize: const Size(200, 50), // Larger size
                      textStyle: const TextStyle(
                        fontSize: 18, // Larger text
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              if (viewModel.selectedImages.isNotEmpty) ...[
                _buildImageGrid(context, viewModel),
                const SizedBox(height: 20),
                _buildSubmitButton(context, viewModel),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showActionsSheet(context, viewModel);
                    },
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text("Add Images"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color.fromARGB(255, 11, 61, 68),
                      minimumSize: const Size(250, 40), // Larger size
                      textStyle: const TextStyle(
                        fontSize: 16, // Larger text
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                StatefulBuilder(
                  builder: (context, StateSetter setState) {
                    if (viewModel.isProcessedOnce) {
                      return _buildBottomListView(context, viewModel, setState);
                    } else {
                      return Center(
                        child: Container(
                          width: 300, // Width of the box
                          height: 300, // Height of the box
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 177, 199,
                                176), // Background color for the box
                            borderRadius:
                                BorderRadius.circular(16), // Rounded corners
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(0.1), // Shadow color
                                blurRadius: 8,
                                offset: const Offset(0, 4), // Shadow offset
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Lottie.asset(
                              'assets/animations/emptybox.json',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    }
                  },
                )
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset(
          'assets/animations/empty_state.json',
          width: 200,
          height: 200,
        ),
        const SizedBox(height: 20),
        Text(
          "No images uploaded yet. Start by adding your receipts!",
          style: GoogleFonts.roboto(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildImageGrid(BuildContext context, ImageViewModel viewModel) {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: viewModel.selectedImages.length,
      itemBuilder: (context, index) {
        final image = viewModel.selectedImages[index];
        return Stack(
          children: [
            GestureDetector(
              onTap: () => _showEnlargedImage(context, viewModel, index),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(image.file, fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _confirmDelete(context, viewModel, index),
                child: const Icon(
                  Icons.delete_forever,
                  color: Colors.red,
                  size: 24,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubmitButton(BuildContext context, ImageViewModel viewModel) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () {
          if (viewModel.selectedImages.isEmpty) {
            Fluttertoast.showToast(
              msg: "No images to upload!",
              toastLength: Toast.LENGTH_SHORT,
            );
            return;
          }
          if (!viewModel.isAuthorized ||
              viewModel.isUploading ||
              viewModel.confirmationToken != null) {
            _showAuthorizationDialog(context, viewModel);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color.fromARGB(255, 11, 61, 68),
          textStyle: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text("Submit Images"),
      ),
    );
  }

  Widget _buildReceiptTable(BuildContext context, ImageViewModel viewModel) {
    final totalSubtotal = viewModel.totalSubtotal;
    final totalGST = viewModel.totalGST;
    final totalPST = viewModel.totalPST;
    final totalHST = viewModel.totalHST;
    final totalTip = viewModel.totalTip;
    final total = viewModel.total;

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
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          columns: const [
            DataColumn(
              label: Row(children: [
                Icon(Icons.image, size: 16),
                SizedBox(width: 4),
                Text("Image Name")
              ]),
            ),
            DataColumn(
              label: Row(children: [
                Icon(Icons.store, size: 16),
                SizedBox(width: 4),
                Text("Store Name")
              ]),
            ),
            DataColumn(
              label: Row(children: [
                Icon(Icons.date_range, size: 16),
                SizedBox(width: 4),
                Text("Date")
              ]),
            ),
            DataColumn(label: Text("Subtotal")),
            DataColumn(label: Text("GST")),
            DataColumn(label: Text("PST")),
            DataColumn(label: Text("HST")),
            DataColumn(label: Text("Tip")),
            DataColumn(label: Text("Total")),
          ],
          rows: [
            ...viewModel.selectedImages.asMap().entries.map((entry) {
              final index = entry.key;
              final imageModel = entry.value;

              return DataRow(
                color: WidgetStateProperty.resolveWith<Color?>((states) {
                  return index.isEven ? Colors.grey.withOpacity(0.1) : null;
                }),
                cells: [
                  DataCell(Text(imageModel.imageName ?? "Unknown")),
                  DataCell(Text(imageModel.storeName ?? "N/A")),
                  DataCell(Text(imageModel.date ?? "N/A")),
                  DataCell(
                      Text((imageModel.subtotal ?? 0.0).toStringAsFixed(2))),
                  DataCell(Text((imageModel.gst ?? 0.0).toStringAsFixed(2))),
                  DataCell(Text((imageModel.pst ?? 0.0).toStringAsFixed(2))),
                  DataCell(Text((imageModel.hst ?? 0.0).toStringAsFixed(2))),
                  DataCell(Text((imageModel.tip ?? 0.0).toStringAsFixed(2))),
                  DataCell(Text((imageModel.total ?? 0.0).toStringAsFixed(2))),
                ],
              );
            }),
            DataRow(
              cells: [
                const DataCell(Text("Total",
                    style: TextStyle(fontWeight: FontWeight.bold))),
                const DataCell(Text("")),
                const DataCell(Text("")),
                DataCell(Text(totalSubtotal.toStringAsFixed(2))),
                DataCell(Text(totalGST.toStringAsFixed(2))),
                DataCell(Text(totalPST.toStringAsFixed(2))),
                DataCell(Text(totalHST.toStringAsFixed(2))),
                DataCell(Text(totalTip.toStringAsFixed(2))),
                DataCell(Text(total.toStringAsFixed(2))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showActionsSheet(BuildContext context, ImageViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 177, 199, 176),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStyledButton(
                context,
                label: "Select Images from Gallery",
                icon: Icons.photo_library,
                onPressed: viewModel.pickImagesFromGallery,
              ),
              const SizedBox(height: 10),
              _buildStyledButton(
                context,
                label: "Capture Image with Camera",
                icon: Icons.camera_alt,
                onPressed: viewModel.captureImageWithCamera,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStyledButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.of(context).pop();
        onPressed();
      },
      icon: Icon(icon, color: const Color.fromARGB(255, 11, 61, 68)),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color.fromARGB(255, 11, 61, 68),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showAuthorizationDialog(
      BuildContext context, ImageViewModel viewModel) {
    // Trigger the backend call when the dialog is shown
    viewModel.checkAuthorization();

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal until status is resolved
      builder: (context) {
        return Consumer<ImageViewModel>(
          builder: (context, updatedViewModel, _) {
            // Check if the user is authorized
            if (updatedViewModel.isAuthorized) {
              if (context.mounted) Navigator.of(context).pop();
              viewModel.uploadImagesWithProgress();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  _showProgressDialog(context, viewModel);
                }
              });
            }

            // Determine the animation to show
            String animationPath;
            if (updatedViewModel.authorizationError != null) {
              animationPath = 'assets/animations/error.json';
            } else if (!updatedViewModel.isAuthorized) {
              animationPath = 'assets/animations/loader.json';
            } else {
              animationPath = 'assets/animations/success.json';
            }

            return AlertDialog(
              backgroundColor: const Color.fromARGB(255, 213, 224, 213),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.white, width: 2),
              ),
              title: const Text("Authorization"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(animationPath, height: 100),
                  const SizedBox(height: 20),
                  if (updatedViewModel.authorizationError != null)
                    Text(
                      updatedViewModel.authorizationError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                ],
              ),
              actions: updatedViewModel.isAuthorized
                  ? [] // No actions if authorized (auto-close)
                  : [
                      if (updatedViewModel.authorizationError != null)
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          child: const Text("Close"),
                        ),
                    ],
            );
          },
        );
      },
    );
  }

  void _showProgressDialog(BuildContext context, ImageViewModel viewModel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        AnimationController? progressController;
        AnimationController? syncController;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            // Initialize progressController if null
            progressController ??= AnimationController(
              vsync: Navigator.of(context),
              duration: const Duration(milliseconds: 500),
            );

            // Initialize syncController if null
            syncController ??= AnimationController(
              vsync: Navigator.of(context),
              duration:
                  const Duration(seconds: 1), // Duration for checkmark.json
            );

            return Consumer<ImageViewModel>(
              builder: (context, updatedViewModel, _) {
                // Calculate overall progress percentage
                int totalImages = updatedViewModel.selectedImages.length;
                int processedImages = updatedViewModel.processingStatuses
                    .where(
                        (status) => status == "Success" || status == "Failed")
                    .length;
                double progressPercentage =
                    totalImages > 0 ? (processedImages / totalImages) : 0;

                // Update the progress animation
                progressController?.animateTo(progressPercentage);

                // Determine the overall animation to show
                String overallAnimationPath = processedImages == totalImages
                    ? 'assets/animations/success.json'
                    : 'assets/animations/loader.json';

                // Start the syncController when the first success occurs
                bool firstSuccessDetected =
                    updatedViewModel.processingStatuses.contains("Success");
                if (firstSuccessDetected && !syncController!.isAnimating) {
                  syncController?.forward();
                }

                return AlertDialog(
                  backgroundColor: const Color.fromARGB(
                      255, 213, 224, 213), // Light green background
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                    side: const BorderSide(
                        color: Colors.white, width: 2), // Thick white border
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Processing Images"),
                      Center(
                        child: SizedBox(
                          height: 100,
                          width: 100,
                          child: Lottie.asset(
                            overallAnimationPath,
                            repeat: processedImages != totalImages,
                          ),
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          height: 100, // Enlarged progress bar height
                          width: 400, // Enlarged progress bar width
                          child: Lottie.asset(
                            'assets/animations/progressbar.json',
                            controller: progressController,
                          ),
                        ),
                      ),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(totalImages, (index) {
                        String status =
                            updatedViewModel.processingStatuses[index];
                        String animationPath = status == "Success"
                            ? 'assets/animations/checkmark.json'
                            : status == "Failed"
                                ? 'assets/animations/error.json'
                                : 'assets/animations/spinner.json';

                        return ListTile(
                          leading: SizedBox(
                            height: 50, // Uniform size for all icons
                            width: 50,
                            child: Lottie.asset(
                              animationPath,
                              repeat: status !=
                                  "Success", // Spinner keeps animating
                              controller: status == "Success"
                                  ? syncController // Sync with the first success
                                  : null,
                              animate: true,
                            ),
                          ),
                          title: Text(
                            updatedViewModel.selectedImages[index].file.path
                                .split('/')
                                .last,
                          ),
                          subtitle: Text(
                            status,
                            style: TextStyle(
                              color: status == "Success"
                                  ? Colors.green
                                  : status == "Failed"
                                      ? Colors.red
                                      : Colors.orange,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  actions: [
                    if (processedImages == totalImages)
                      TextButton(
                        onPressed: () {
                          progressController?.dispose();
                          syncController?.dispose();
                          Navigator.of(context).pop(); // Close the dialog
                        },
                        child: const Text("Close"),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, ImageViewModel viewModel, int index,
      {VoidCallback? onDelete}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              const Color.fromARGB(255, 177, 199, 176), // Theme color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0), // Rounded corners
          ),
          title: const Text(
            "Confirm Deletion",
            style: TextStyle(
              fontWeight: FontWeight.bold, // Bold the title
              fontSize: 18,
              color: Colors.black, // Black text for the title
            ),
          ),
          content: const Text(
            "Are you sure you want to delete this image?",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black, // Black text for the content
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.black, // Black text for Cancel button
                  fontWeight: FontWeight.bold, // Bold text
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                viewModel.removeImageAt(index);

                // Perform additional actions after deletion
                if (onDelete != null) {
                  onDelete();
                }

                Fluttertoast.showToast(
                  msg: "Image deleted successfully!",
                  toastLength: Toast.LENGTH_SHORT,
                );

                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                "Delete",
                style: TextStyle(
                  color: Colors.black, // Black text for Delete button
                  fontWeight: FontWeight.bold, // Bold text
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cropImage(
      BuildContext context, ImageViewModel viewModel, int index) async {
    final originalFile = viewModel.selectedImages[index].file;

    // Launch the image cropper
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: originalFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: const Color.fromARGB(255, 177, 199, 176),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: Colors.green,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Image',
          rotateButtonsHidden: false,
          aspectRatioLockEnabled: false,
        ),
      ],
    );

    if (croppedFile != null) {
      // Update the image in the view model
      viewModel.updateImageAt(index, File(croppedFile.path));

      // Notify the user
      Fluttertoast.showToast(msg: "Image cropped successfully!");
    } else {
      // User canceled cropping
      Fluttertoast.showToast(msg: "Cropping canceled.");
    }
  }

  Future<void> showImageDetails(BuildContext context, int index,
      ImageViewModel viewModel, StateSetter parentSetState) async {
    final image = viewModel.selectedImages[index];

    // Persistent controllers initialized only once per modal instance
    final TextEditingController companyNameController =
        TextEditingController(text: image.companyName ?? '');
    final TextEditingController meetingInfoController =
        TextEditingController(text: image.meetingInfo ?? '');

    // Persistent dropdown state for purposeOfExpense
    PurposeOfExpense purpose = image.purposeOfExpense ?? PurposeOfExpense.None;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color.fromARGB(255, 177, 199, 176),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (context) {
        // Use StatefulBuilder to manage modal-specific state for dropdown
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Company Name',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      controller: companyNameController,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Meeting Info',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLines: 3,
                      controller: meetingInfoController,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<PurposeOfExpense>(
                      value: purpose,
                      dropdownColor: const Color.fromARGB(255, 177, 199, 176),
                      items: PurposeOfExpense.values
                          .map((PurposeOfExpense purpose) {
                        return DropdownMenuItem<PurposeOfExpense>(
                          value: purpose,
                          child: Text(purpose.toString().split('.').last),
                        );
                      }).toList(),
                      onChanged: (PurposeOfExpense? value) {
                        if (value != null) {
                          setState(() {
                            purpose = value;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Purpose of Expense',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Save data back to the ImageModel
                        viewModel.updateCompanyName(
                            index, companyNameController.text);
                        viewModel.updateMeetingInfo(
                            index, meetingInfoController.text);
                        viewModel.updatePurposeOfExpense(index, purpose);
                        // Trigger immediate rebuild for parent info tab
                        parentSetState(() {});
                        Navigator.of(context).pop();
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEnlargedImage(
      BuildContext context, ImageViewModel viewModel, int initialIndex) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) {
        final PageController pageController =
            PageController(initialPage: initialIndex);
        ValueNotifier<int> currentIndexNotifier =
            ValueNotifier<int>(initialIndex);

        return StatefulBuilder(
          builder: (context, StateSetter setState) {
            return Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: const Color.fromARGB(255, 177, 199, 176),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.crop, color: Colors.white),
                    onPressed: () async {
                      await _cropImage(
                          context, viewModel, currentIndexNotifier.value);
                      if (context.mounted) Navigator.of(context).pop();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          _showEnlargedImage(
                              context, viewModel, currentIndexNotifier.value);
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _confirmDelete(
                        context,
                        viewModel,
                        currentIndexNotifier.value,
                        onDelete: () {
                          setState(() {
                            // Adjust index after deletion
                            if (viewModel.selectedImages.isNotEmpty) {
                              // If deleting the last image, move to the previous one
                              if (currentIndexNotifier.value >=
                                  viewModel.selectedImages.length) {
                                currentIndexNotifier.value =
                                    viewModel.selectedImages.length - 1;
                              }
                            } else {
                              // Close the enlarged view if no images remain
                              Navigator.of(context).pop();
                            }
                          });
                        },
                      );
                    },
                  ),
                ],
              ),
              body: Column(
                children: [
                  Expanded(
                    child: PhotoViewGallery.builder(
                      itemCount: viewModel.selectedImages.length,
                      builder: (context, index) {
                        final image = viewModel.selectedImages[index];
                        return PhotoViewGalleryPageOptions(
                          imageProvider: FileImage(image.file),
                          initialScale: PhotoViewComputedScale.contained,
                          minScale: PhotoViewComputedScale.contained * 0.8,
                          maxScale: PhotoViewComputedScale.covered * 2,
                        );
                      },
                      pageController: pageController,
                      onPageChanged: (index) {
                        currentIndexNotifier.value = index;
                        setState(() {}); // Rebuild info tab on scroll
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ));
  }

  void _showListEnlargedImage(
      BuildContext context, ImageViewModel viewModel, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          final PageController pageController =
              PageController(initialPage: initialIndex);
          ValueNotifier<int> currentIndexNotifier =
              ValueNotifier<int>(initialIndex);
          ValueNotifier<bool> isEditingNotifier =
              ValueNotifier<bool>(false); // Tracks editing state

          return StatefulBuilder(
            builder: (context, StateSetter setState) {
              return Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  backgroundColor: const Color.fromARGB(255, 177, 199, 176),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _confirmDelete(
                          context,
                          viewModel,
                          currentIndexNotifier.value,
                          onDelete: () {
                            setState(() {
                              if (viewModel.selectedImages.isNotEmpty) {
                                if (currentIndexNotifier.value >=
                                    viewModel.selectedImages.length) {
                                  currentIndexNotifier.value =
                                      viewModel.selectedImages.length - 1;
                                }
                              } else {
                                Navigator.of(context).pop();
                              }
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
                body: Column(
                  children: [
                    // Photo Viewer
                    Expanded(
                      child: PhotoViewGallery.builder(
                        itemCount: viewModel.selectedImages.length,
                        builder: (context, index) {
                          final image = viewModel.selectedImages[index];
                          return PhotoViewGalleryPageOptions(
                            imageProvider: FileImage(image.file),
                            initialScale: PhotoViewComputedScale.contained,
                            minScale: PhotoViewComputedScale.contained * 0.8,
                            maxScale: PhotoViewComputedScale.covered * 2,
                          );
                        },
                        pageController: pageController,
                        onPageChanged: (index) {
                          currentIndexNotifier.value = index;
                          isEditingNotifier.value =
                              false; // Reset editing mode on page change
                          setState(() {}); // Rebuild UI on page change
                        },
                      ),
                    ),
                    // Bottom Section: Editable Fields
                    ValueListenableBuilder<int>(
                      valueListenable: currentIndexNotifier,
                      builder: (context, currentIndex, _) {
                        final imageModel =
                            viewModel.selectedImages[currentIndex];
                        return ValueListenableBuilder<bool>(
                          valueListenable: isEditingNotifier,
                          builder: (context, isEditing, _) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(255, 216, 230, 216),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // "Details" Row with Edit/Save Button
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Details",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          if (isEditing) {
                                            // Save changes and exit edit mode
                                            _saveChanges(
                                                viewModel, currentIndex);
                                            isEditingNotifier.value =
                                                false; // Switch to read-only
                                          } else {
                                            // Enable edit mode
                                            isEditingNotifier.value = true;
                                          }
                                        },
                                        icon: Icon(isEditing
                                            ? Icons.check
                                            : Icons.edit),
                                        label:
                                            Text(isEditing ? "Save" : "Edit"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isEditing
                                              ? Colors.green
                                              : Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Monetary Fields
                                  _buildMonetaryFields(imageModel, viewModel,
                                      currentIndex, isEditing, context),
                                  const SizedBox(height: 16),
                                  // Additional Fields
                                  _buildAdditionalFields(imageModel, viewModel,
                                      currentIndex, isEditing),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMonetaryFields(ImageModel imageModel, ImageViewModel viewModel,
      int index, bool isEditing, BuildContext context) {
    final data = {
      "Subtotal": imageModel.subtotal,
      "GST": imageModel.gst,
      "PST": imageModel.pst,
      "HST": imageModel.hst,
      "Tip": imageModel.tip,
      "Total": imageModel.total,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: data.entries.map((entry) {
          final label = entry.key;
          final value = entry.value;

          if (isEditing) {
            final controller =
                TextEditingController(text: value?.toString() ?? '');
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SizedBox(
                width: 120, // Fixed width for each field
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(labelText: label),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (newValue) {
                    final double parsedValue = double.tryParse(newValue) ?? 0.0;
                    switch (label) {
                      case "Subtotal":
                        viewModel.updateSubtotal(index, parsedValue);
                        break;
                      case "GST":
                        viewModel.updateGST(index, parsedValue);
                        break;
                      case "PST":
                        viewModel.updatePST(index, parsedValue);
                        break;
                      case "HST":
                        viewModel.updateHST(index, parsedValue);
                        break;
                      case "Tip":
                        viewModel.updateTip(index, parsedValue);
                        break;
                      case "Total":
                        viewModel.updateTotal(index, parsedValue);
                        break;
                    }
                  },
                ),
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(value?.toStringAsFixed(2) ?? "N/A"),
                ],
              ),
            );
          }
        }).toList(),
      ),
    );
  }

  Widget _buildAdditionalFields(ImageModel imageModel, ImageViewModel viewModel,
      int index, bool isEditing) {
    if (isEditing) {
      final companyNameController =
          TextEditingController(text: imageModel.companyName ?? '');
      final meetingInfoController =
          TextEditingController(text: imageModel.meetingInfo ?? '');
      PurposeOfExpense purpose =
          imageModel.purposeOfExpense ?? PurposeOfExpense.None;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: companyNameController,
            decoration: const InputDecoration(labelText: 'Company Name'),
            onChanged: (value) {
              viewModel.updateCompanyName(index, value);
            },
          ),
          TextField(
            controller: meetingInfoController,
            decoration: const InputDecoration(labelText: 'Meeting Info'),
            maxLines: 3,
            onChanged: (value) {
              viewModel.updateMeetingInfo(index, value);
            },
          ),
          DropdownButtonFormField<PurposeOfExpense>(
            value: purpose,
            items: PurposeOfExpense.values.map((purpose) {
              return DropdownMenuItem<PurposeOfExpense>(
                value: purpose,
                child: Text(purpose.toString().split('.').last),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                viewModel.updatePurposeOfExpense(index, value);
              }
            },
            decoration: const InputDecoration(labelText: 'Purpose of Expense'),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReadOnlyField("Company Name", imageModel.companyName),
          _buildReadOnlyField("Meeting Info", imageModel.meetingInfo),
          _buildReadOnlyField(
            "Purpose",
            imageModel.purposeOfExpense?.toString().split('.').last,
          ),
        ],
      );
    }
  }

  Widget _buildReadOnlyField(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? "N/A",
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  void _saveChanges(ImageViewModel viewModel, int index) {
    // Implement saving logic here, if additional actions are needed
    debugPrint("Changes saved for image at index $index.");
  }

  Widget _buildBottomListView(
      BuildContext context, ImageViewModel viewModel, StateSetter setState) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              vertical: 8.0), // Uniform padding of 16 pixels
          child: _buildReceiptTable(
              context, viewModel), // The widget inside the padding
        ),

        // ListView for displaying images and details
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: viewModel.selectedImages.length,
          itemBuilder: (context, index) {
            final imageModel = viewModel.selectedImages[index];
            final isValid = imageModel.validated ?? false;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row with Image Thumbnail and Key Details
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Thumbnail with Validation Outline
                        GestureDetector(
                          onTap: () =>
                              _showListEnlargedImage(context, viewModel, index),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isValid ? Colors.green : Colors.red,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                imageModel.file,
                                width: 100,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Key Details in Table Format
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Image Name: ${imageModel.imageName ?? "Unknown"}",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                "Store Name: ${imageModel.storeName ?? "N/A"}",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                "Date: ${imageModel.date ?? "N/A"}",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              // Table for Numerical Data
                              Table(
                                columnWidths: const {
                                  0: IntrinsicColumnWidth(),
                                  1: FlexColumnWidth(),
                                },
                                children: [
                                  _buildTableRow(
                                      "Subtotal", imageModel.subtotal),
                                  _buildTableRow("GST", imageModel.gst),
                                  _buildTableRow("PST", imageModel.pst),
                                  _buildTableRow("HST", imageModel.hst),
                                  _buildTableRow("Tip", imageModel.tip),
                                  _buildTableRow(
                                    "Total",
                                    imageModel.total,
                                    highlight: true,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Additional Information Section
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAdditionalInfoRow(Icons.business,
                              "Company Name", imageModel.companyName),
                          _buildAdditionalInfoRow(Icons.meeting_room,
                              "Meeting Info", imageModel.meetingInfo),
                          _buildAdditionalInfoRow(
                            Icons.question_mark_rounded,
                            "Purpose",
                            imageModel.purposeOfExpense
                                ?.toString()
                                .split('.')
                                .last,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // Save All Data Button
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                viewModel.saveHistory(context); // Call the saveHistory function
              });
            },
            icon: const Icon(Icons.save),
            label: const Text("Save All Data"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color.fromARGB(255, 11, 61, 68),
              minimumSize: const Size(200, 50), // Larger size
              textStyle: const TextStyle(
                fontSize: 18, // Larger text
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  TableRow _buildTableRow(String label, double? value,
      {bool highlight = false}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? Colors.blue : Colors.black,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            value != null ? value.toStringAsFixed(2) : 'N/A',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? Colors.blue : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value ?? "N/A",
              style: const TextStyle(color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
