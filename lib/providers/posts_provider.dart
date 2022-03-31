import 'package:flutter/material.dart';
import 'package:isolate/models/post_model.dart';

class PostsProvider extends ChangeNotifier {
  List<PostModel> posts = [];

  String error = "";

  bool loader = true;

  setPosts(List<PostModel> _posts) {
    posts = _posts;
    notifyListeners();
  }

  setLoader(bool value) {
    loader = value;
    notifyListeners();
  }

  setError(String _error) {
    error = _error;
    notifyListeners();
  }
}
