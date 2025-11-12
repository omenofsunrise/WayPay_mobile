import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/features/credit/data/objectType/data_source/object_type_remote_data_source.dart';
import 'package:waypay/features/credit/data/objectType/models/get_object_types_query.dart';
import 'package:waypay/features/credit/data/objectType/models/object_type_model.dart';
import 'object_type_event.dart';
import 'object_type_state.dart';

class ObjectTypeBloc extends Bloc<ObjectTypeEvent, ObjectTypeState> {
  final ObjectTypeRemoteDataSource _dataSource =
      getIt<ObjectTypeRemoteDataSource>();

  List<ObjectTypeModel> _objectTypes = [];
  int _currentPage = 1;
  bool _hasMore = true;

  GetObjectTypesQuery _lastQuery = GetObjectTypesQuery();
  GetObjectTypesQuery get lastQuery => _lastQuery;

  ObjectTypeBloc() : super(ObjectTypeInitial()) {
    on<LoadObjectTypesEvent>(_onLoadObjectTypes);
    on<CreateObjectTypeEvent>(_onCreateObjectType);
    on<UpdateObjectTypeEvent>(_onUpdateObjectType);
    on<DeleteObjectTypeEvent>(_onDeleteObjectType);
    on<CheckObjectTypeExistsEvent>(_onCheckObjectTypeExists);
  }

  Future<void> _onLoadObjectTypes(
    LoadObjectTypesEvent event,
    Emitter<ObjectTypeState> emit,
  ) async {
    if (event.refresh) {
      _currentPage = event.query.page ?? 1;
      _hasMore = true;
      _objectTypes.clear();
      emit(ObjectTypeLoading());
    } else if (!_hasMore) {
      return;
    } else {
      _currentPage = event.query.page ?? _currentPage;
    }

    try {
      final query = event.query.copyWith(page: _currentPage);
      _lastQuery = query;
      final response = await _dataSource.getObjectTypes(query);

      if (event.refresh) {
        _objectTypes = response.items;
      } else {
        _objectTypes.addAll(response.items);
      }

      final totalPages = response.totalPages;
      _hasMore = _currentPage < totalPages;

      emit(
        ObjectTypeLoaded(
          objectTypes: List.from(_objectTypes),
          hasMoreData: _hasMore,
          currentPage: _currentPage,
          totalPages: totalPages,
          totalCount: response.totalCount,
        ),
      );
    } catch (e) {
      emit(ObjectTypeError('Ошибка при загрузке типов объектов: $e'));
    }
  }

  Future<void> _onCreateObjectType(
    CreateObjectTypeEvent event,
    Emitter<ObjectTypeState> emit,
  ) async {
    try {
      final createdObjectType = await _dataSource.createObjectType(
        event.request,
      );

      // Добавляем новый тип в список
      _objectTypes.insert(0, createdObjectType);

      // Обновляем состояние если текущее состояние - loaded
      if (state is ObjectTypeLoaded) {
        final currentState = state as ObjectTypeLoaded;
        emit(
          currentState.copyWith(
            objectTypes: List.from(_objectTypes),
            totalCount: currentState.totalCount + 1,
          ),
        );
      }

      emit(ObjectTypeCreated(createdObjectType));

      // Возвращаемся к предыдущему состоянию после успешного создания
      if (state is ObjectTypeCreated) {
        final currentState = state as ObjectTypeLoaded?;
        if (currentState != null) {
          emit(currentState);
        } else {
          emit(ObjectTypeInitial());
        }
      }
    } catch (e) {
      emit(ObjectTypeError('Ошибка при создании типа объекта: $e'));
    }
  }

  Future<void> _onUpdateObjectType(
    UpdateObjectTypeEvent event,
    Emitter<ObjectTypeState> emit,
  ) async {
    try {
      final updatedObjectType = await _dataSource.updateObjectType(
        event.objectTypeId,
        event.request,
      );

      // Обновляем тип в списке
      final index = _objectTypes.indexWhere(
        (ot) => ot.id == event.objectTypeId,
      );
      if (index != -1) {
        _objectTypes[index] = updatedObjectType;
      }

      // Обновляем состояние если текущее состояние - loaded
      if (state is ObjectTypeLoaded) {
        final currentState = state as ObjectTypeLoaded;
        emit(currentState.copyWith(objectTypes: List.from(_objectTypes)));
      }

      emit(ObjectTypeUpdated(updatedObjectType));

      // Возвращаемся к предыдущему состоянию после успешного обновления
      if (state is ObjectTypeUpdated) {
        final currentState = state as ObjectTypeLoaded?;
        if (currentState != null) {
          emit(currentState);
        } else {
          emit(ObjectTypeInitial());
        }
      }
    } catch (e) {
      emit(ObjectTypeError('Ошибка при обновлении типа объекта: $e'));
    }
  }

  Future<void> _onDeleteObjectType(
    DeleteObjectTypeEvent event,
    Emitter<ObjectTypeState> emit,
  ) async {
    try {
      await _dataSource.deleteObjectType(event.objectTypeId);

      _objectTypes.removeWhere((ot) => ot.id == event.objectTypeId);

      if (state is ObjectTypeLoaded) {
        final currentState = state as ObjectTypeLoaded;
        emit(
          currentState.copyWith(
            objectTypes: List.from(_objectTypes),
            totalCount: currentState.totalCount - 1,
          ),
        );
      }

      emit(ObjectTypeDeleted(event.objectTypeId));

      if (state is ObjectTypeDeleted) {
        final currentState = state as ObjectTypeLoaded?;
        if (currentState != null) {
          emit(currentState);
        } else {
          emit(ObjectTypeInitial());
        }
      }
    } catch (e) {
      emit(ObjectTypeError('Ошибка при удалении типа объекта: $e'));
    }
  }

  Future<void> _onCheckObjectTypeExists(
    CheckObjectTypeExistsEvent event,
    Emitter<ObjectTypeState> emit,
  ) async {
    try {
      final exists = await _dataSource.checkObjectTypeExists(
        CheckObjectTypeExistsQuery(
          name: event.name,
          entityType: event.entityType,
        ),
      );

      if (state is ObjectTypeLoaded) {
        emit(state as ObjectTypeLoaded);
      }
    } catch (e) {
      emit(
        ObjectTypeError('Ошибка при проверке существования типа объекта: $e'),
      );
    }
  }
}
