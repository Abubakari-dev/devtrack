import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import 'package:devtrack/features/projects/models/models.dart';
import '../data/project_repository.dart';

import '../../../core/localization/app_localizations.dart';

class AddEditProjectScreen extends StatefulWidget {
  final String? projectId;

  const AddEditProjectScreen({super.key, this.projectId});

  @override
  State<AddEditProjectScreen> createState() => _AddEditProjectScreenState();
}

class _AddEditProjectScreenState extends State<AddEditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProjectRepository _projectRepo = ProjectRepository();

  int _currentStep = 0;
  bool _isLoading = false;
  Project? _existingProject;

  // Step 1: Identity
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  ProjectCategory _category = ProjectCategory.mobile;
  ProjectStatus _status = ProjectStatus.active;
  TaskPriority _projectPriority = TaskPriority.medium;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  String _projectEmoji = '🚀';
  Color _projectColor = AppColors.indigo;

  List<Phase> _phases = [];

  final List<String> _emojis = ['🚀', '📱', '🌐', '💻', '🎨', '⚙️', '📊', '🛍️', '🏥', '🏠', '⚡', '💡', '🎯', '🛠️', '🔒', '📦', '🏆', '🔥'];
  final List<Color> _colors = [
    AppColors.indigo, AppColors.blue, AppColors.emerald, 
    AppColors.amber, AppColors.rose, Colors.black, 
    Colors.deepPurple, Colors.teal, Colors.orange, Colors.pink
  ];

  @override
  void initState() {
    super.initState();
    if (widget.projectId != null) {
      _loadProjectData();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProjectData() async {
    setState(() => _isLoading = true);
    try {
      final project = await _projectRepo.getProject(widget.projectId!);
      if (project != null && mounted) {
        setState(() {
          _existingProject = project;
          _nameCtrl.text = project.name;
          _descCtrl.text = project.description ?? '';
          _category = project.category;
          _status = project.status;
          _projectPriority = project.priority;
          _startDate = project.startDate;
          _endDate = project.endDate;
          _projectEmoji = project.projectEmoji;
          _projectColor = project.projectColor;
          _priceCtrl.text = project.totalPrice == 0 ? '' : NumberFormat('#,###').format(project.totalPrice / 100.0);
          _phases = List.from(project.phases);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        HapticFeedback.mediumImpact();
        setState(() => _currentStep++);
      }
    } else if (_currentStep < 2) {
      HapticFeedback.mediumImpact();
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      setState(() => _currentStep--);
    }
  }

  void _addOrEditPhase({Phase? existingPhase, int? index}) {
    final nameCtrl = TextEditingController(text: existingPhase?.name);
    final descCtrl = TextEditingController(text: existingPhase?.description);
    TaskStatus phaseStatus = existingPhase?.status ?? TaskStatus.todo;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSTState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32))
          ),
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(existingPhase == null ? context.tr('new_module') : context.tr('edit_module'), 
                      style: AppTextStyles.h2.copyWith(color: _projectColor, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    if (existingPhase != null)
                      _buildPopupStatusSelector<TaskStatus>(
                        current: phaseStatus,
                        values: TaskStatus.values,
                        onChanged: (v) => setSTState(() => phaseStatus = v),
                        isDark: Theme.of(context).brightness == Brightness.dark,
                        context: context,
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                _ModernInput(controller: nameCtrl, hint: context.tr('module_name'), icon: Icons.folder_rounded, accentColor: _projectColor),
                const SizedBox(height: 16),
                _ModernInput(controller: descCtrl, hint: context.tr('description_optional'), icon: Icons.description_rounded, accentColor: _projectColor),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.isNotEmpty) {
                      setState(() {
                        final newPhase = (existingPhase ?? Phase(
                          id: const Uuid().v4(),
                          projectId: widget.projectId ?? '',
                          name: '',
                          startDate: _startDate,
                          endDate: _endDate,
                          orderIndex: _phases.length,
                          status: phaseStatus,
                        )).copyWith(
                          name: nameCtrl.text.toUpperCase(),
                          description: descCtrl.text.isEmpty ? null : descCtrl.text,
                          price: 0,
                          status: phaseStatus,
                        );

                        if (index != null) {
                          _phases[index] = newPhase;
                        } else {
                          _phases.add(newPhase);
                        }
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _projectColor, 
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(existingPhase == null ? context.tr('add_module') : context.tr('update_module'), 
                    style: AppTextStyles.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addOrEditTask(int phaseIndex, {ProjectTask? existingTask, int? taskIndex}) {
    final nameCtrl = TextEditingController(text: existingTask?.name);
    TaskPriority priority = existingTask?.priority ?? TaskPriority.medium;
    TaskStatus taskStatus = existingTask?.status ?? TaskStatus.todo;
    List<Subtask> tempSubtasks = List.from(existingTask?.subtasks ?? []);
    final subtaskCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSTState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF161B22) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              )
            ],
          ),
          padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          existingTask == null ? context.tr('create_mission') : context.tr('edit_mission'), 
                          style: AppTextStyles.labelSmall.copyWith(
                            color: _projectColor, 
                            fontWeight: FontWeight.w900, 
                            fontSize: 10, 
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          existingTask == null ? context.tr('new_task') : context.tr('edit_task'), 
                          style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w900, fontSize: 24),
                        ),
                      ],
                    ),
                  ),
                  _buildPopupStatusSelector<TaskStatus>(
                    current: taskStatus,
                    values: TaskStatus.values,
                    onChanged: (v) => setSTState(() => taskStatus = v),
                    isDark: Theme.of(context).brightness == Brightness.dark,
                    context: context,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _ModernInput(
                      controller: nameCtrl, 
                      hint: context.tr('task_name'), 
                      icon: Icons.assignment_rounded, 
                      accentColor: _projectColor,
                    ),
                    const SizedBox(height: 24),
                    
                    _buildPopupPrioritySelector(
                      current: priority,
                      onChanged: (v) => setSTState(() => priority = v),
                      isDark: Theme.of(context).brightness == Brightness.dark,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _projectColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            context.tr('subtasks').toUpperCase(), 
                            style: AppTextStyles.labelSmall.copyWith(
                              color: _projectColor, 
                              fontSize: 9, 
                              fontWeight: FontWeight.w900, 
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Divider(color: _projectColor.withValues(alpha: 0.1), thickness: 1)),
                        const SizedBox(width: 12),
                        Text(
                          '${tempSubtasks.length} ${context.tr('items')}', 
                          style: TextStyle(
                            color: Colors.grey.shade400, 
                            fontSize: 10, 
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white.withValues(alpha: 0.03) 
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white.withValues(alpha: 0.08) 
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: subtaskCtrl,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: context.tr('add_new_step'),
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                              ),
                              onSubmitted: (val) {
                                if (val.isNotEmpty) {
                                  setSTState(() {
                                    tempSubtasks.add(Subtask(
                                      id: const Uuid().v4(),
                                      taskId: existingTask?.id ?? '',
                                      name: val.toUpperCase(),
                                      startDate: DateTime.now(),
                                      endDate: DateTime.now(),
                                    ));
                                    subtaskCtrl.clear();
                                  });
                                }
                              },
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _projectColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                              onPressed: () {
                                if (subtaskCtrl.text.isNotEmpty) {
                                  setSTState(() {
                                    tempSubtasks.add(Subtask(
                                      id: const Uuid().v4(),
                                      taskId: existingTask?.id ?? '',
                                      name: subtaskCtrl.text.toUpperCase(),
                                      startDate: DateTime.now(),
                                      endDate: DateTime.now(),
                                    ));
                                    subtaskCtrl.clear();
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (tempSubtasks.isNotEmpty)
                      ...tempSubtasks.asMap().entries.map((entry) {
                        final i = entry.key;
                        final sub = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white.withValues(alpha: 0.01) 
                                : Colors.white,
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.white.withValues(alpha: 0.05) 
                                  : Colors.grey.shade100,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: _projectColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}', 
                                  style: TextStyle(
                                    color: _projectColor, 
                                    fontSize: 11, 
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              sub.name, 
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.3),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.remove_circle_outline_rounded, size: 20, color: Colors.grey.withValues(alpha: 0.4)),
                              onPressed: () => setSTState(() => tempSubtasks.removeAt(i)),
                            ),
                          ),
                        );
                      })
                    else 
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          children: [
                            Icon(Icons.checklist_rtl_rounded, size: 56, color: Colors.grey.withValues(alpha: 0.1)),
                            const SizedBox(height: 16),
                            Text(
                              context.tr('no_steps_defined'), 
                              style: TextStyle(
                                color: Colors.grey.withValues(alpha: 0.4), 
                                fontSize: 13, 
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty) {
                    setState(() {
                      final phase = _phases[phaseIndex];
                      final newTask = (existingTask ?? ProjectTask(
                        id: const Uuid().v4(),
                        phaseId: phase.id,
                        name: '',
                        priority: priority,
                        startDate: phase.startDate,
                        endDate: phase.endDate,
                        status: taskStatus,
                      )).copyWith(
                        name: nameCtrl.text.toUpperCase(),
                        priority: priority,
                        status: taskStatus,
                        price: 0,
                        subtasks: tempSubtasks,
                      );

                      final updatedTasks = List<ProjectTask>.from(phase.tasks);
                      if (taskIndex != null) {
                        updatedTasks[taskIndex] = newTask;
                      } else {
                        updatedTasks.add(newTask);
                      }
                      _phases[phaseIndex] = phase.copyWith(tasks: updatedTasks);
                    });
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _projectColor, 
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 8,
                  shadowColor: _projectColor.withValues(alpha: 0.3),
                ),
                child: Text(
                  context.tr('confirm_task').toUpperCase(), 
                  style: const TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: 1.5,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopupPrioritySelector({
    required TaskPriority current, 
    required ValueChanged<TaskPriority> onChanged, 
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('priority').toUpperCase(), 
          style: TextStyle(
            color: Colors.grey, 
            fontSize: 10, 
            fontWeight: FontWeight.w900, 
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: TaskPriority.values.map((p) {
            final isSelected = current == p;
            final color = _getPriorityColor(p);
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? color : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _getPriorityLabel(context, p),
                    style: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white38 : Colors.grey),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getPriorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.critical: return AppColors.rose;
      case TaskPriority.high: return Colors.orange;
      case TaskPriority.medium: return AppColors.indigo;
      case TaskPriority.low: return AppColors.emerald;
    }
  }

  Future<void> _saveProject() async {
    setState(() => _isLoading = true);
    
    final project = (_existingProject ?? Project(
      id: const Uuid().v4(),
      name: '',
      category: _category,
      status: _status,
      totalPrice: 0,
      advanceAmount: 0,
      startDate: _startDate,
      endDate: _endDate,
      createdAt: DateTime.now(),
    )).copyWith(
      name: _nameCtrl.text.trim().toUpperCase(),
      description: _descCtrl.text.isEmpty ? null : _descCtrl.text,
      category: _category,
      status: _status,
      totalPrice: (CurrencyInputFormatter.parse(_priceCtrl.text) * 100).round().toDouble(),
      startDate: _startDate,
      endDate: _endDate,
      priority: _projectPriority,
      projectEmoji: _projectEmoji,
      projectColor: _projectColor,
      phases: _phases,
    );

    try {
      await _projectRepo.saveProject(project);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : AppColors.bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : Colors.black87), onPressed: () => Navigator.pop(context)),
        title: Text(widget.projectId == null ? context.tr('new_mission') : context.tr('update_project'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(4), child: _buildStepIndicator()),
      ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                _buildStep1(isDark).animate().fadeIn().slideX(begin: 0.05), 
                _buildStep2(isDark).animate().fadeIn().slideX(begin: 0.05), 
                _buildStep3(isDark).animate().fadeIn().slideX(begin: 0.05)
              ],
            ),
          ),
          _buildBottomNav(isDark),
        ],
      ),
    );
  }

  Widget _buildStep1(bool isDark) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildVisualSelector(isDark),
          const SizedBox(height: 32),
          _ModernInput(controller: _nameCtrl, hint: context.tr('project_name'), icon: Icons.rocket_launch_rounded, accentColor: _projectColor, validator: (v) => v!.isEmpty ? context.tr('name_required_error') : null),
          const SizedBox(height: 16),
          _ModernInput(controller: _descCtrl, hint: context.tr('description_optional'), icon: Icons.description_rounded, accentColor: _projectColor),
          const SizedBox(height: 16),
          _ModernInput(
            controller: _priceCtrl, 
            hint: context.tr('total_project_budget'), 
            icon: Icons.payments_rounded, 
            accentColor: _projectColor, 
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
          ),
          const SizedBox(height: 24),
          _buildDateRow(isDark),
          const SizedBox(height: 32),
          _buildDropdown<ProjectCategory>(label: context.tr('category'), value: _category, items: ProjectCategory.values, onChanged: (v) => setState(() => _category = v!), isDark: isDark, context: context),
          const SizedBox(height: 16),
          _buildDropdown<TaskPriority>(label: context.tr('priority'), value: _projectPriority, items: TaskPriority.values, onChanged: (v) => setState(() => _projectPriority = v!), isDark: isDark, context: context),
        ],
      ),
    );
  }

  Widget _buildStep2(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(context.tr('roadmap_modules'), isDark),
            IconButton.filledTonal(onPressed: () => _addOrEditPhase(), icon: const Icon(Icons.add_rounded), style: IconButton.styleFrom(backgroundColor: _projectColor.withValues(alpha: 0.1), foregroundColor: _projectColor)),
          ],
        ),
        const SizedBox(height: 16),
        if (_phases.isEmpty) 
          _buildEmptyRoadmap(isDark)
        else
          ..._phases.asMap().entries.map((e) => _buildPhaseItem(e.key, e.value, isDark)),
      ],
    );
  }

  Widget _buildEmptyRoadmap(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(children: [Icon(Icons.layers_outlined, size: 64, color: isDark ? Colors.white10 : Colors.grey.shade200), const SizedBox(height: 16), Text(context.tr('no_modules_added'), style: TextStyle(color: isDark ? Colors.white38 : Colors.grey))]),
    );
  }

  Widget _buildPhaseItem(int index, Phase phase, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white, 
        borderRadius: BorderRadius.circular(28), 
        border: Border.all(
          color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
        ],
      ),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _projectColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.inventory_2_rounded, color: _projectColor, size: 22),
        ),
        title: Text(
          phase.name, 
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.2),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _projectColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${phase.tasks.length} ${context.tr('tasks')}', 
                style: TextStyle(color: _projectColor, fontSize: 10, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        children: [
          Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100),
          ...phase.tasks.asMap().entries.map((t) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(t.value.priority).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.task_alt_rounded, size: 18, color: _getPriorityColor(t.value.priority)),
                  ),
                  title: Text(
                    t.value.name,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  subtitle: Text(
                    _getPriorityLabel(context, t.value.priority),
                    style: TextStyle(
                      color: _getPriorityColor(t.value.priority), 
                      fontSize: 9, 
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20), 
                        onPressed: () => _addOrEditTask(index, existingTask: t.value, taskIndex: t.key),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.rose),
                        onPressed: () => setState(() => _phases[index].tasks.removeAt(t.key)),
                      ),
                    ],
                  ),
                  onTap: () => _addOrEditTask(index, existingTask: t.value, taskIndex: t.key),
                ),
                if (t.value.subtasks.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(60, 0, 16, 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: t.value.subtasks.map((st) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.subdirectory_arrow_right_rounded, size: 10, color: _projectColor.withValues(alpha: 0.5)),
                            const SizedBox(width: 6),
                            Text(
                              st.name, 
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.black54, 
                                fontSize: 10, 
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
              ],
            ),
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _addOrEditTask(index), 
                  icon: const Icon(Icons.add_task_rounded, size: 18), 
                  label: Text(context.tr('add_task').toUpperCase()), 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _projectColor.withValues(alpha: 0.1),
                    foregroundColor: _projectColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                  ),
                ),
                const Spacer(),
                IconButton.filledTonal(
                  icon: const Icon(Icons.edit_rounded, size: 20), 
                  onPressed: () => _addOrEditPhase(existingPhase: phase, index: index),
                  style: IconButton.styleFrom(backgroundColor: Colors.blue.withValues(alpha: 0.1), foregroundColor: Colors.blue),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20), 
                  onPressed: () => setState(() => _phases.removeAt(index)),
                  style: IconButton.styleFrom(backgroundColor: AppColors.rose.withValues(alpha: 0.1), foregroundColor: AppColors.rose),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(bool isDark) {
    final total = CurrencyInputFormatter.parse(_priceCtrl.text);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader(context.tr('final_review'), isDark),
        const SizedBox(height: 24),
        _buildReviewCard(icon: Icons.rocket_launch_rounded, label: context.tr('mission'), title: _nameCtrl.text, subtitle: _category.name.toUpperCase(), isDark: isDark),
        const SizedBox(height: 16),
        _buildReviewCard(icon: Icons.payments_rounded, label: context.tr('budget').toUpperCase(), title: 'TSh ${NumberFormat('#,###').format(total)}', subtitle: '${_phases.length} ${context.tr('modules_label')}', isDark: isDark, color: AppColors.emerald),
        const SizedBox(height: 16),
        _buildReviewCard(icon: Icons.event_rounded, label: context.tr('timeline'), title: '${DateFormat('MMM dd', Localizations.localeOf(context).toString()).format(_startDate)} - ${DateFormat('MMM dd', Localizations.localeOf(context).toString()).format(_endDate)}', subtitle: '${_endDate.difference(_startDate).inDays} ${context.tr('days')}', isDark: isDark, color: AppColors.amber),
      ],
    );
  }

  Widget _buildReviewCard({required IconData icon, required String label, required String title, required String subtitle, required bool isDark, Color? color}) {
    final accent = color ?? _projectColor;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF161B22) : Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: accent)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: accent, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF161B22) : Colors.white, border: Border(top: BorderSide(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight))),
      child: Row(
        children: [
          if (_currentStep > 0) Expanded(child: TextButton(onPressed: _prevStep, child: Text(context.tr('back').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900)))),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: ElevatedButton(onPressed: _currentStep == 2 ? _saveProject : _nextStep, style: ElevatedButton.styleFrom(backgroundColor: _projectColor, minimumSize: const Size(0, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_currentStep == 2 ? context.tr('save_project') : context.tr('continue').toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)))),
        ],
      ),
    );
  }

  Widget _buildVisualSelector(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _colors.map((c) => GestureDetector(
          onTap: () => setState(() => _projectColor = c), 
          child: AnimatedContainer(
            duration: 200.ms, 
            width: 44, 
            height: 44, 
            margin: const EdgeInsets.only(right: 16), 
            decoration: BoxDecoration(
              color: c, 
              shape: BoxShape.circle, 
              border: _projectColor == c 
                  ? Border.all(color: isDark ? Colors.white : Colors.black, width: 3) 
                  : null,
              boxShadow: [
                if (_projectColor == c)
                  BoxShadow(
                    color: c.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(context: context, builder: (ctx) => GridView.builder(padding: const EdgeInsets.all(24), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing: 16, crossAxisSpacing: 16), itemCount: _emojis.length, itemBuilder: (ctx, i) => GestureDetector(onTap: () { setState(() => _projectEmoji = _emojis[i]); Navigator.pop(ctx); }, child: Center(child: Text(_emojis[i], style: const TextStyle(fontSize: 24))))));
  }

  Widget _buildDateRow(bool isDark) {
    return Row(
      children: [
        Expanded(child: _DateTile(label: context.tr('start'), date: _startDate, isDark: isDark, color: _projectColor, onTap: () async { final d = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2020), lastDate: DateTime(2030)); if (d != null) setState(() => _startDate = d); })),
        const SizedBox(width: 16),
        Expanded(child: _DateTile(label: context.tr('deadline'), date: _endDate, isDark: isDark, color: _projectColor, onTap: () async { final d = await showDatePicker(context: context, initialDate: _endDate, firstDate: DateTime(2020), lastDate: DateTime(2030)); if (d != null) setState(() => _endDate = d); })),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(children: List.generate(3, (i) => Expanded(child: Container(height: 4, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: _currentStep >= i ? _projectColor : _projectColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2))))));
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(title, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 10));
  }

  Widget _buildDropdown<T extends Enum>({required String label, required T value, required List<T> items, required ValueChanged<T?> onChanged, required bool isDark, required BuildContext context}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey)),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: isDark ? const Color(0xFF161B22) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight)), child: DropdownButtonHideUnderline(child: DropdownButton<T>(value: value, items: items.map((e) {
        String label = e.name.toUpperCase();
        if (e is ProjectCategory) {
          label = _getCategoryLabel(context, e);
        } else if (e is TaskPriority) {
          label = _getPriorityLabel(context, e);
        }
        return DropdownMenuItem(value: e, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)));
      }).toList(), onChanged: onChanged, isExpanded: true))),
    ]);
  }

  Widget _buildPopupStatusSelector<T extends Enum>({required T current, required List<T> values, required ValueChanged<T> onChanged, required bool isDark, required BuildContext context}) {
    return PopupMenuButton<T>(onSelected: onChanged, itemBuilder: (ctx) => values.map((s) {
      String label = s.name.toUpperCase();
      if (s is TaskStatus) {
        label = _getStatusLabel(context, s);
      }
      return PopupMenuItem(value: s, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)));
    }).toList(), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)), child: Text((current is TaskStatus ? _getStatusLabel(context, current as TaskStatus) : current.name).toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900))));
  }

  String _getCategoryLabel(BuildContext context, ProjectCategory cat) {
    return switch (cat) {
      ProjectCategory.mobile => context.tr('cat_mobile'),
      ProjectCategory.website => context.tr('cat_website'),
      ProjectCategory.desktop => context.tr('cat_desktop'),
      ProjectCategory.other => context.tr('cat_other'),
    }.toUpperCase();
  }

  String _getPriorityLabel(BuildContext context, TaskPriority p) {
    return switch (p) {
      TaskPriority.critical => context.tr('priority_critical'),
      TaskPriority.high => context.tr('priority_high'),
      TaskPriority.medium => context.tr('priority_medium'),
      TaskPriority.low => context.tr('priority_low'),
    }.toUpperCase();
  }

  String _getStatusLabel(BuildContext context, TaskStatus s) {
    return switch (s) {
      TaskStatus.done => context.tr('status_done'),
      TaskStatus.inProgress => context.tr('status_in_progress'),
      TaskStatus.todo => context.tr('status_todo'),
    }.toUpperCase();
  }
}

class _DateTile extends StatelessWidget {
  final String label; final DateTime date; final VoidCallback onTap; final bool isDark; final Color color;
  const _DateTile({required this.label, required this.date, required this.onTap, required this.isDark, required this.color});
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isDark ? const Color(0xFF161B22) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(DateFormat('dd MMM').format(date), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14))])));
  }
}

class _ModernInput extends StatelessWidget {
  final TextEditingController controller; 
  final String hint; 
  final IconData icon; 
  final Color accentColor; 
  final String? Function(String?)? validator; 
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _ModernInput({
    required this.controller, 
    required this.hint, 
    required this.icon, 
    required this.accentColor, 
    this.validator, 
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller, 
      validator: validator, 
      keyboardType: keyboardType, 
      inputFormatters: inputFormatters,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), 
      decoration: InputDecoration(
        hintText: hint, 
        prefixIcon: Icon(icon, color: accentColor, size: 20), 
        filled: true, 
        fillColor: isDark ? const Color(0xFF161B22) : Colors.white, 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight)), 
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: accentColor, width: 2))
      )
    );
  }
}
