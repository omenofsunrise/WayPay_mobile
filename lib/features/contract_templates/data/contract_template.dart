class ContractTemplate {
  const ContractTemplate({
    required this.id,
    required this.name,
    required this.fileName,
  });

  final int id;
  final String name;
  final String fileName;

  factory ContractTemplate.fromJson(Map<String, dynamic> json) {
    return ContractTemplate(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
    );
  }
}
