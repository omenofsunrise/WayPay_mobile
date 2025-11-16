import 'package:waypay_mobile/features/objectType/data/models/get_object_types_query.dart';
import 'package:waypay_mobile/features/objectType/data/models/object_type_model.dart';

abstract class ObjectTypeEvent {}

class LoadObjectTypesEvent extends ObjectTypeEvent {
  final bool refresh;
  final GetObjectTypesQuery query;

  LoadObjectTypesEvent({this.refresh = false, required this.query});
}

class CreateObjectTypeEvent extends ObjectTypeEvent {
  final CreateObjectTypeRequest request;

  CreateObjectTypeEvent({required this.request});
}

class EditObjectTypeEvent extends ObjectTypeEvent {
  final ObjectTypeModel objectType;

  EditObjectTypeEvent({required this.objectType});
}

class UpdateObjectTypeEvent extends ObjectTypeEvent {
  final int objectTypeId;
  final UpdateObjectTypeRequest request;

  UpdateObjectTypeEvent({required this.objectTypeId, required this.request});
}

class DeleteObjectTypeEvent extends ObjectTypeEvent {
  final int objectTypeId;

  DeleteObjectTypeEvent(this.objectTypeId);
}

class CheckObjectTypeExistsEvent extends ObjectTypeEvent {
  final String name;
  final String entityType;

  CheckObjectTypeExistsEvent({required this.name, required this.entityType});
}
