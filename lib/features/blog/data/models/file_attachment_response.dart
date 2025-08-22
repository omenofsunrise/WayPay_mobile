class FileAttachmentResponse {
  final String? url;
  final String? name;
  final int size;

  FileAttachmentResponse({this.url, this.name, required this.size});

  factory FileAttachmentResponse.fromJson(Map<String, dynamic> json) {
    return FileAttachmentResponse(
      url: json['url'] as String?,
      name: json['name'] as String?,
      size: json['size'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'url': url, 'name': name, 'size': size};
  }
}
