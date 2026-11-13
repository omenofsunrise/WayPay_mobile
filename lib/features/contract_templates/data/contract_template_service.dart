import 'package:dio/dio.dart';
import 'package:waypay_mobile/features/contract_templates/data/contract_template.dart';

class ContractTemplateService {
  ContractTemplateService(this._dio);

  final Dio _dio;
  static const _path = '/contract-templates';

  Future<List<ContractTemplate>> getAll() async {
    final response = await _dio.get<List<dynamic>>(_path);
    return (response.data ?? const [])
        .map((item) => ContractTemplate.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> getVariables() async {
    final response = await _dio.get<Map<String, dynamic>>('$_path/variables');
    return ((response.data?['variables'] as List<dynamic>?) ?? const [])
        .map((item) => item.toString())
        .toList();
  }

  Future<ContractTemplate> upload({
    required String name,
    required String filePath,
  }) async {
    final fileName = filePath.split(RegExp(r'[/\\]')).last;
    final response = await _dio.post<Map<String, dynamic>>(
      _path,
      data: FormData.fromMap({
        'name': name,
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      }),
      options: Options(contentType: 'multipart/form-data'),
    );
    return ContractTemplate.fromJson(response.data!);
  }

  Future<void> delete(int id) => _dio.delete<void>('$_path/$id');

  Future<List<int>> generate(int templateId, int creditId) async {
    final response = await _dio.get<List<int>>(
      '$_path/$templateId/generate/$creditId',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? const [];
  }
}
