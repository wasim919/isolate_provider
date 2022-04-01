import 'dart:convert';
import 'dart:isolate';

import 'package:isolate/core/clients/enums.dart';
import 'package:isolate/core/clients/http_client.dart';
import 'package:isolate/core/constants.dart';
import 'package:isolate/models/post_model.dart';
import 'package:isolate/providers/posts_provider.dart';

class Worker {
  // Communication: _mainReceivePort <=> _mainSendPort
  static final ReceivePort _mainReceivePort = ReceivePort();
  static Isolate? _isolate;

  // This includes the methods that will be invoked inside of the "child" isolate based on taskName
  static Future<void> callbackDispatcher(
    dynamic message,
    SendPort mainSendPort,
  ) async {
    try {
      if (message is Map) {
        String taskName = message[WORKER_TASK_NAMESPACE];

        if (taskName == WorkerTasks.GetPosts) {
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
            data: (jsonDecode(jsonString) as List<dynamic>)
                .map(
                  (e) => PostModel.fromJson(e),
                )
                .toList(),
          );
        }
      }
    } catch (e) {
      sendResponse(
        mainSendPort: mainSendPort,
        workerStatus: WorkerStatus.Error,
        data: e.toString(),
      );
      return;
    }
  }

  // Creates an isolate for taskName and inputData and passes it as payload
  static void createTask<T>({
    required T provider,
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

      // Listens for messages from the child isolate
      _mainReceivePort.listen((message) {
        // Setting the childSentPort sent by the child isolate for communication
        // childSendPort <=> childReceivePort
        if (message is SendPort) {
          childSendPort = message;
          childSendPort?.send(
            payload,
          );
        }
        // If the message contains data
        else if (message is Map) {
          final status = message[WORKER_RESPONSE_STATUS_NAMESPACE];
          final data = message[WORKER_RESPONSE_DATA_NAMESPACE];
          _handleUiCallback<T>(
            taskName: taskName,
            workerStatus: status,
            data: data,
            provider: provider,
          );
        }
      });
    } catch (e) {
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
        (message) => callbackDispatcher(
          message,
          mainSendPort,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  // On receiving data from the child isolate
  // main isolate updates the UI based on taskName, provider and workerStatus
  static _handleUiCallback<T>({
    required String taskName,
    required WorkerStatus workerStatus,
    required dynamic data,
    required T provider,
  }) async {
    if (taskName == WorkerTasks.GetPosts && T == PostsProvider) {
      PostsProvider postsProvider = (provider as PostsProvider);
      if (workerStatus == WorkerStatus.Done && data is List<PostModel>) {
        postsProvider.setLoader(
          false,
        );
        postsProvider.setPosts(
          data,
        );
        dispose();
      } else if (workerStatus == WorkerStatus.Loading) {
        postsProvider.setLoader(
          true,
        );
      } else if (workerStatus == WorkerStatus.Error ||
          data is! List<PostModel>) {
        postsProvider.setLoader(
          false,
        );
        postsProvider.setError(
          data,
        );
        dispose();
      }
    }
  }

  // Invoked by the "child" Isolate to send messages to the parent (main) Isoalte
  static void sendResponse({
    required SendPort mainSendPort,
    required WorkerStatus workerStatus,
    required dynamic data,
  }) {
    mainSendPort.send(
      {
        WORKER_RESPONSE_STATUS_NAMESPACE: workerStatus,
        WORKER_RESPONSE_DATA_NAMESPACE: data,
      },
    );
  }

  // Clearning the memory
  static void dispose() {
    _mainReceivePort.close();
    _isolate?.kill();
  }
}
