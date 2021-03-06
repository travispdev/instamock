import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/all.dart';
import 'package:instamock/shared/post_models.dart';

part 'post_list_state.freezed.dart';

@freezed
abstract class PostListState implements _$PostListState {
  const PostListState._();

  const factory PostListState({
    @Default([]) List<Post> postList,
    @Default(false) bool isInitializing,
    @Default(false) bool isLoadingMore,
  }) = _PostListState;

  int get postCount {
    if (isLoadingMore) {
      return postList.length + 1;
    } else {
      return postList.length;
    }
  }
}

class PostListViewModel extends StateNotifier<PostListState> {
  PostListViewModel() : super(PostListState());

  final postPerPage = 10;
  late final CollectionReference _collectionReference;
  QueryDocumentSnapshot? _lastDocument;

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _collectionReference = FirebaseFirestore.instance.collection('posts');
      final querySnapshot = await _collectionReference.orderBy('createdAt', descending: true).limit(postPerPage).get();
      _lastDocument = querySnapshot.docs.lastOrNull;
      state = state.copyWith.call(
        isInitializing: false,
        postList: querySnapshot.docs.map((e) => Post.fromJson(e.data())).toList(),
      );
    } catch (e, s) {
      state = state.copyWith.call(isInitializing: false);
      throw e;
    }
  }

  Future<void> fetchMoreIfAny() async {
    if (_lastDocument == null || state.isLoadingMore) {
      return;
    }
    try {
      state = state.copyWith.call(isLoadingMore: true);
      final querySnapshot =
          await _collectionReference.orderBy('createdAt', descending: true).startAfterDocument(_lastDocument).limit(postPerPage).get();
      _lastDocument = querySnapshot.docs.lastOrNull;
      state = state.copyWith.call(
        isLoadingMore: false,
        postList: [
          ...state.postList,
          ...querySnapshot.docs.map((e) => Post.fromJson(e.data())).toList(),
        ],
      );
    } catch (e, s) {
      state = state.copyWith.call(isLoadingMore: false);
      throw e;
    }
  }

  void addNewPostFromLocal(Post post) {
    state = state.copyWith.call(
      postList: [
        post,
        ...state.postList,
      ],
    );
  }
}

final postListViewModelProvider = StateNotifierProvider((ref) => PostListViewModel());
