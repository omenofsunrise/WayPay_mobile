import 'package:waypay/features/credit/data/objectType/models/object_type_model.dart';

abstract class ObjectTypeState {}

final class ObjectTypeInitial extends ObjectTypeState {}

final class ObjectTypeLoading extends ObjectTypeState {}

final class ObjectTypeLoaded extends ObjectTypeState {
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

final class ObjectTypeError extends ObjectTypeState {
  final String message;

  ObjectTypeError(this.message);
}

final class ObjectTypeCreated extends ObjectTypeState {
  final ObjectTypeModel objectType;

  ObjectTypeCreated(this.objectType);
}

final class ObjectTypeUpdated extends ObjectTypeState {
  final ObjectTypeModel objectType;

  ObjectTypeUpdated(this.objectType);
}

final class ObjectTypeDeleted extends ObjectTypeState {
  final int objectTypeId;

  ObjectTypeDeleted(this.objectTypeId);
}
