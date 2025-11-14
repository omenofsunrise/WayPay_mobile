import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/blog/data/data_sources/blog_remote_data_sources.dart';
import 'package:waypay_mobile/features/blog/data/models/comment_response.dart';
import 'comment_event.dart';
import 'comment_state.dart';

class CommentBloc extends Bloc<CommentEvent, CommentState> {
  CommentBloc() : super(CommentInitial()) {
    on<LoadComments>(_onLoadComments);
    on<ToggleLikeComment>(_onToggleLikeComment);
    on<CreateComment>(_onCreateComment);
    on<DeleteComment>(_onDeleteComment);
    on<UpdateCommentText>(_onUpdateCommentText);
    on<AddCommentAttachment>(_onAddCommentAttachment);
  }

  Future<void> _onLoadComments(
    LoadComments event,
    Emitter<CommentState> emit,
  ) async {
    emit(CommentLoading());
    try {
      final comments = await getIt<BlogRemoteDataSources>().getCommentsByPostId(
        event.postId,
      );
      emit(CommentLoaded(comments));
    } catch (e) {
      emit(CommentError(e.toString()));
    }
  }

  Future<void> _onToggleLikeComment(
    ToggleLikeComment event,
    Emitter<CommentState> emit,
  ) async {
    final currentState = state;
    if (currentState is CommentLoaded) {
      final updatedComments = _updateLikeInTree(
        currentState.comments,
        event.commentId,
      );
      emit(CommentLoaded(updatedComments));

      try {
        await getIt<BlogRemoteDataSources>().likeComment(event.commentId);
      } catch (_) {}
    }
  }

  Future<void> _onCreateComment(
    CreateComment event,
    Emitter<CommentState> emit,
  ) async {
    try {
      final newComment = await getIt<BlogRemoteDataSources>().createComment(
        postId: event.postId,
        parentId: event.parentId,
        content: event.content,
        attachments: event.attachments,
      );

      final currentState = state;
      if (currentState is CommentLoaded) {
        List<CommentResponse> updatedComments;
        if (event.parentId != null) {
          updatedComments = _addReplyToTree(
            currentState.comments,
            event.parentId!,
            newComment,
          );
        } else {
          updatedComments = [...currentState.comments, newComment];
        }

        emit(CommentLoaded(updatedComments));
      } else {
        add(LoadComments(event.postId));
      }
    } catch (e) {
      emit(CommentError('Ошибка при создании комментария: $e'));
    }
  }

  Future<void> _onDeleteComment(
    DeleteComment event,
    Emitter<CommentState> emit,
  ) async {
    try {
      await getIt<BlogRemoteDataSources>().deleteComment(event.commentId);

      final currentState = state;
      if (currentState is CommentLoaded) {
        final updatedComments = _removeCommentFromTree(
          currentState.comments,
          event.commentId,
        );
        emit(CommentLoaded(updatedComments));
      } else {
        add(LoadComments(event.postId));
      }
    } catch (e) {
      emit(CommentError('Ошибка при удалении комментария: $e'));
    }
  }

  Future<void> _onUpdateCommentText(
    UpdateCommentText event,
    Emitter<CommentState> emit,
  ) async {
    try {
      await getIt<BlogRemoteDataSources>().updateCommentText(
        commentId: event.commentId,
        newText: event.newText,
      );

      final currentState = state;
      if (currentState is CommentLoaded) {
        final updatedComments = _updateCommentTextInTree(
          currentState.comments,
          event.commentId,
          event.newText,
        );
        emit(CommentLoaded(updatedComments));
      } else {
        add(LoadComments(event.postId));
      }
    } catch (e) {
      emit(CommentError('Ошибка при обновлении комментария: $e'));
    }
  }

  List<CommentResponse> _updateLikeInTree(
    List<CommentResponse> comments,
    int commentId,
  ) {
    return comments.map((comment) {
      if (comment.id == commentId) {
        return comment.copyWith(
          isLikedByCurrentUser: !comment.isLikedByCurrentUser,
          likeCount: comment.isLikedByCurrentUser
              ? comment.likeCount - 1
              : comment.likeCount + 1,
        );
      }

      if (comment.replies.isNotEmpty) {
        return comment.copyWith(
          replies: _updateLikeInTree(comment.replies, commentId),
        );
      }

      return comment;
    }).toList();
  }

  List<CommentResponse> _addReplyToTree(
    List<CommentResponse> comments,
    int parentId,
    CommentResponse reply,
  ) {
    return comments.map((comment) {
      if (comment.id == parentId) {
        return comment.copyWith(replies: [...comment.replies, reply]);
      }

      if (comment.replies.isNotEmpty) {
        return comment.copyWith(
          replies: _addReplyToTree(comment.replies, parentId, reply),
        );
      }

      return comment;
    }).toList();
  }

  List<CommentResponse> _removeCommentFromTree(
    List<CommentResponse> comments,
    int commentId,
  ) {
    return comments
        .where((comment) => comment.id != commentId)
        .map(
          (comment) => comment.copyWith(
            replies: _removeCommentFromTree(comment.replies, commentId),
          ),
        )
        .toList();
  }

  List<CommentResponse> _updateCommentTextInTree(
    List<CommentResponse> comments,
    int commentId,
    String newText,
  ) {
    return comments.map((comment) {
      if (comment.id == commentId) {
        return comment.copyWith(content: newText);
      }

      if (comment.replies.isNotEmpty) {
        return comment.copyWith(
          replies: _updateCommentTextInTree(
            comment.replies,
            commentId,
            newText,
          ),
        );
      }

      return comment;
    }).toList();
  }

  Future<void> _onAddCommentAttachment(
    AddCommentAttachment event,
    Emitter<CommentState> emit,
  ) async {
    try {
      final updatedComment = await getIt<BlogRemoteDataSources>()
          .uploadCommentAttachment(
            commentId: event.commentId,
            file: event.file,
          );

      final currentState = state;
      if (currentState is CommentLoaded) {
        final updatedComments = _replaceCommentInTree(
          currentState.comments,
          updatedComment,
        );
        emit(CommentLoaded(updatedComments));
      } else {
        add(LoadComments(event.postId));
      }
    } catch (e) {
      emit(CommentError('Ошибка при добавлении вложения: $e'));
    }
  }

  List<CommentResponse> _replaceCommentInTree(
    List<CommentResponse> comments,
    CommentResponse updated,
  ) {
    return comments.map((comment) {
      if (comment.id == updated.id) {
        return updated;
      }
      if (comment.replies.isNotEmpty) {
        return comment.copyWith(
          replies: _replaceCommentInTree(comment.replies, updated),
        );
      }
      return comment;
    }).toList();
  }
}
