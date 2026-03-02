import 'package:flutter/material.dart';
import 'package:blurt_ai/features/tasks/models/task_repository.dart';
import 'package:blurt_ai/services/speech/speech_service.dart';
import 'package:blurt_ai/services/ai/ai_task_service.dart';
import '../models/task_model.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen>
    with TickerProviderStateMixin {
  final TaskRepository _repository = TaskRepository();
  final SpeechService _speechService = SpeechService();
  final AiTaskService _aiService = AiTaskService();
  final TextEditingController _controller = TextEditingController();

  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<TaskModel> _displayedTasks = [];

  bool _isListening = false;
  String _pendingSpeech = '';
  late AnimationController _micPulseController;

  @override
  void initState() {
    super.initState();
    _micPulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  void _handleTaskUpdate(List<TaskModel> newTasks) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      for (var i = 0; i < newTasks.length; i++) {
        final task = newTasks[i];
        if (!_displayedTasks.any((t) => t.id == task.id)) {
          _displayedTasks.insert(i, task);
          _listKey.currentState?.insertItem(
            i,
            duration: const Duration(milliseconds: 500),
          );
        }
      }

      final idsToRemove =
          _displayedTasks
              .where((t) => !newTasks.any((nt) => nt.id == t.id))
              .map((t) => t.id)
              .toList();

      for (var id in idsToRemove) {
        final index = _displayedTasks.indexWhere((t) => t.id == id);
        if (index != -1) {
          final removedItem = _displayedTasks.removeAt(index);
          _listKey.currentState?.removeItem(
            index,
            (context, animation) => _buildTaskItem(removedItem, animation),
            duration: const Duration(milliseconds: 300),
          );
        }
      }

      for (var i = 0; i < _displayedTasks.length; i++) {
        final updatedTask = newTasks.firstWhere(
          (t) => t.id == _displayedTasks[i].id,
          orElse: () => _displayedTasks[i],
        );
        if (_displayedTasks[i].completed != updatedTask.completed) {
          setState(() {
            _displayedTasks[i] = updatedTask;
          });
        }
      }
    });
  }

  void _handleSpeechCompletion() {
    if (!mounted) return;
    final spokenText = _pendingSpeech.trim();
    setState(() {
      _isListening = false;
      _micPulseController.stop();
      if (spokenText.isNotEmpty) {
        final existing = _controller.text.trim();
        _controller.text =
            existing.isEmpty ? spokenText : "$existing $spokenText";
      }
    });
    _pendingSpeech = '';
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      _pendingSpeech = '';
      setState(() => _isListening = true);
      _micPulseController.repeat();
      await _speechService.startListening(
        onResult: (text, _) => _pendingSpeech = text.trim(),
        onStopped: _handleSpeechCompletion,
        onListeningStateChanged: (isL) {
          if (mounted) setState(() => _isListening = isL);
        },
      );
    } else {
      await _speechService.stopListening();
    }
  }

  @override
  void dispose() {
    _speechService.stopListening();
    _controller.dispose();
    _micPulseController.dispose();
    super.dispose();
  }

  Future<void> _processWithAI() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    try {
      final tasks = await _aiService.extractTasks(text);

      for (final task in tasks) {
        await _repository.addTask(task['title']);
      }

      _controller.clear();
    } catch (e) {
      print("AI processing failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Your Tasks',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildStreamWrapper()),
          _buildBottomInputBar(),
        ],
      ),
    );
  }

  Widget _buildStreamWrapper() {
    return StreamBuilder<List<TaskModel>>(
      stream: _repository.streamTasks(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final newTasks = snapshot.data!;

        if (_displayedTasks.isEmpty) {
          _displayedTasks.addAll(newTasks);

          return AnimatedList(
            key: _listKey,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            initialItemCount: _displayedTasks.length,
            itemBuilder: (context, index, animation) {
              return _buildTaskItem(_displayedTasks[index], animation);
            },
          );
        }

        _handleTaskUpdate(newTasks);

        if (_displayedTasks.isEmpty) {
          return const Center(child: Text("No tasks yet"));
        }

        return AnimatedList(
          key: _listKey,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          initialItemCount: _displayedTasks.length,
          itemBuilder: (context, index, animation) {
            if (index >= _displayedTasks.length) {
              return const SizedBox.shrink();
            }
            return _buildTaskItem(_displayedTasks[index], animation);
          },
        );
      },
    );
  }

  Widget _buildTaskItem(TaskModel task, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: animation,
        child: ListTile(
          title: Text(
            task.parsedTaskText,
            style: TextStyle(
              color: task.completed ? Colors.grey : Colors.white,
              decoration:
                  task.completed
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
            ),
          ),
          onTap: () => _repository.toggleTask(task.id, task.completed),
          onLongPress: () => _repository.deleteTask(task.id),
        ),
      ),
    );
  }

  Widget _buildBottomInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Blurt your tasks...",
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.mic), onPressed: _toggleListening),
          IconButton(icon: const Icon(Icons.send), onPressed: _processWithAI),
        ],
      ),
    );
  }
}
