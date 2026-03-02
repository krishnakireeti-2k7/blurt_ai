import 'package:cloud_functions/cloud_functions.dart';

class AiTaskService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<List<dynamic>> extractTasks(String speechText) async {
    try {
      final callable = _functions.httpsCallable('extractTasks');

      final result = await callable.call({"text": speechText});

      final data = result.data;

      return data['data']['tasks'] as List<dynamic>;
    } catch (e) {
      print("AI extraction error: $e");
      rethrow;
    }
  }
}
