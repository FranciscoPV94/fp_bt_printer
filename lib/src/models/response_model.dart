part of fp_bt_printer;

class PrinterResponseModel<T> {
  bool success;
  String message;
  T? model;

  PrinterResponseModel(
      {required this.success, required this.message, this.model});
}
