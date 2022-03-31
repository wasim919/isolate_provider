import "package:flutter/material.dart";
import 'package:isolate/models/post_model.dart';
import 'package:isolate/providers/posts_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Isolate Example",
        ),
      ),
      body: Consumer<PostsProvider>(
        builder: (context, postsProvider, child) {
          if (postsProvider.loader) {
            return const Center(
              child: Text("Loading..."),
            );
          } else if (postsProvider.error.isNotEmpty) {
            return Center(
              child: Text("Error: ${postsProvider.error}"),
            );
          } else {
            return SingleChildScrollView(
              child: ListView.separated(
                itemCount: postsProvider.posts.length,
                separatorBuilder: (context, index) => const Divider(
                  color: Colors.black45,
                ),
                itemBuilder: (context, index) {
                  PostModel post = postsProvider.posts[index];
                  return ListTile(
                    title: Text(
                      post.title!,
                    ),
                    subtitle: Text(
                      post.body!,
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}
