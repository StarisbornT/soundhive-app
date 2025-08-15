class ApiResponseModel {
  final bool status;
  final String message;
  final dynamic data;

  ApiResponseModel({
    required this.status,
    required this.message,
    this.data,
  });

  factory ApiResponseModel.fromJson(Map<String, dynamic> json) {
    return ApiResponseModel(
      status: json['status'] ?? false,
      message: json['message'] ?? 'Something went wrong',
      data: json['data'],
    );
  }
}
