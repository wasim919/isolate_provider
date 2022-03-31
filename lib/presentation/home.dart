import "package:flutter/material.dart";
import 'package:isolate/core/constants.dart';
import 'package:isolate/models/post_model.dart';
import 'package:isolate/providers/posts_provider.dart';
import 'package:isolate/workers/main.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    Worker.createTask(
      postsProvider: context.read<PostsProvider>(),
      taskName: WORKER_GET_POSTS_NAMESPACE,
      inputData: {},
    );
    super.initState();
  }

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
            return ListView.separated(
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
            );
          }
        },
      ),
    );
  }
}
