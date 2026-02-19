import 'package:flutter/material.dart';
import 'package:blurt_ai/features/tasks/models/task_repository.dart';
import 'package:blurt_ai/services/speech/speech_service.dart';
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
  final TextEditingController _controller = TextEditingController();

  // AnimatedList controls
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

  /// Syncs the stream data with the AnimatedList state safely after the build frame
  void _handleTaskUpdate(List<TaskModel> newTasks) {
    // We use postFrameCallback to avoid the "setState() called during build" error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // 1. Handle Additions
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

      // 2. Handle Deletions
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

      // 3. Update status (Strike-through)
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
            letterSpacing: -0.5,
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

        // 🔥 FIRST LOAD FIX
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

        // After first load → handle diffs
        _handleTaskUpdate(newTasks);

        if (_displayedTasks.isEmpty) {
          return _buildEmptyState();
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
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF141A2A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _repository.toggleTask(task.id, task.completed),
              onLongPress: () => _repository.deleteTask(task.id),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    _buildAnimatedCheckbox(task),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task.parsedTaskText,
                        style: TextStyle(
                          color:
                              task.completed
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          decoration:
                              task.completed
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                          decorationColor: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCheckbox(TaskModel task) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color:
              task.completed
                  ? Colors.blueAccent
                  : Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
        color:
            task.completed
                ? Colors.blueAccent.withValues(alpha: 0.2)
                : Colors.transparent,
      ),
      child:
          task.completed
              ? const Icon(Icons.check, size: 16, color: Colors.blueAccent)
              : null,
    );
  }

  Widget _buildBottomInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E1A),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF141A2A),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Blurt your tasks...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildMicButton(),
          const SizedBox(width: 8),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildMicButton() {
    return AnimatedBuilder(
      animation: _micPulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow:
                _isListening
                    ? [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.3),
                        blurRadius: 12 * _micPulseController.value,
                      ),
                    ]
                    : [],
          ),
          child: InkWell(
            onTap: _toggleListening,
            customBorder: const CircleBorder(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _isListening
                        ? Colors.redAccent.withValues(alpha: 0.8)
                        : const Color(0xFF1F2639),
              ),
              child: Icon(
                Icons.mic,
                color: _isListening ? Colors.white : Colors.white70,
                size: 20,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSendButton() {
    return InkWell(
      onTap: () async {
        if (_controller.text.trim().isEmpty) return;
        await _repository.addTask(_controller.text.trim());
        _controller.clear();
      },
      customBorder: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Colors.blueAccent.withValues(alpha: 0.8),
              Colors.blue.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks yet',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }
}
