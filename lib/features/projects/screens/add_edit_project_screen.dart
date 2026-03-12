import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/project_model.dart';
import '../data/project_repository.dart';

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
    final priceCtrl = TextEditingController(text: existingPhase?.price == 0 ? '' : existingPhase?.price.toString());
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
                    Text(existingPhase == null ? 'New Module' : 'Edit Module', 
                      style: AppTextStyles.h2(context).copyWith(color: _projectColor, fontWeight: FontWeight.w900)),
                    if (existingPhase != null)
                      _buildPopupStatusSelector<TaskStatus>(
                        current: phaseStatus,
                        values: TaskStatus.values,
                        onChanged: (v) => setSTState(() => phaseStatus = v),
                        isDark: Theme.of(context).brightness == Brightness.dark,
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                _ModernInput(controller: nameCtrl, hint: 'MODULE NAME', icon: Icons.folder_rounded, accentColor: _projectColor),
                const SizedBox(height: 16),
                _ModernInput(controller: descCtrl, hint: 'DESCRIPTION (OPTIONAL)', icon: Icons.description_rounded, accentColor: _projectColor),
                const SizedBox(height: 16),
                _ModernInput(controller: priceCtrl, hint: 'PRICE', icon: Icons.payments_rounded, keyboardType: TextInputType.number, accentColor: _projectColor),
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
                          price: double.tryParse(priceCtrl.text) ?? 0,
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
                  child: Text(existingPhase == null ? 'ADD MODULE' : 'UPDATE MODULE', 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
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
    final priceCtrl = TextEditingController(text: existingTask?.price == 0 ? '' : existingTask?.price.toString());
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
            color: Theme.of(context).scaffoldBackgroundColor, 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32))
          ),
          padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(existingTask == null ? 'CREATE MISSION' : 'EDIT MISSION', 
                        style: TextStyle(color: _projectColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2)),
                      Text(existingTask == null ? 'New Task' : 'Edit Task', 
                        style: AppTextStyles.h2(context).copyWith(fontWeight: FontWeight.w900)),
                    ],
                  ),
                  _buildPopupStatusSelector<TaskStatus>(
                    current: taskStatus,
                    values: TaskStatus.values,
                    onChanged: (v) => setSTState(() => taskStatus = v),
                    isDark: Theme.of(context).brightness == Brightness.dark,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _ModernInput(controller: nameCtrl, hint: 'TASK NAME', icon: Icons.assignment_rounded, accentColor: _projectColor),
                    const SizedBox(height: 16),
                    _ModernInput(controller: priceCtrl, hint: 'TASK BUDGET (OPTIONAL)', icon: Icons.payments_rounded, keyboardType: TextInputType.number, accentColor: _projectColor),
                    const SizedBox(height: 32),
                    
                    // SUBTASK SECTION HEADER
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _projectColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('SUBTASKS', style: TextStyle(color: _projectColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Divider(color: _projectColor.withOpacity(0.1), thickness: 1)),
                        const SizedBox(width: 12),
                        Text('${tempSubtasks.length} ITEMS', style: TextStyle(color: Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // ADD SUBTASK INPUT (CLEANER)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.02) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: subtaskCtrl,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: 'Add a new step...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
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
                          IconButton(
                            icon: Icon(Icons.add_rounded, color: _projectColor),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // SUBTASK LIST (CLEAN, NO BACKGROUND CARD)
                    if (tempSubtasks.isNotEmpty)
                      ...tempSubtasks.asMap().entries.map((entry) {
                        final i = entry.key;
                        final sub = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            leading: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: _projectColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(child: Text('${i + 1}', style: TextStyle(color: _projectColor, fontSize: 10, fontWeight: FontWeight.w900))),
                            ),
                            title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.3)),
                            trailing: IconButton(
                              icon: Icon(Icons.remove_circle_outline_rounded, size: 18, color: Colors.grey.withOpacity(0.5)),
                              onPressed: () => setSTState(() => tempSubtasks.removeAt(i)),
                            ),
                          ),
                        );
                      }).toList()
                    else 
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(Icons.add_task_rounded, size: 40, color: Colors.grey.withOpacity(0.1)),
                            const SizedBox(height: 12),
                            Text('No steps defined for this task', style: TextStyle(color: Colors.grey.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w500)),
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
                        price: double.tryParse(priceCtrl.text) ?? 0,
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
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Text('CONFIRM TASK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ],
          ),
        ),
      ),
    );
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
      startDate: _startDate,
      endDate: _endDate,
      priority: _projectPriority,
      projectEmoji: _projectEmoji,
      projectColor: _projectColor,
      phases: _phases,
    );

    final finalProject = project.copyWith(
      totalPrice: project.calculateTotalPriceFromTasks(),
    );

    try {
      await _projectRepo.saveProject(finalProject);
      if (mounted) Navigator.pop(context);
    } catch (e) {
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
        title: Text(widget.projectId == null ? 'NEW MISSION' : 'UPDATE PROJECT', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
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
          _ModernInput(controller: _nameCtrl, hint: 'PROJECT NAME', icon: Icons.rocket_launch_rounded, accentColor: _projectColor, validator: (v) => v!.isEmpty ? 'Name required' : null),
          const SizedBox(height: 16),
          _ModernInput(controller: _descCtrl, hint: 'DESCRIPTION (OPTIONAL)', icon: Icons.description_rounded, accentColor: _projectColor),
          const SizedBox(height: 24),
          _buildDateRow(isDark),
          const SizedBox(height: 32),
          _buildDropdown<ProjectCategory>(label: 'CATEGORY', value: _category, items: ProjectCategory.values, onChanged: (v) => setState(() => _category = v!), isDark: isDark),
          const SizedBox(height: 16),
          _buildDropdown<TaskPriority>(label: 'PRIORITY', value: _projectPriority, items: TaskPriority.values, onChanged: (v) => setState(() => _projectPriority = v!), isDark: isDark),
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
            _buildSectionHeader('ROADMAP MODULES', isDark),
            IconButton.filledTonal(onPressed: () => _addOrEditPhase(), icon: const Icon(Icons.add_rounded), style: IconButton.styleFrom(backgroundColor: _projectColor.withOpacity(0.1), foregroundColor: _projectColor)),
          ],
        ),
        const SizedBox(height: 16),
        if (_phases.isEmpty) 
          _buildEmptyRoadmap(isDark)
        else
          ..._phases.asMap().entries.map((e) => _buildPhaseItem(e.key, e.value, isDark)).toList(),
      ],
    );
  }

  Widget _buildEmptyRoadmap(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(children: [Icon(Icons.layers_outlined, size: 64, color: isDark ? Colors.white10 : Colors.grey.shade200), const SizedBox(height: 16), Text('No modules added yet', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey))]),
    );
  }

  Widget _buildPhaseItem(int index, Phase phase, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF161B22) : Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight)),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(backgroundColor: _projectColor.withOpacity(0.1), child: Icon(Icons.inventory_2_rounded, color: _projectColor, size: 20)),
        title: Text(phase.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
        subtitle: Text('TSh ${NumberFormat.compact().format(phase.totalPhasePrice)} • ${phase.tasks.length} tasks', style: TextStyle(color: _projectColor, fontSize: 11, fontWeight: FontWeight.w700)),
        children: [
          ...phase.tasks.asMap().entries.map((t) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _projectColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.task_alt_rounded, size: 18, color: _projectColor),
                  ),
                  title: Text(
                    t.value.name,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _addOrEditTask(index, existingTask: t.value, taskIndex: t.key)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.rose),
                        onPressed: () => setState(() => _phases[index].tasks.removeAt(t.key)),
                      ),
                    ],
                  ),
                  onTap: () => _addOrEditTask(index, existingTask: t.value, taskIndex: t.key),
                ),
                if (t.value.subtasks.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(52, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: t.value.subtasks.map((st) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.subdirectory_arrow_right_rounded, size: 12, color: _projectColor.withOpacity(0.4)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(st.name, style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w500))),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
              ],
            ),
          )).toList(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                TextButton.icon(onPressed: () => _addOrEditTask(index), icon: const Icon(Icons.add_task_rounded, size: 18), label: const Text('ADD TASK'), style: TextButton.styleFrom(foregroundColor: _projectColor, textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                const Spacer(),
                IconButton(icon: const Icon(Icons.edit_rounded, size: 18), onPressed: () => _addOrEditPhase(existingPhase: phase, index: index)),
                IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.rose), onPressed: () => setState(() => _phases.removeAt(index))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(bool isDark) {
    final total = _phases.fold(0.0, (sum, p) => sum + p.totalPhasePrice);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader('FINAL REVIEW', isDark),
        const SizedBox(height: 24),
        _buildReviewCard(icon: Icons.rocket_launch_rounded, label: 'MISSION', title: _nameCtrl.text, subtitle: _category.name.toUpperCase(), isDark: isDark),
        const SizedBox(height: 16),
        _buildReviewCard(icon: Icons.payments_rounded, label: 'BUDGET', title: 'TSh ${NumberFormat('#,###').format(total)}', subtitle: '${_phases.length} Modules', isDark: isDark, color: AppColors.emerald),
        const SizedBox(height: 16),
        _buildReviewCard(icon: Icons.event_rounded, label: 'TIMELINE', title: '${DateFormat('MMM dd').format(_startDate)} - ${DateFormat('MMM dd').format(_endDate)}', subtitle: '${_endDate.difference(_startDate).inDays} Days', isDark: isDark, color: AppColors.amber),
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
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: accent)),
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
          if (_currentStep > 0) Expanded(child: TextButton(onPressed: _prevStep, child: const Text('BACK', style: TextStyle(fontWeight: FontWeight.w900)))),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: ElevatedButton(onPressed: _currentStep == 2 ? _saveProject : _nextStep, style: ElevatedButton.styleFrom(backgroundColor: _projectColor, minimumSize: const Size(0, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_currentStep == 2 ? 'SAVE PROJECT' : 'CONTINUE', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)))),
        ],
      ),
    );
  }

  Widget _buildVisualSelector(bool isDark) {
    return Row(
      children: [
        GestureDetector(onTap: _showEmojiPicker, child: Container(width: 64, height: 64, decoration: BoxDecoration(color: _projectColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: _projectColor, width: 2)), child: Center(child: Text(_projectEmoji, style: const TextStyle(fontSize: 28))))),
        const SizedBox(width: 16),
        Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _colors.map((c) => GestureDetector(onTap: () => setState(() => _projectColor = c), child: AnimatedContainer(duration: 200.ms, width: 32, height: 32, margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: _projectColor == c ? Border.all(color: isDark ? Colors.white : Colors.black, width: 3) : null)))).toList()))),
      ],
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(context: context, builder: (ctx) => GridView.builder(padding: const EdgeInsets.all(24), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing: 16, crossAxisSpacing: 16), itemCount: _emojis.length, itemBuilder: (ctx, i) => GestureDetector(onTap: () { setState(() => _projectEmoji = _emojis[i]); Navigator.pop(ctx); }, child: Center(child: Text(_emojis[i], style: const TextStyle(fontSize: 24))))));
  }

  Widget _buildDateRow(bool isDark) {
    return Row(
      children: [
        Expanded(child: _DateTile(label: 'START', date: _startDate, isDark: isDark, color: _projectColor, onTap: () async { final d = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2020), lastDate: DateTime(2030)); if (d != null) setState(() => _startDate = d); })),
        const SizedBox(width: 16),
        Expanded(child: _DateTile(label: 'DEADLINE', date: _endDate, isDark: isDark, color: _projectColor, onTap: () async { final d = await showDatePicker(context: context, initialDate: _endDate, firstDate: DateTime(2020), lastDate: DateTime(2030)); if (d != null) setState(() => _endDate = d); })),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(children: List.generate(3, (i) => Expanded(child: Container(height: 4, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: _currentStep >= i ? _projectColor : _projectColor.withOpacity(0.1), borderRadius: BorderRadius.circular(2))))));
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(title, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 10));
  }

  Widget _buildDropdown<T extends Enum>({required String label, required T value, required List<T> items, required ValueChanged<T?> onChanged, required bool isDark}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey)),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: isDark ? const Color(0xFF161B22) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight)), child: DropdownButtonHideUnderline(child: DropdownButton<T>(value: value, items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)))).toList(), onChanged: onChanged, isExpanded: true))),
    ]);
  }

  Widget _buildPopupStatusSelector<T extends Enum>({required T current, required List<T> values, required ValueChanged<T> onChanged, required bool isDark}) {
    return PopupMenuButton<T>(onSelected: onChanged, itemBuilder: (ctx) => values.map((s) => PopupMenuItem(value: s, child: Text(s.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)))).toList(), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)), child: Text(current.name.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900))));
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
  final TextEditingController controller; final String hint; final IconData icon; final Color accentColor; final String? Function(String?)? validator; final TextInputType? keyboardType;
  const _ModernInput({required this.controller, required this.hint, required this.icon, required this.accentColor, this.validator, this.keyboardType});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(controller: controller, validator: validator, keyboardType: keyboardType, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: accentColor, size: 20), filled: true, fillColor: isDark ? const Color(0xFF161B22) : Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: accentColor, width: 2))));
  }
}
