class AddMoneyModel {
  final bool success;
  final String message;
  final String? url;

  AddMoneyModel({
    required this.success,
    required this.message,
    this.url,
  });

  factory AddMoneyModel.fromJson(Map<String, dynamic> json) {
    return AddMoneyModel(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Something went wrong',
      url: json['url']  ?? '',
    );
  }
}