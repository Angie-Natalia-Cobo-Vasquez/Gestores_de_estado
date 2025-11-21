import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../models/task_model.dart';
import '../../providers/providers.dart';
import '../widgets/task_tile.dart';
import 'edit_task_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final uuid = const Uuid();
  var tasks = <TaskModel>[];
  var loading = true;

  @override
  void initState() {
    super.initState();
    _loadLocal();
    Future.microtask(() => ref.read(syncServiceProvider).trySync());
  }

  Future<void> _loadLocal() async {
    setState(() => loading = true);
    final repo = ref.read(tasksRepositoryProvider);
    try {
      final result = await repo.getAllLocal();
      setState(() {
        tasks = result;
        loading = false;
      });
    } catch (error) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar tareas: $error')),
        );
      }
    }
  }

  Future<void> _addTask() async {
    final id = uuid.v4();
    final now = DateTime.now().toUtc();
    final newTask = TaskModel(
      id: id,
      title: 'Nueva tarea',
      completed: false,
      updatedAt: now,
    );
    try {
      await ref.read(tasksRepositoryProvider).createLocal(newTask);
      await _loadLocal();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea creada')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear la tarea: $error')),
        );
      }
    }
  }

  Future<void> _toggle(TaskModel task) async {
    final updated = task.copyWith(
      completed: !task.completed,
      updatedAt: DateTime.now().toUtc(),
    );
    try {
      await ref.read(tasksRepositoryProvider).updateLocal(updated);
      await _loadLocal();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(updated.completed
                ? 'Tarea marcada como completada'
                : 'Tarea marcada como pendiente'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar la tarea: $error')),
        );
      }
    }
  }

  Future<void> _delete(TaskModel task) async {
    try {
      await ref.read(tasksRepositoryProvider).deleteLocal(
            task.id,
            DateTime.now().toUtc(),
          );
      await _loadLocal();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea eliminada')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(taskFilterProvider);
    final filteredTasks = tasks.where((task) {
      switch (filter) {
        case TaskFilter.all:
          return true;
        case TaskFilter.pending:
          return !task.completed && !task.deleted;
        case TaskFilter.completed:
          return task.completed && !task.deleted;
      }
    }).toList();

    final lastSyncText = tasks.isEmpty
        ? 'Sin tareas locales todavía'
        : 'Última actualización local: ${DateFormat('dd MMM yyyy • HH:mm', 'es').format(tasks.first.updatedAt.toLocal())}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskFlow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sincronizar',
            onPressed: () async {
              try {
                await ref.read(syncServiceProvider).trySync();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sincronización iniciada')),
                  );
                }
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error de sincronización: $error')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Organiza tu día',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Gestiona tus tareas y sincroniza cuando estés en línea.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              Text(
                lastSyncText,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 16),
              _FilterChips(filter: filter),
              const SizedBox(height: 12),
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadLocal,
                        child: filteredTasks.isEmpty
                            ? _EmptyState(onAdd: _addTask)
                            : ListView.separated(
                                itemCount: filteredTasks.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final task = filteredTasks[index];
                                  return TaskTile(
                                    task: task,
                                    onToggle: () => _toggle(task),
                                    onDelete: () => _delete(task),
                                    onEdit: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => EditTaskScreen(task: task),
                                        ),
                                      );
                                      await _loadLocal();
                                    },
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips({required this.filter});

  final TaskFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 12,
      children: TaskFilter.values.map((value) {
        final isSelected = value == filter;
        return ChoiceChip(
          label: Text(value.label),
          selected: isSelected,
          onSelected: (_) => ref.read(taskFilterProvider.notifier).state = value,
        );
      }).toList(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Align(
          child: Column(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, size: 60),
              ),
              const SizedBox(height: 20),
              Text(
                'No hay tareas en esta vista',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Crea tu primera tarea para comenzar a organizarte.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAdd,
                child: const Text('Añadir tarea'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
