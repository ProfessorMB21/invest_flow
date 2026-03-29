import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:investflow/features/projects/logic/project_notifier.dart';

class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _goalAmountCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  
  DateTime? _deadline;
  bool _isLoading = false;
  String? _selectedCategory;
  
  final List<String> _categories = [
    'Technology',
    'Emergency funds',
    'Housing',
    'Business',
    'Education',
    'Savings',
    'Other',
  ];
  
  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _goalAmountCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }
  
  Future<void> _selectDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Theme.of(context).colorScheme.primary,
              )
            ), 
            child: child!
        );
      }
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }
  
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a deadline')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final projectId = await ref.read(projectNotifierProvider.notifier).createProject(
        title: _titleCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        goalAmount: double.parse(_goalAmountCtrl.text.replaceAll(',', '')),
        deadline: _deadline!,
        category: _selectedCategory ?? 'Other',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project created successfully!'),
            backgroundColor: Colors.green,
          )
        );
        // Navigate to project details
        context.go('/projects/$projectId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create project: $e'),
              backgroundColor: Colors.red,
            )
        );
      }
    }
    finally {
      if (mounted) setState(() =>  _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Project'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Create Investment Project',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fill in the details below to create a new investment opportunity',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Project Title
              TextFormField(
                controller: _titleCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Project Title *',
                  hintText: 'e.g., Tech Startup Series A',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                  helperText: 'Choose a clear, descriptive title',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a project title';
                  }
                  if (value.length < 5) {
                    return 'Title must be at least 5 characters';
                  }
                  if (value.length > 100) {
                    return 'Title must be less than 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Select a category'),
                items: _categories.map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionCtrl,
                textInputAction: TextInputAction.next,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Describe your project, goals, and investment opportunity...',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  helperText: 'Provide detailed information about your project',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.length < 20) {
                    return 'Description must be at least 20 characters';
                  }
                  if (value.length > 2000) {
                    return 'Description must be less than 2000 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Goal Amount
              TextFormField(
                controller: _goalAmountCtrl,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Funding Goal *',
                  hintText: currencyFormat.format(100000),
                  prefixIcon: const Icon(Icons.attach_money),
                  border: const OutlineInputBorder(),
                  suffixText: 'USD',
                  helperText: 'Total amount you want to raise',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a funding goal';
                  }
                  final amount = double.tryParse(value.replaceAll(',', ''));
                  if (amount == null) {
                    return 'Please enter a valid number';
                  }
                  if (amount < 1000) {
                    return 'Minimum funding goal is \$1,000';
                  }
                  if (amount > 100000000) {
                    return 'Maximum funding goal is \$100,000,000';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Deadline
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.calendar_today,
                    color: _deadline != null
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                  title: Text(
                    _deadline != null
                        ? 'Deadline: ${DateFormat.yMMMd().format(_deadline!)}'
                        : 'Select Project Deadline *',
                    style: TextStyle(
                      color: _deadline != null ? null : Colors.grey[600],
                    ),
                  ),
                  subtitle: Text(
                    _deadline != null
                        ? '${_deadline!.difference(DateTime.now()).inDays} days from now'
                        : 'Choose when the funding period ends',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _selectDeadline,
                ),
              ),
              if (_deadline == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Please select a deadline',
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ),
              const SizedBox(height: 24),

              // Info Card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Important Information',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Once created, project details can be edited but cannot be deleted if investments exist.',
                              style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              FilledButton.icon(
                onPressed: _isLoading ? null : _submitForm,
                icon: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.check),
                label: Text(_isLoading ? 'Creating Project...' : 'Create Project'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Cancel Button
              OutlinedButton(
                onPressed: _isLoading ? null : () => context.pop(),
                child: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
