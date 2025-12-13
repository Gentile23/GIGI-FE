import 'package:flutter/material.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('I Tuoi Progressi'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Overview
              _buildStatsOverview(),
              const SizedBox(height: 16),
              // AI Quote
              const Center(
                child: Text(
                  '"Il dolore che senti oggi è la forza che sentirai domani."',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Metric Toggles
              _buildMetricToggles(),
              const SizedBox(height: 16),
              // Main Chart
              _buildMainChart(),
              const SizedBox(height: 16),
              // AI Insight
              _buildAiInsight(),
              const SizedBox(height: 16),
              // Recent Personal Records
              _buildPersonalRecords(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF13EC5B),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Piano',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Progressi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profilo',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatCard('Workout', '12'),
        _buildStatCard('Streak Giorni', '5', isHighlighted: true),
        _buildStatCard('Punti XP', '1450'),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, {bool isHighlighted = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFF13EC5B) : Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: isHighlighted ? Colors.black : Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: isHighlighted ? Colors.black : Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricToggles() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildMetricToggle('Peso Corporeo', isSelected: true),
          const SizedBox(width: 8),
          _buildMetricToggle('Massimale Panca'),
          const SizedBox(width: 8),
          _buildMetricToggle('Body Fat %'),
          const SizedBox(width: 8),
          _buildMetricToggle('Squat Max'),
        ],
      ),
    );
  }

  Widget _buildMetricToggle(String text, {bool isSelected = false}) {
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

  Widget _buildMainChart() {
    // This is a placeholder for the chart
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          'Chart Placeholder',
          style: TextStyle(color: Colors.white),
        ),
      ),
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
              'Ottimo lavoro! La tua forza nello Squat è aumentata del 5% questo mese. Mantieni questo ritmo e raggiungerai il tuo obiettivo di 100kg entro 3 settimane.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalRecords() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Record Personali Recenti',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildPrCard('Panca Piana', '95 kg', isNew: true),
            _buildPrCard('Corsa 5k', '24:30'),
            _buildPrCard('Stacco da Terra', '140 kg'),
            _buildPrCard('Aggiungi', '+', isAddButton: true),
          ],
        ),
      ],
    );
  }

  Widget _buildPrCard(String title, String value, {bool isNew = false, bool isAddButton = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isNew)
            const Align(
              alignment: Alignment.topRight,
              child: Text(
                'NEW PR',
                style: TextStyle(
                  color: Color(0xFF13EC5B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (isAddButton)
            const Icon(
              Icons.add,
              size: 40,
              color: Color(0xFF13EC5B),
            )
          else
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
