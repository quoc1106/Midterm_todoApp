/// 🎨 FRONTEND COMPONENTS - Add Task Overlay
///
/// ⭐ RIVERPOD LEVEL 2-3 DEMONSTRATION ⭐
/// Full-screen Add Task overlay with slide animation similar to search
///
/// FEATURES:
/// - Slide animation from top
/// - Full-screen overlay design
/// - Integration with AddTaskWidget
/// - Success feedback animation
/// - Cancel functionality

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Backend imports
import '../../../providers/todo_providers.dart';

// Frontend component imports
import '../todo/add_task_widget.dart';

class AddTaskOverlay extends ConsumerStatefulWidget {
  const AddTaskOverlay({super.key});

  @override
  ConsumerState<AddTaskOverlay> createState() => _AddTaskOverlayState();
}

class _AddTaskOverlayState extends ConsumerState<AddTaskOverlay>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _successController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();

    // Slide animation controller
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Success animation controller
    _successController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Slide animation - từ trên xuống
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Success animation
    _successAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));

    // Start slide animation
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _onTaskAdded() {
    // Trigger success animation
    _successController.forward().then((_) {
      // Reset success animation for next use
      _successController.reset();
    });

    // Show success feedback
    _showSuccessFeedback();
  }

  void _showSuccessFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            AnimatedBuilder(
              animation: _successAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _successAnimation.value,
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            const Text('Task added successfully!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _onCancel() {
    // Slide out animation
    _slideController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.5),
      body: GestureDetector(
        onTap: _onCancel, // Tap outside to close
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with title and close button
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.add_task_rounded,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Add New Task',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _onCancel,
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                                tooltip: 'Cancel',
                              ),
                            ],
                          ),
                        ),

                        // Add Task Widget Content
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            child: Consumer(
                              builder: (context, ref, child) {
                                final currentView = ref.watch(sidebarItemProvider);
                                // Luôn hiển thị date picker khi mở từ Today/Upcoming
                                final shouldShowDatePicker = currentView == SidebarItem.today ||
                                                               currentView == SidebarItem.upcoming;

                                return AddTaskWidget(
                                  onTaskAdded: _onTaskAdded,
                                  onCancel: _onCancel,
                                  showCancel: true,
                                  hintText: 'What do you want to accomplish?',
                                  // Force show date picker for Today/Upcoming contexts
                                  presetDate: shouldShowDatePicker ? DateTime.now() : null,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
