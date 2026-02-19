import 'package:flutter/material.dart';
import 'package:blurt_ai/features/tasks/models/task_repository.dart';
import 'package:blurt_ai/services/speech/speech_service.dart';
import '../models/task_model.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TaskRepository _repository = TaskRepository();
  final SpeechService _speechService = SpeechService();
  final TextEditingController _controller = TextEditingController();

  bool _isListening = false;
  String _pendingSpeech = '';

  void _handleSpeechCompletion() {
    if (!mounted) return;

    final spokenText = _pendingSpeech.trim();
    setState(() {
      _isListening = false;

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

      await _speechService.startListening(
        onResult: (text, _) {
          final trimmed = text.trim();
          if (trimmed.isEmpty) return;
          _pendingSpeech = trimmed;
        },
        onStopped: _handleSpeechCompletion,
        onListeningStateChanged: (isListening) {
          if (!mounted) return;
          setState(() => _isListening = isListening);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F1A),
        elevation: 0,
        title: const Text('Your Tasks', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [Expanded(child: _buildTaskList()), _buildBottomInputBar()],
      ),
    );
  }

  // ------------------------
  // Bottom Input Bar
  // ------------------------

  Widget _buildBottomInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0B0F1A),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F2E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                maxLines: null,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: 'Blurt your tasks...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Mic
          IconButton(
            icon: Icon(
              Icons.mic,
              color: _isListening ? Colors.red : Colors.white,
            ),
            onPressed: _toggleListening,
          ),

          // Send
          IconButton(
            icon: const Icon(Icons.arrow_upward, color: Colors.white),
            onPressed: () async {
              if (_controller.text.trim().isEmpty) return;

              await _repository.addTask(_controller.text.trim());
              _controller.clear();
            },
          ),
        ],
      ),
    );
  }

  // ------------------------
  // Task List
  // ------------------------

  Widget _buildTaskList() {
    return StreamBuilder<List<TaskModel>>(
      stream: _repository.streamTasks(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data!;

        if (tasks.isEmpty) {
          return const Center(
            child: Text(
              'No tasks yet',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];

            return GestureDetector(
              onLongPress: () async {
                await _repository.deleteTask(task.id);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F2E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: task.completed,
                      onChanged: (_) async {
                        await _repository.toggleTask(task.id, task.completed);
                      },
                    ),
                    Expanded(
                      child: Text(
                        task.parsedTaskText,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          decoration:
                              task.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
