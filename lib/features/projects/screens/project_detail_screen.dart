import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../finance/data/finance_repository.dart';
import '../data/project_repository.dart';
import '../models/project_model.dart';
import 'add_edit_project_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  final Project? initialProject;
  const ProjectDetailScreen({super.key, required this.projectId, this.initialProject});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final ProjectRepository _projectRepo = ProjectRepository();
  final FinanceRepository _financeRepo = FinanceRepository();
  String? _expandedPhaseId;
  bool _isFirstLoad = true;
  Project? _cachedProject;

  Future<void> _toggleSubtask(Project project, Phase phase, ProjectTask task, Subtask subtask, bool isDone) async {
    await _projectRepo.updateSubtaskStatus(
      projectId: project.id,
      phaseId: phase.id,
      taskId: task.id,
      subtaskId: subtask.id,
      isDone: isDone,
      subtaskName: subtask.name,
    );
  }

  Future<void> _updateTaskStatus(Phase phase, ProjectTask task, TaskStatus newStatus, Project project) async {
    await _projectRepo.updateTaskStatus(
      projectId: project.id,
      phaseId: phase.id,
      taskId: task.id,
      newStatus: newStatus,
    );
  }

  Future<void> _updatePhaseStatus(Phase phase, TaskStatus newStatus, Project project) async {
    await _projectRepo.updatePhaseStatus(
      projectId: project.id,
      phaseId: phase.id,
      newStatus: newStatus,
    );
  }

  void _showModuleAddSheet(Project project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ModuleAddBottomSheet(
        accentColor: project.projectColor,
        isDark: Theme.of(context).brightness == Brightness.dark,
        onAdd: (name, description, price) async {
          final newPhase = Phase(
            id: const Uuid().v4(),
            projectId: project.id,
            name: name.toUpperCase(),
            description: description.isEmpty ? null : description,
            price: price,
            startDate: DateTime.now(),
            endDate: DateTime.now().add(const Duration(days: 7)),
            orderIndex: project.phases.length,
            status: TaskStatus.todo,
          );
          await _projectRepo.saveProject(project.copyWith(
            phases: [...project.phases, newPhase],
          ));
        },
      ),
    );
  }

  void _showTaskAddSheet(Project project, Phase phase) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TaskAddBottomSheet(
        accentColor: project.projectColor,
        isDark: Theme.of(context).brightness == Brightness.dark,
        onAdd: (name, price, priority, subtasks) async {
          final newTask = ProjectTask(
            id: const Uuid().v4(),
            phaseId: phase.id,
            name: name.toUpperCase(),
            price: price,
            priority: priority,
            status: TaskStatus.todo,
            startDate: phase.startDate,
            endDate: phase.endDate,
            subtasks: subtasks,
          );
          
          final updatedPhases = project.phases.map((p) {
            if (p.id == phase.id) {
              return p.copyWith(tasks: [...p.tasks, newTask]);
            }
            return p;
          }).toList();
          
          await _projectRepo.saveProject(project.copyWith(phases: updatedPhases));
        },
      ),
    );
  }

  void _showBudgetSheet(Project project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BudgetBottomSheet(
        project: project,
        financeRepo: _financeRepo,
        onUpdate: (total, advance) async {
          await _projectRepo.saveProject(project.copyWith(totalPrice: total, advanceAmount: advance));
        },
      ),
    );
  }

  Future<void> _deleteProject(Project project) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.rose.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.rose,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Delete Project?',
              style: AppTextStyles.h2(context).copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to delete "${project.name}"? This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.rose,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'DELETE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _projectRepo.deleteProject(project.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<Project?>(
      stream: _projectRepo.getProjectStream(widget.projectId),
      initialData: widget.initialProject ?? _cachedProject,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData && _cachedProject == null) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0D1117) : AppColors.bg,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final p = snapshot.data;
        if (p == null) return const Scaffold(body: Center(child: Text('Project not found')));
        
        _cachedProject = p;
        
        if (_isFirstLoad && p.phases.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final activePhase = p.phases.firstWhere((ph) => ph.status != TaskStatus.done, orElse: () => p.phases.first);
              setState(() {
                _expandedPhaseId = activePhase.id;
                _isFirstLoad = false;
              });
            }
          });
        }

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0D1117) : AppColors.bg,
          body: RefreshIndicator(
            onRefresh: () async => setState(() => _cachedProject = null),
            color: p.projectColor,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                _buildSliverAppBar(p, isDark),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProjectHeaderCard(
                          p: p, 
                          isDark: isDark, 
                          onBudgetTap: () => _showBudgetSheet(p),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('MISSION ROADMAP', style: TextStyle(color: p.projectColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
                                const SizedBox(height: 4),
                                Text('Modules & Progress', style: AppTextStyles.h2(context).copyWith(fontWeight: FontWeight.w900, fontSize: 20)),
                              ],
                            ),
                            IconButton.filledTonal(
                              onPressed: () => _showModuleAddSheet(p),
                              icon: const Icon(Icons.add_rounded, size: 20),
                              style: IconButton.styleFrom(
                                backgroundColor: p.projectColor.withValues(alpha: 0.08), 
                                foregroundColor: p.projectColor,
                                padding: const EdgeInsets.all(8),
                              ),
                              tooltip: 'Add Module',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final phase = p.phases[index];
                        return _PhaseCard(
                          phase: phase,
                          isExpanded: _expandedPhaseId == phase.id,
                          onTap: () => setState(() => _expandedPhaseId = _expandedPhaseId == phase.id ? null : phase.id),
                          onToggleSubtask: (task, sub, val) => _toggleSubtask(p, phase, task, sub, val),
                          onTaskStatusChange: (task, s) => _updateTaskStatus(phase, task, s, p),
                          onPhaseStatusChange: (s) => _updatePhaseStatus(phase, s, p),
                          onAddTask: () => _showTaskAddSheet(p, phase),
                          accentColor: p.projectColor,
                          isDark: isDark,
                        ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05);
                      },
                      childCount: p.phases.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(Project p, bool isDark) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      elevation: 0,
      backgroundColor: p.projectColor,
      leading: const BackButton(color: Colors.white),
      actions: [
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditProjectScreen(projectId: p.id))),
          icon: const Icon(Icons.edit_rounded, color: Colors.white),
          tooltip: 'Edit Project',
        ),
        IconButton(
          onPressed: () => _deleteProject(p),
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          tooltip: 'Delete Project',
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [p.projectColor, p.projectColor.withBlue(180)],
                ),
              ),
            ),
            // Decorative circles
            Positioned(
              right: -50,
              top: -50,
              child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withValues(alpha: 0.05)),
            ),
            Positioned(
              left: -30,
              bottom: 20,
              child: CircleAvatar(radius: 60, backgroundColor: Colors.white.withValues(alpha: 0.03)),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Hero(
                    tag: 'project_emoji_${p.id}',
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                      ),
                      child: Text(p.projectEmoji, style: const TextStyle(fontSize: 48)),
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 16),
                  Text(
                    p.name, 
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: -0.5),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      p.categoryLabel.toUpperCase(), 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 1),
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleAddBottomSheet extends StatefulWidget {
  final Color accentColor;
  final bool isDark;
  final Function(String, String, double) onAdd;

  const _ModuleAddBottomSheet({required this.accentColor, required this.isDark, required this.onAdd});

  @override
  State<_ModuleAddBottomSheet> createState() => _ModuleAddBottomSheetState();
}

class _ModuleAddBottomSheetState extends State<_ModuleAddBottomSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  bool _isLoading = false;

  void _submit() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    await widget.onAdd(
      _nameCtrl.text.trim(),
      _descCtrl.text.trim(),
      double.tryParse(_priceCtrl.text) ?? 0,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
            Text('NEW MODULE', style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2)),
            Text('Roadmap Phase', style: AppTextStyles.h2(context).copyWith(fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 24),
            _ModernInputDetail(controller: _nameCtrl, hint: 'MODULE NAME', icon: Icons.folder_rounded, accentColor: widget.accentColor),
            const SizedBox(height: 12),
            _ModernInputDetail(controller: _descCtrl, hint: 'DESCRIPTION (OPTIONAL)', icon: Icons.description_rounded, accentColor: widget.accentColor),
            const SizedBox(height: 12),
            _ModernInputDetail(controller: _priceCtrl, hint: 'BUDGET / PRICE', icon: Icons.payments_rounded, accentColor: widget.accentColor, keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('CREATE MODULE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskAddBottomSheet extends StatefulWidget {
  final Color accentColor;
  final bool isDark;
  final Function(String, double, TaskPriority, List<Subtask>) onAdd;

  const _TaskAddBottomSheet({required this.accentColor, required this.isDark, required this.onAdd});

  @override
  State<_TaskAddBottomSheet> createState() => _TaskAddBottomSheetState();
}

class _TaskAddBottomSheetState extends State<_TaskAddBottomSheet> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _subtaskCtrl = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  final List<Subtask> _subtasks = [];
  bool _isLoading = false;

  void _submit() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    await widget.onAdd(
      _nameCtrl.text.trim(),
      double.tryParse(_priceCtrl.text) ?? 0,
      _priority,
      _subtasks,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NEW TASK', style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2)),
                  Text('Mission Step', style: AppTextStyles.h2(context).copyWith(fontWeight: FontWeight.w900, fontSize: 20)),
                ],
              ),
              _buildPriorityBadge(),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                _ModernInputDetail(controller: _nameCtrl, hint: 'TASK NAME', icon: Icons.assignment_rounded, accentColor: widget.accentColor),
                const SizedBox(height: 12),
                _ModernInputDetail(controller: _priceCtrl, hint: 'TASK BUDGET (OPTIONAL)', icon: Icons.payments_rounded, keyboardType: TextInputType.number, accentColor: widget.accentColor),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: widget.accentColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                      child: Text('SUBTASKS', style: TextStyle(color: widget.accentColor, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Divider(color: widget.accentColor.withValues(alpha: 0.05), thickness: 1)),
                    const SizedBox(width: 10),
                    Text('${_subtasks.length} STEPS', style: TextStyle(color: Colors.grey.shade400, fontSize: 8, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 16),
                
                Container(
                  decoration: BoxDecoration(
                    color: widget.isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: widget.isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _subtaskCtrl,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'Add a new subtask...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          ),
                          onSubmitted: (val) {
                            if (val.isNotEmpty) {
                              setState(() {
                                _subtasks.add(Subtask(id: const Uuid().v4(), taskId: '', name: val.toUpperCase(), startDate: DateTime.now(), endDate: DateTime.now()));
                                _subtaskCtrl.clear();
                              });
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_rounded, color: widget.accentColor, size: 20),
                        onPressed: () {
                          if (_subtaskCtrl.text.isNotEmpty) {
                            setState(() {
                              _subtasks.add(Subtask(id: const Uuid().v4(), taskId: '', name: _subtaskCtrl.text.toUpperCase(), startDate: DateTime.now(), endDate: DateTime.now()));
                              _subtaskCtrl.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                ..._subtasks.asMap().entries.map((entry) {
                  final i = entry.key;
                  final sub = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: widget.isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      leading: Text('${i + 1}', style: TextStyle(color: widget.accentColor.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.w900)),
                      title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      trailing: IconButton(
                        icon: Icon(Icons.close_rounded, size: 16, color: Colors.grey.withValues(alpha: 0.4)),
                        onPressed: () => setState(() => _subtasks.removeAt(i)),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.accentColor, 
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isLoading 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('CONFIRM TASK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge() {
    return PopupMenuButton<TaskPriority>(
      onSelected: (p) => setState(() => _priority = p),
      itemBuilder: (ctx) => TaskPriority.values.map((p) => PopupMenuItem(value: p, child: Text(p.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)))).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(_priority.name.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _BudgetBottomSheet extends StatefulWidget {
  final Project project;
  final FinanceRepository financeRepo;
  final Function(double total, double advance) onUpdate;

  const _BudgetBottomSheet({required this.project, required this.financeRepo, required this.onUpdate});

  @override
  State<_BudgetBottomSheet> createState() => _BudgetBottomSheetState();
}

class _BudgetBottomSheetState extends State<_BudgetBottomSheet> {
  late TextEditingController _totalCtrl;
  final _amountPaidCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _totalCtrl = TextEditingController(text: widget.project.totalPrice.toString());
  }

  void _submitUpdate() async {
    final total = double.tryParse(_totalCtrl.text) ?? 0;
    setState(() => _isLoading = true);
    await widget.onUpdate(total, widget.project.advanceAmount);
    if (mounted) setState(() => _isLoading = false);
  }

  void _recordPayment() async {
    final amount = double.tryParse(_amountPaidCtrl.text) ?? 0;
    if (amount <= 0) return;
    
    setState(() => _isLoading = true);
    final payment = Payment(
      id: const Uuid().v4(),
      projectId: widget.project.id,
      label: _labelCtrl.text.isEmpty ? 'Down Payment' : _labelCtrl.text,
      amount: amount,
      date: DateTime.now(),
      isReceived: true,
    );
    
    await widget.financeRepo.recordPayment(payment);
    
    // Also update project advance amount in parent
    final newAdvance = widget.project.advanceAmount + amount;
    await widget.onUpdate(double.tryParse(_totalCtrl.text) ?? widget.project.totalPrice, newAdvance);
    
    if (mounted) {
      _amountPaidCtrl.clear();
      _labelCtrl.clear();
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = widget.project.projectColor;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
          Text('FINANCIAL OVERVIEW', style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2)),
          Text('Budget & Payments', style: AppTextStyles.h2(context).copyWith(fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 24),
          
          _ModernInputDetail(
            controller: _totalCtrl, 
            hint: 'TOTAL PROJECT BUDGET', 
            icon: Icons.payments_rounded, 
            accentColor: accentColor, 
            keyboardType: TextInputType.number,
            onChanged: (v) => _submitUpdate(),
          ),
          
          const SizedBox(height: 24),
          Row(
            children: [
              Text('PAYMENT HISTORY', style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2)),
              const Spacer(),
              StreamBuilder<List<Payment>>(
                stream: widget.financeRepo.getPaymentsForProject(widget.project.id),
                builder: (context, snapshot) {
                  final totalPaid = snapshot.data?.fold(0.0, (sum, p) => sum + p.amount) ?? 0.0;
                  final balance = (double.tryParse(_totalCtrl.text) ?? 0) - totalPaid;
                  return Text(
                    'Balance: TSh ${NumberFormat.compact().format(balance)}',
                    style: TextStyle(color: balance > 0 ? AppColors.rose : AppColors.emerald, fontWeight: FontWeight.w900, fontSize: 10),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Expanded(
            child: StreamBuilder<List<Payment>>(
              stream: widget.financeRepo.getPaymentsForProject(widget.project.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final payments = snapshot.data!;
                if (payments.isEmpty) return Center(child: Text('No payments recorded yet', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)));
                
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final p = payments[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.emerald.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.check_rounded, color: AppColors.emerald, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                Text(DateFormat('MMM dd, yyyy').format(p.date), style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                              ],
                            ),
                          ),
                          Text('TSh ${NumberFormat.compact().format(p.amount)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.emerald)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C2128) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                _ModernInputDetail(controller: _labelCtrl, hint: 'PAYMENT LABEL (E.G. PARTIAL)', icon: Icons.label_rounded, accentColor: accentColor),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _ModernInputDetail(controller: _amountPaidCtrl, hint: 'AMOUNT', icon: Icons.add_card_rounded, accentColor: accentColor, keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _recordPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        minimumSize: const Size(60, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernInputDetail extends StatelessWidget {
  final TextEditingController controller; 
  final String hint; 
  final IconData icon; 
  final Color accentColor; 
  final TextInputType? keyboardType;
  final Function(String)? onChanged;

  const _ModernInputDetail({required this.controller, required this.hint, required this.icon, required this.accentColor, this.keyboardType, this.onChanged});
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller, 
      keyboardType: keyboardType, 
      onChanged: onChanged,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), 
      decoration: InputDecoration(
        hintText: hint, 
        prefixIcon: Icon(icon, color: accentColor, size: 18), 
        filled: true, 
        fillColor: isDark ? const Color(0xFF1C2128) : Colors.grey.shade50, 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), 
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accentColor, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      )
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  final String label; final IconData icon; final Color color; final VoidCallback onTap; final bool isDark;
  const _QuickAddButton({required this.label, required this.icon, required this.color, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          color: color.withValues(alpha: 0.04),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

class _ProjectHeaderCard extends StatelessWidget {
  final Project p;
  final bool isDark;
  final VoidCallback onBudgetTap;

  const _ProjectHeaderCard({required this.p, required this.isDark, required this.onBudgetTap});

  @override
  Widget build(BuildContext context) {
    final remaining = p.totalPrice - p.advanceAmount;
    final isFullyPaid = remaining <= 0;
    final isOverdue = remaining > 0 && p.endDate.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(label: 'MODULES', value: '${p.phases.where((ph) => ph.status == TaskStatus.done).length}/${p.phases.length}', color: p.projectColor, isDark: isDark),
              _Stat(label: 'STATUS', value: p.statusLabel, color: p.statusColor, isDark: isDark),
              InkWell(
                onTap: onBudgetTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('BUDGET', style: const TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                          const SizedBox(height: 3),
                          Text('TSh ${NumberFormat.compact().format(p.totalPrice)}', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 13)),
                          const SizedBox(height: 5),
                          if (isOverdue)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.rose.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'OVERDUE: TSh ${NumberFormat.compact().format(remaining)}',
                                style: const TextStyle(
                                  color: AppColors.rose,
                                  fontSize: 7,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            )
                          else if (!isFullyPaid)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.amber.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'BALANCE: TSh ${NumberFormat.compact().format(remaining)}',
                                style: const TextStyle(
                                  color: AppColors.amber,
                                  fontSize: 7,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.emerald.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'FULLY PAID',
                                style: TextStyle(
                                  color: AppColors.emerald,
                                  fontSize: 7,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Project Completion', style: TextStyle(color: isDark ? Colors.white38 : AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800)),
              Text('${(p.progressPercent * 100).toInt()}%', style: TextStyle(color: p.projectColor, fontSize: 13, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: p.progressPercent,
              minHeight: 10,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.surface,
              valueColor: AlwaysStoppedAnimation(p.projectColor),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}

class _Stat extends StatelessWidget {
  final String label, value; final Color color; final bool isDark;
  const _Stat({required this.label, required this.value, required this.color, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      const SizedBox(height: 3),
      Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 13)),
      const SizedBox(height: 5),
      Container(width: 15, height: 2.5, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    ]);
  }
}

class _PhaseCard extends StatefulWidget {
  final Phase phase; final bool isExpanded; final VoidCallback onTap;
  final Function(ProjectTask, Subtask, bool) onToggleSubtask;
  final Function(ProjectTask, TaskStatus) onTaskStatusChange;
  final Function(TaskStatus) onPhaseStatusChange;
  final VoidCallback onAddTask;
  final Color accentColor; final bool isDark;

  const _PhaseCard({required this.phase, required this.isExpanded, required this.onTap, required this.onToggleSubtask, required this.onTaskStatusChange, required this.onPhaseStatusChange, required this.onAddTask, required this.accentColor, required this.isDark});

  @override
  State<_PhaseCard> createState() => _PhaseCardState();
}

class _PhaseCardState extends State<_PhaseCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    if (widget.isExpanded) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(_PhaseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      widget.isExpanded ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final progress = widget.phase.progressPercent;
    final doneCount = widget.phase.tasks.where((t) => t.status == TaskStatus.done).length;
    final totalTasks = widget.phase.tasks.length;
    final statusColor = _getStatusColor(widget.phase.status, widget.isDark, widget.accentColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isExpanded ? widget.accentColor.withValues(alpha: 0.3) : (widget.isDark ? const Color(0xFF30363D) : AppColors.borderLight), 
          width: 1
        ),
        boxShadow: [
          if (!widget.isDark && widget.isExpanded) 
            BoxShadow(color: widget.accentColor.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _PhaseProgressIcon(progress: progress, color: statusColor, status: widget.phase.status),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.phase.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: widget.isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            _PhaseStatusBadge(
                              status: widget.phase.status,
                              accentColor: widget.accentColor,
                              isDark: widget.isDark,
                              onStatusChange: widget.onPhaseStatusChange,
                              doneCount: doneCount,
                              totalTasks: totalTasks,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• TSh ${NumberFormat.compact().format(widget.phase.totalPhasePrice)}',
                              style: TextStyle(
                                fontSize: 9,
                                color: widget.isDark ? Colors.white24 : Colors.grey.shade600,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    widget.isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: widget.accentColor.withValues(alpha: 0.3),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _animation,
            child: Column(
              children: [
                Divider(height: 1, color: widget.isDark ? const Color(0xFF30363D) : const Color(0xFFF1F5F9)),
                if (totalTasks == 0)
                  _buildNoTasks()
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.phase.tasks.length,
                      itemBuilder: (context, index) => _TaskTile(
                        task: widget.phase.tasks[index],
                        isDark: widget.isDark,
                        accentColor: widget.accentColor,
                        onStatusChange: (s) => widget.onTaskStatusChange(widget.phase.tasks[index], s),
                        onToggleSubtask: (sub, val) => widget.onToggleSubtask(widget.phase.tasks[index], sub, val),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: _QuickAddButtonSmall(
                    onTap: widget.onAddTask,
                    accentColor: widget.accentColor,
                    label: 'ADD MISSION STEP',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoTasks() {
    return Padding(padding: const EdgeInsets.all(20), child: Text('No steps yet', style: TextStyle(fontSize: 11, color: widget.isDark ? Colors.white12 : Colors.grey.shade400, fontWeight: FontWeight.w600)));
  }
}

class _PhaseStatusBadge extends StatelessWidget {
  final TaskStatus status;
  final Color accentColor;
  final bool isDark;
  final Function(TaskStatus) onStatusChange;
  final int doneCount, totalTasks;

  const _PhaseStatusBadge({required this.status, required this.accentColor, required this.isDark, required this.onStatusChange, required this.doneCount, required this.totalTasks});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(status, isDark, accentColor);
    
    return PopupMenuButton<TaskStatus>(
      onSelected: onStatusChange,
      offset: const Offset(0, 30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF161B22) : Colors.white,
      itemBuilder: (ctx) => TaskStatus.values.map((s) {
        final color = _getStatusColor(s, isDark, accentColor);
        return PopupMenuItem(
          value: s,
          height: 40,
          child: Row(
            children: [
              Icon(_getStatusIcon(s), color: color, size: 14),
              const SizedBox(width: 8),
              Text(
                _getStatusLabel(s),
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: isDark ? Colors.white : Colors.black87),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.08), 
          borderRadius: BorderRadius.circular(6),
        ), 
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              status == TaskStatus.todo ? 'PENDING' : (status == TaskStatus.done ? 'DONE' : '$doneCount/$totalTasks'), 
              style: TextStyle(fontSize: 8, color: statusColor, fontWeight: FontWeight.w900, letterSpacing: 0.3)
            ),
            const SizedBox(width: 1),
            Icon(Icons.arrow_drop_down_rounded, size: 12, color: statusColor),
          ],
        ),
      ),
    );
  }
}

class _QuickAddButtonSmall extends StatelessWidget {
  final VoidCallback onTap;
  final Color accentColor;
  final String label;
  const _QuickAddButtonSmall({required this.onTap, required this.accentColor, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accentColor.withValues(alpha: 0.08), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_task_rounded, size: 14, color: accentColor),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

Color _getStatusColor(TaskStatus status, bool isDark, Color accentColor) {
  return switch (status) {
    TaskStatus.done => AppColors.emerald,
    TaskStatus.inProgress => accentColor,
    TaskStatus.todo => isDark ? Colors.white24 : Colors.grey.shade400,
  };
}

IconData _getStatusIcon(TaskStatus status) {
  return switch (status) {
    TaskStatus.done => Icons.check_circle_rounded,
    TaskStatus.inProgress => Icons.timelapse_rounded,
    TaskStatus.todo => Icons.radio_button_unchecked_rounded,
  };
}

String _getStatusLabel(TaskStatus status) {
  return switch (status) {
    TaskStatus.done => 'Done',
    TaskStatus.inProgress => 'In Progress',
    TaskStatus.todo => 'To Do',
  };
}

class _PhaseProgressIcon extends StatelessWidget {
  final double progress; final Color color; final TaskStatus status;
  const _PhaseProgressIcon({required this.progress, required this.color, required this.status});
  @override
  Widget build(BuildContext context) {
    final isInactive = status == TaskStatus.todo;
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05), 
        borderRadius: BorderRadius.circular(12), 
      ),
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(width: 28, height: 28, child: CircularProgressIndicator(value: isInactive ? 0 : progress, strokeWidth: 2, backgroundColor: color.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation(color))),
        Icon(
          isInactive ? Icons.pause_rounded : (progress == 1.0 ? Icons.check_circle_rounded : Icons.inventory_2_rounded), 
          size: 14, 
          color: color
        ),
      ]),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final ProjectTask task; final bool isDark; final Color accentColor;
  final Function(TaskStatus) onStatusChange;
  final Function(Subtask, bool) onToggleSubtask;

  const _TaskTile({required this.task, required this.isDark, required this.accentColor, required this.onStatusChange, required this.onToggleSubtask});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(task.status, isDark, accentColor);
    final hasSubtasks = task.subtasks.isNotEmpty;
    final completedSubtasks = task.subtasks.where((s) => s.isDone).length;
    final isDone = task.status == TaskStatus.done;
    final isInProgress = task.status == TaskStatus.inProgress;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.01) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isInProgress ? accentColor.withValues(alpha: 0.15) : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade100),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isDone 
                        ? Icons.check_circle_rounded 
                        : (isInProgress ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded),
                      color: statusColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: isDone 
                            ? (isDark ? Colors.white24 : Colors.grey.shade400)
                            : (isDark ? Colors.white : Colors.black87),
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    _TaskStatusDropdownDetail(
                      currentStatus: task.status,
                      isDark: isDark,
                      accentColor: accentColor,
                      onStatusChange: onStatusChange,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _PriorityBadgeDetail(priority: task.priority),
                    if (task.price > 0) ...[
                      const SizedBox(width: 6),
                      _PriceBadgeDetail(price: task.price),
                    ],
                    if (hasSubtasks) ...[
                      const SizedBox(width: 6),
                      Text(
                        '$completedSubtasks/${task.subtasks.length} STEPS',
                        style: TextStyle(fontSize: 7, color: accentColor.withValues(alpha: 0.6), fontWeight: FontWeight.w900),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (hasSubtasks)
            _SubtaskListDetail(
              subtasks: task.subtasks,
              isDark: isDark,
              onToggle: onToggleSubtask,
            ),
        ],
      ),
    );
  }
}

class _TaskStatusDropdownDetail extends StatelessWidget {
  final TaskStatus currentStatus;
  final bool isDark;
  final Color accentColor;
  final Function(TaskStatus) onStatusChange;

  const _TaskStatusDropdownDetail({
    required this.currentStatus,
    required this.isDark,
    required this.accentColor,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(currentStatus, isDark, accentColor);
    
    return PopupMenuButton<TaskStatus>(
      onSelected: onStatusChange,
      offset: const Offset(0, 25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF161B22) : Colors.white,
      itemBuilder: (ctx) => TaskStatus.values.map((s) {
        final color = _getStatusColor(s, isDark, accentColor);
        return PopupMenuItem(
          value: s,
          height: 35,
          child: Row(
            children: [
              Icon(_getStatusIcon(s), color: color, size: 14),
              const SizedBox(width: 8),
              Text(
                _getStatusLabel(s),
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: isDark ? Colors.white : Colors.black87),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getStatusLabel(currentStatus).toUpperCase(),
              style: TextStyle(fontSize: 7.5, color: statusColor, fontWeight: FontWeight.w900),
            ),
            Icon(Icons.arrow_drop_down_rounded, size: 12, color: statusColor),
          ],
        ),
      ),
    );
  }
}

class _PriceBadgeDetail extends StatelessWidget {
  final double price;
  const _PriceBadgeDetail({required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.emerald.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        'TSh ${NumberFormat.compact().format(price)}',
        style: const TextStyle(fontSize: 7.5, color: AppColors.emerald, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _SubtaskListDetail extends StatelessWidget {
  final List<Subtask> subtasks;
  final bool isDark;
  final Function(Subtask, bool) onToggle;

  const _SubtaskListDetail({required this.subtasks, required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Column(
        children: [
          Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade100),
          const SizedBox(height: 6),
          ...subtasks.map((sub) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: InkWell(
              onTap: () => onToggle(sub, !sub.isDone),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      sub.isDone ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                      size: 13,
                      color: sub.isDone ? AppColors.emerald : (isDark ? Colors.white10 : Colors.grey.shade300),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sub.name,
                        style: TextStyle(
                          fontSize: 10,
                          color: sub.isDone 
                            ? (isDark ? Colors.white24 : Colors.grey.shade400) 
                            : (isDark ? Colors.white70 : Colors.black87),
                          decoration: sub.isDone ? TextDecoration.lineThrough : null,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class _PriorityBadgeDetail extends StatelessWidget {
  final TaskPriority priority;
  const _PriorityBadgeDetail({required this.priority});
  
  @override
  Widget build(BuildContext context) {
    final color = switch (priority) { 
      TaskPriority.critical => AppColors.purple, 
      TaskPriority.high => AppColors.rose, 
      TaskPriority.medium => AppColors.amber, 
      TaskPriority.low => AppColors.emerald 
    };
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        priority.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 7.5, fontWeight: FontWeight.w900),
      ),
    );
  }
}
