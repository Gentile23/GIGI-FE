# Cooldown UI Implementation Guide

## File: ai_workout_generation_screen.dart

### Location
Find line 173 which contains: `const SizedBox(height: 24),`

### Code to Add
Replace lines 173-222 (from `const SizedBox(height: 24),` to the end of the ElevatedButton widget) with the following code:

```dart
          const SizedBox(height: 24),

          // Cooldown Check
          Consumer<WorkoutProvider>(
            builder: (context, workoutProvider, _) {
              final canGenerate = workoutProvider.canGenerateNewPlan(widget.user);
              final daysRemaining = workoutProvider.getDaysUntilNextGeneration(widget.user);

              if (!canGenerate) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule, color: Colors.orange.shade700, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Prossima generazione disponibile tra',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$daysRemaining ${daysRemaining == 1 ? "giorno" : "giorni"}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Generate Button
          Consumer<WorkoutProvider>(
            builder: (context, workoutProvider, _) {
              final canGenerate = workoutProvider.canGenerateNewPlan(widget.user);
              
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isGenerating || !canGenerate) ? null : _generatePlan,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isGenerating
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Generazione in corso...',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome),
                            SizedBox(width: 8),
                            Text(
                              'Genera Scheda AI',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              );
            },
          ),
```

## Summary
This adds:
1. A cooldown check that displays an orange warning box when user cannot generate
2. Shows days remaining until next generation
3. Disables the generate button when cooldown is active
4. Uses `Consumer<WorkoutProvider>` to reactively check cooldown status
