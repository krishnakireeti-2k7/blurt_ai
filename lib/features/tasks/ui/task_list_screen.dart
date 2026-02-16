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
  String _tempSpeech = '';
  void _handleSpeechCompletion() {
    setState(() {
      _isListening = false;

      if (_tempSpeech.trim().isNotEmpty) {
        final existing = _controller.text.trim();

        if (existing.isEmpty) {
          _controller.text = _tempSpeech.trim();
        } else {
          _controller.text = "$existing ${_tempSpeech.trim()}";
        }
      }
    });
  }


  Future<void> _toggleListening() async {
    if (!_isListening) {
      setState(() => _isListening = true);

      await _speechService.startListening(
        onResult: (text, isFinal) {
          if (isFinal) {
            _tempSpeech = text;
          }
        },
        onStopped: () {
          _handleSpeechCompletion();
        },
      );
    } else {
      await _speechService.stopListening();
      _handleSpeechCompletion();
    }
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
        children: [_buildInputField(), Expanded(child: _buildTaskList())],
      ),
    );
  }

  Widget _buildInputField() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child:
                _isListening
                    ? const _ListeningIndicator()
                    : TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Speak or type a task...',
                        hintStyle: TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Color(0xFF1A1F2E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
          ),
          const SizedBox(width: 8),

          // 🔴 Animated Mic Button
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  _isListening
                      ? Colors.red.withOpacity(0.2)
                      : Colors.transparent,
            ),
            child: IconButton(
              icon: Icon(
                Icons.mic,
                color: _isListening ? Colors.red : Colors.white,
              ),
              onPressed: _toggleListening,
            ),
          ),

          const SizedBox(width: 8),

          IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
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
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];

            return ListTile(
              title: Text(
                task.parsedTaskText,
                style: TextStyle(
                  color: Colors.white,
                  decoration:
                      task.completed ? TextDecoration.lineThrough : null,
                ),
              ),
              leading: Checkbox(
                value: task.completed,
                onChanged: (_) async {
                  await _repository.toggleTask(task.id, task.completed);
                },
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  await _repository.deleteTask(task.id);
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _ListeningIndicator extends StatelessWidget {
  const _ListeningIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.graphic_eq, color: Colors.red, size: 32),
        SizedBox(width: 8),
        Text("Listening...", style: TextStyle(color: Colors.white70)),
      ],
    );
  }
}
