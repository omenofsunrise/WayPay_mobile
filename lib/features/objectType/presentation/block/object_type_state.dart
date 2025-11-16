import 'package:waypay_mobile/features/objectType/data/models/object_type_model.dart';

abstract class ObjectTypeState {}

class ObjectTypeInitial extends ObjectTypeState {}

class ObjectTypeLoading extends ObjectTypeState {}

class ObjectTypeLoaded extends ObjectTypeState {
  final List<ObjectTypeModel> objectTypes;
  final bool hasMoreData;
  final int currentPage;
  final int totalPages;
  final int totalCount;

  ObjectTypeLoaded({
    required this.objectTypes,
    required this.hasMoreData,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
  });

  ObjectTypeLoaded copyWith({
    List<ObjectTypeModel>? objectTypes,
    bool? hasMoreData,
    int? currentPage,
    int? totalPages,
    int? totalCount,
  }) {
    return ObjectTypeLoaded(
      objectTypes: objectTypes ?? this.objectTypes,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class ObjectTypeError extends ObjectTypeState {
  final String message;

  ObjectTypeError(this.message);
}

// УБИРАЕМ ObjectTypeCreated, ObjectTypeUpdated, ObjectTypeDeleted
// так как они вызывают проблемы с кастингом

class ObjectTypeEditing extends ObjectTypeState {
  final ObjectTypeModel objectType;

  ObjectTypeEditing(this.objectType);
}
