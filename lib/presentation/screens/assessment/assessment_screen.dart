import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class AssessmentIntroScreen extends StatelessWidget {
  const AssessmentIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text('Assessment Workouts', style: AppTextStyles.h2),
              const SizedBox(height: 8),
              Text(
                'Complete 3 evaluation workouts to help our AI understand your fitness level',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 32),

              // Info cards
              Expanded(
                child: ListView(
                  children: [
                    _buildInfoCard(
                      icon: Icons.assessment,
                      title: 'Why Assessment?',
                      description:
                          'These workouts help us understand your current fitness level, strengths, and areas for improvement.',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.timer,
                      title: 'How Long?',
                      description:
                          'Each assessment workout takes 20-30 minutes. You can complete them at your own pace.',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.fitness_center,
                      title: 'What to Expect?',
                      description:
                          'A mix of strength, endurance, and mobility exercises to evaluate your overall fitness.',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.auto_awesome,
                      title: 'Personalized Plans',
                      description:
                          'After completion, you\'ll receive a customized workout plan tailored to your abilities.',
                    ),
                  ],
                ),
              ),

              // Progress indicator
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Progress', style: AppTextStyles.h5),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: 0 / 3,
                        backgroundColor: AppColors.backgroundLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '0 of 3 assessments completed',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Start button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const AssessmentWorkoutScreen(assessmentNumber: 1),
                      ),
                    );
                  },
                  child: const Text('Start First Assessment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryNeon.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryNeon),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.h6),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AssessmentWorkoutScreen extends StatefulWidget {
  final int assessmentNumber;

  const AssessmentWorkoutScreen({super.key, required this.assessmentNumber});

  @override
  State<AssessmentWorkoutScreen> createState() =>
      _AssessmentWorkoutScreenState();
}

class _AssessmentWorkoutScreenState extends State<AssessmentWorkoutScreen> {
  int _currentExerciseIndex = 0;
  final List<Map<String, dynamic>> _exercises = [
    {
      'name': 'Push-ups',
      'description': 'Do as many push-ups as you can with good form',
      'type': 'max_reps',
      'completed': false,
      'result': 0,
    },
    {
      'name': 'Bodyweight Squats',
      'description': 'Do as many squats as you can in 60 seconds',
      'type': 'timed',
      'duration': 60,
      'completed': false,
      'result': 0,
    },
    {
      'name': 'Plank Hold',
      'description': 'Hold a plank position for as long as possible',
      'type': 'duration',
      'completed': false,
      'result': 0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final currentExercise = _exercises[_currentExerciseIndex];

    return Scaffold(
      appBar: AppBar(title: Text('Assessment ${widget.assessmentNumber}/3')),
      body: Column(
        children: [
          // Progress
          LinearProgressIndicator(
            value: (_currentExerciseIndex + 1) / _exercises.length,
            backgroundColor: AppColors.backgroundLight,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise info
                  Text(currentExercise['name'], style: AppTextStyles.h2),
                  const SizedBox(height: 8),
                  Text(
                    currentExercise['description'],
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Video placeholder
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.play_circle_outline, size: 64),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Instructions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Instructions', style: AppTextStyles.h5),
                          const SizedBox(height: 12),
                          _buildInstruction('1. Get into starting position'),
                          _buildInstruction('2. Perform the exercise'),
                          _buildInstruction('3. Record your result'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Result input
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Record Your Result', style: AppTextStyles.h5),
                          const SizedBox(height: 16),
                          TextField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: currentExercise['type'] == 'max_reps'
                                  ? 'Number of reps'
                                  : 'Seconds',
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              currentExercise['result'] =
                                  int.tryParse(value) ?? 0;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Next button
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextExercise,
                child: Text(
                  _currentExerciseIndex == _exercises.length - 1
                      ? 'Complete Assessment'
                      : 'Next Exercise',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  void _nextExercise() {
    if (_currentExerciseIndex < _exercises.length - 1) {
      setState(() {
        _exercises[_currentExerciseIndex]['completed'] = true;
        _currentExerciseIndex++;
      });
    } else {
      // Assessment complete
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Assessment Complete!'),
        content: Text(
          widget.assessmentNumber == 3
              ? 'Great job! You\'ve completed all assessments. Your personalized plan is being generated.'
              : 'Great job! Assessment ${widget.assessmentNumber} complete. ${3 - widget.assessmentNumber} more to go!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close assessment screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
