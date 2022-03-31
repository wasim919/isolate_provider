import 'dart:convert';
import 'dart:isolate';

import 'package:isolate/core/clients/enums.dart';
import 'package:isolate/core/clients/http_client.dart';
import 'package:isolate/core/constants.dart';
import 'package:isolate/models/post_model.dart';
import 'package:isolate/providers/posts_provider.dart';

class Worker {
  static final ReceivePort _mainReceivePort = ReceivePort();
  static Isolate? _isolate;

  static void createTask({
    required PostsProvider postsProvider,
    required String taskName,
    required Map<String, dynamic> inputData,
  }) async {
    try {
      Map payload = {
        WORKER_TASK_NAMESPACE: taskName,
        WORKER_TASK_PAYLOAD: inputData,
      };
      _isolate = await Isolate.spawn(
        _isolateEntry,
        _mainReceivePort.sendPort,
      );
      SendPort? childSendPort;

      _mainReceivePort.listen((message) {
        if (message is SendPort) {
          childSendPort = message;
          childSendPort?.send(
            payload,
          );
        } else if (message is Map) {
          WorkerStatus workerStatus = message[WORKER_RESPONSE_STATUS_NAMESPACE];

          String data = message[WORKER_RESPONSE_DATA_NAMESPACE];
          if (workerStatus == WorkerStatus.Done) {
            postsProvider.setLoader(
              false,
            );
            List<PostModel> _posts = (jsonDecode(data) as List<dynamic>)
                .map(
                  (e) => PostModel.fromJson(e),
                )
                .toList();
            postsProvider.setPosts(
              _posts,
            );
            dispose();
          } else if (workerStatus == WorkerStatus.Loading) {
            postsProvider.setLoader(
              true,
            );
          } else if (workerStatus == WorkerStatus.Error) {
            postsProvider.setLoader(
              false,
            );
            postsProvider.setError(
              data,
            );
            dispose();
          }
        }
      });
    } catch (e) {
      print(
        e,
      );
      dispose();
    }
  }

  static void _isolateEntry(
    SendPort mainSendPort,
  ) async {
    ReceivePort childReceivePort = ReceivePort();
    try {
      mainSendPort.send(
        childReceivePort.sendPort,
      );
      childReceivePort.listen(
        (message) async {
          if (message is Map) {
            String taskName = message[WORKER_TASK_NAMESPACE];
            if (taskName == WORKER_GET_POSTS_NAMESPACE) {
              sendResponse(
                mainSendPort: mainSendPort,
                workerStatus: WorkerStatus.Loading,
                data: "",
              );
              var jsonString = await HttpClient.fetch(
                "https://jsonplaceholder.typicode.com/posts",
              );
              sendResponse(
                mainSendPort: mainSendPort,
                workerStatus: WorkerStatus.Done,
                data: jsonString,
              );
            }
          }
        },
      );
    } catch (e) {
      sendResponse(
        mainSendPort: mainSendPort,
        workerStatus: WorkerStatus.Error,
        data: e.toString(),
      );
    }
  }

  static void sendResponse({
    required SendPort mainSendPort,
    required WorkerStatus workerStatus,
    required String data,
  }) {
    mainSendPort.send(
      {
        WORKER_RESPONSE_STATUS_NAMESPACE: workerStatus,
        WORKER_RESPONSE_DATA_NAMESPACE: data,
      },
    );
  }

  static void dispose() {
    _mainReceivePort.close();
    _isolate?.kill();
  }
}
