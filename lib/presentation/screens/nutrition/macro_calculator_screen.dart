import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MacroCalculatorScreen extends StatelessWidget {
  const MacroCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Calcolatore Macro'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search
              _buildSearch(),
              const SizedBox(height: 16),
              // Chips
              _buildChips(),
              const SizedBox(height: 16),
              // Result Card
              _buildResultCard(),
              const SizedBox(height: 16),
              // AI Insight
              _buildAiInsight(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('Aggiungi al Diario'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF13EC5B),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSearch() {
    return Row(
      children: [
        const Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Cerca alimento...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: Icon(Icons.mic),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.qr_code_scanner),
        ),
      ],
    );
  }

  Widget _buildChips() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildChip('Banana'),
          const SizedBox(width: 8),
          _buildChip('Pollo', isSelected: true),
          const SizedBox(width: 8),
          _buildChip('Riso Basmati'),
          const SizedBox(width: 8),
          _buildChip('Uova'),
        ],
      ),
    );
  }

  Widget _buildChip(String text, {bool isSelected = false}) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF13EC5B) : Colors.grey[800],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Petto di Pollo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.favorite_border,
                color: Color(0xFF13EC5B),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Visualization
          // This is a placeholder for the donut chart
          const CircleAvatar(
            radius: 80,
            backgroundColor: Color(0xFF13EC5B),
            child: Text(
              '165\nKcal',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Quantity Adjuster
          _buildQuantityAdjuster(),
          const SizedBox(height: 16),
          // Macro Breakdown
          _buildMacroBreakdown(),
        ],
      ),
    );
  }

  Widget _buildQuantityAdjuster() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.remove),
        ),
        const Text(
          '100g',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  Widget _buildMacroBreakdown() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMacroItem('Proteine', '31g', '55%'),
        _buildMacroItem('Carbo', '0g', '0%'),
        _buildMacroItem('Grassi', '3.6g', '15%'),
      ],
    );
  }

  Widget _buildMacroItem(String title, String value, String percentage) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          percentage,
          style: const TextStyle(
            color: Color(0xFF13EC5B),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildAiInsight() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.lightbulb,
            color: Color(0xFF13EC5B),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ottima fonte di proteine magre! Perfetto per il recupero muscolare. Abbina con carboidrati complessi per un pasto completo.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
