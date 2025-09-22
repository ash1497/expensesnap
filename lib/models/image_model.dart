import 'dart:io';

// ignore: constant_identifier_names
enum PurposeOfExpense { None, Personal, Business, Miscellaneous }

class ImageModel {
  File file;
  String? companyName;
  String? meetingInfo;
  PurposeOfExpense? purposeOfExpense;
  String? imageName;
  bool? validated;
  String? storeName;
  String? date;
  double? subtotal;
  double? gst;
  double? pst;
  double? hst;
  double? tip;
  double? total;

  ImageModel(
      {required this.file,
      this.companyName,
      this.meetingInfo,
      this.purposeOfExpense,
      this.imageName,
      this.validated,
      this.storeName,
      this.date,
      this.subtotal,
      this.gst,
      this.pst,
      this.hst,
      this.tip,
      this.total});
}
