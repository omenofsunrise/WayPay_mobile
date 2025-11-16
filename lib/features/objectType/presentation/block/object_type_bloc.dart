import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/objectType/data/data_source/object_type_remote_data_source.dart';
import 'package:waypay_mobile/features/objectType/data/models/get_object_types_query.dart';
import 'package:waypay_mobile/features/objectType/data/models/object_type_model.dart';
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
    on<EditObjectTypeEvent>(_onEditObjectType);
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
    // Сохраняем предыдущее состояние
    final previousState = state;

    try {
      emit(ObjectTypeLoading());
      final createdObjectType = await _dataSource.createObjectType(
        event.request,
      );

      // Добавляем новый тип в список
      _objectTypes.insert(0, createdObjectType);

      // Возвращаем обновленное состояние
      emit(
        ObjectTypeLoaded(
          objectTypes: List.from(_objectTypes),
          hasMoreData: _hasMore,
          currentPage: _currentPage,
          totalPages: previousState is ObjectTypeLoaded
              ? previousState.totalPages
              : 1,
          totalCount:
              (previousState is ObjectTypeLoaded
                  ? previousState.totalCount
                  : 0) +
              1,
        ),
      );
    } catch (e) {
      // В случае ошибки возвращаем предыдущее состояние
      emit(previousState);
      emit(ObjectTypeError('Ошибка при создании типа объекта: $e'));
    }
  }

  Future<void> _onEditObjectType(
    EditObjectTypeEvent event,
    Emitter<ObjectTypeState> emit,
  ) async {
    emit(ObjectTypeEditing(event.objectType));
  }

  Future<void> _onUpdateObjectType(
    UpdateObjectTypeEvent event,
    Emitter<ObjectTypeState> emit,
  ) async {
    // Сохраняем предыдущее состояние
    final previousState = state;

    try {
      emit(ObjectTypeLoading());
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

      // Возвращаем обновленное состояние
      if (previousState is ObjectTypeLoaded) {
        emit(previousState.copyWith(objectTypes: List.from(_objectTypes)));
      } else {
        emit(
          ObjectTypeLoaded(
            objectTypes: List.from(_objectTypes),
            hasMoreData: _hasMore,
            currentPage: _currentPage,
            totalPages: previousState is ObjectTypeLoaded
                ? previousState.totalPages
                : 1,
            totalCount: previousState is ObjectTypeLoaded
                ? previousState.totalCount
                : _objectTypes.length,
          ),
        );
      }
    } catch (e) {
      // В случае ошибки возвращаем предыдущее состояние
      emit(previousState);
      emit(ObjectTypeError('Ошибка при обновлении типа объекта: $e'));
    }
  }

  Future<void> _onDeleteObjectType(
    DeleteObjectTypeEvent event,
    Emitter<ObjectTypeState> emit,
  ) async {
    // Сохраняем предыдущее состояние
    final previousState = state;

    try {
      emit(ObjectTypeLoading());
      await _dataSource.deleteObjectType(event.objectTypeId);

      _objectTypes.removeWhere((ot) => ot.id == event.objectTypeId);

      // Возвращаем обновленное состояние
      if (previousState is ObjectTypeLoaded) {
        emit(
          previousState.copyWith(
            objectTypes: List.from(_objectTypes),
            totalCount: previousState.totalCount - 1,
          ),
        );
      } else {
        emit(
          ObjectTypeLoaded(
            objectTypes: List.from(_objectTypes),
            hasMoreData: _hasMore,
            currentPage: _currentPage,
            totalPages: 1,
            totalCount: _objectTypes.length,
          ),
        );
      }
    } catch (e) {
      // В случае ошибки возвращаем предыдущее состояние
      emit(previousState);
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
    } catch (e) {
      emit(
        ObjectTypeError('Ошибка при проверке существования типа объекта: $e'),
      );
    }
  }
}
