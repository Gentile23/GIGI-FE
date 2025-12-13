import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Dettaglio Esercizio'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.favorite_border),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Player
            _buildMediaPlayer(),
            const SizedBox(height: 16),
            // Headline & Tags
            _buildHeadlineAndTags(),
            const SizedBox(height: 16),
            // AI Tools
            _buildAiTools(),
            const SizedBox(height: 16),
            // Instructions
            _buildInstructions(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('Inizia Allenamento'),
        icon: const Icon(Icons.play_arrow),
        backgroundColor: const Color(0xFF13EC5B),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildMediaPlayer() {
    return Container(
      height: 220,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/exercise_media_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.play_circle_fill,
          color: Color(0xFF13EC5B),
          size: 64,
        ),
      ),
    );
  }

  Widget _buildHeadlineAndTags() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Barbell Squat',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTag('Difficile'),
              const SizedBox(width: 8),
              _buildTag('Gambe'),
              const SizedBox(width: 8),
              _buildTag('Forza'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildAiTools() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Strumenti AI',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          _buildAiToolItem(
            icon: Icons.graphic_eq,
            title: 'AI Voice Coach',
            subtitle: 'Consigli vocali in tempo reale',
          ),
          const SizedBox(height: 8),
          _buildAiToolItem(
            icon: Icons.videocam,
            title: 'Correzione Video AI',
            subtitle: 'Analizza la tua forma con la fotocamera',
          ),
        ],
      ),
    );
  }

  Widget _buildAiToolItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF13EC5B),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Istruzioni',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildInstructionStep(
            step: '1',
            title: 'Posizione Iniziale',
            description:
                'Posiziona il bilanciere sulla parte superiore della schiena, piedi alla larghezza delle spalle. Mantieni il petto in fuori e il core contratto.',
          ),
          const SizedBox(height: 8),
          _buildInstructionStep(
            step: '2',
            title: 'Discesa',
            description:
                'Piega le ginocchia e i fianchi contemporaneamente per abbassarti. Mantieni la schiena dritta e scendi fino a quando le cosce sono parallele al pavimento.',
          ),
          const SizedBox(height: 8),
          _buildInstructionStep(
            step: '3',
            title: 'Risalita',
            description:
                'Spingi con forza attraverso i talloni per tornare alla posizione di partenza. Espira durante lo sforzo.',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep({
    required String step,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFF13EC5B),
          child: Text(
            step,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
