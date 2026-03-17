import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../data/services/api_client.dart';
import 'package:intl/intl.dart';
import '../../widgets/clean_widgets.dart';

class BodyPartDetailSheet extends StatefulWidget {
  final String partId;
  final dynamic currentValue;
  final dynamic change;

  const BodyPartDetailSheet({
    super.key,
    required this.partId,
    this.currentValue,
    this.change,
  });

  @override
  State<BodyPartDetailSheet> createState() => _BodyPartDetailSheetState();
}

class _BodyPartDetailSheetState extends State<BodyPartDetailSheet> {
  final _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  double _parseNum(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> _loadHistory() async {
    try {
      final response = await _apiClient.get('progress/measurements/history');
      if (response['success'] == true) {
        setState(() {
          _history = response['measurements'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _getPartName() {
    final partLabels = {
      'neck_cm': 'Collo',
      'shoulders_cm': 'Spalle',
      'chest_cm': 'Petto',
      'bicep_left_cm': 'Bicipite SX',
      'bicep_right_cm': 'Bicipite DX',
      'forearm_cm': 'Avambraccio',
      'waist_cm': 'Vita',
      'hips_cm': 'Fianchi',
      'thigh_left_cm': 'Coscia SX',
      'thigh_right_cm': 'Coscia DX',
      'calf_cm': 'Polpaccio',
      'calf_left_cm': 'Polpaccio SX',
      'calf_right_cm': 'Polpaccio DX',
    };
    return partLabels[widget.partId] ?? widget.partId;
  }

  String _getPartEmoji() {
    final emojis = {
      'neck_cm': '🧣',
      'shoulders_cm': '👔',
      'chest_cm': '👕',
      'bicep_left_cm': '💪',
      'bicep_right_cm': '💪',
      'forearm_cm': '🦾',
      'waist_cm': '📏',
      'hips_cm': '🍑',
      'thigh_left_cm': '🦵',
      'thigh_right_cm': '🦵',
      'calf_cm': '🏃',
    };
    return emojis[widget.partId] ?? '📊';
  }

  String _getPartDescription() {
    final descriptions = {
      'neck_cm': 'Il collo riflette spesso la postura e lo sviluppo dei trapezi.',
      'shoulders_cm': 'Spalle larghe contribuiscono alla forma a V del torso.',
      'chest_cm': 'Lo sviluppo del petto è un indicatore chiave della forza della parte superiore.',
      'bicep_left_cm': 'Misura nel punto di massima contrazione.',
      'bicep_right_cm': 'Misura nel punto di massima contrazione.',
      'waist_cm': 'La misura della vita è l\'indicatore principale della percentuale di grasso corporeo.',
      'hips_cm': 'I fianchi sono fondamentali per monitorare la composizione della parte inferiore.',
      'thigh_left_cm': 'Le cosce mostrano il progresso nei grandi esercizi multi-articolari.',
      'thigh_right_cm': 'Le cosce mostrano il progresso nei grandi esercizi multi-articolari.',
      'calf_cm': 'I polpacci sono spesso difficili da far crescere, monitorali con costanza!',
    };
    return descriptions[widget.partId] ?? 'Monitora costantemente questa zona per vedere i tuoi progressi nel tempo.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CleanTheme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CleanTheme.borderSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CleanTheme.primaryColor.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _getPartEmoji(),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getPartName(),
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Storico e Approfondimenti',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: CleanTheme.borderSecondary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Current Value & Change
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Attuale',
                  widget.currentValue != null ? '${_parseNum(widget.currentValue)} cm' : '-',
                  CleanTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Variazione',
                  widget.change != null 
                    ? '${_parseNum(widget.change) > 0 ? '+' : ''}${_parseNum(widget.change).toStringAsFixed(1)} cm' 
                    : '-',
                  _getColorForChange(widget.partId, _parseNum(widget.change)),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Chart Section
          Text(
            'Trend Temporale',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _history.isEmpty 
                ? const Center(child: Text('Nessun dato storico disponibile', style: TextStyle(color: CleanTheme.textSecondary)))
                : _buildChart(),
          ),

          const SizedBox(height: 24),
          
          // Add Measurement Button
          CleanButton(
            text: 'Aggiungi Misura',
            icon: Icons.add_circle_outline,
            onPressed: () => _showAddMeasurementDialog(context),
            width: double.infinity,
          ),
          
          const SizedBox(height: 32),
          
          // Cool Info / Tip
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CleanTheme.steelDark,
              borderRadius: BorderRadius.circular(24),
              boxShadow: CleanTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: CleanTheme.accentGold, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Lo sapevi?',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _getPartDescription(),
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // History List Section
          Text(
            'Storico Dettagliato',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _buildHistoryList(),
        ],
      ),
    ),
  );
}

  Widget _buildHistoryList() {
  final filteredHistory = _history
      .where((m) => m[widget.partId] != null)
      .toList();

  if (filteredHistory.isEmpty) return _buildEmptyState();

  return Column(
    children: filteredHistory.map((m) {
      final date = DateTime.parse(m['measurement_date']);
      final value = _parseNum(m[widget.partId]);
      
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: CleanTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CleanTheme.borderSecondary),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: CleanTheme.textSecondary),
            const SizedBox(width: 12),
            Text(
              DateFormat('dd/MM/yyyy').format(date),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: CleanTheme.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '$value cm',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: CleanTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: CleanTheme.accentRed, size: 20),
              onPressed: () => _deleteMeasurement(m),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }).toList(),
  );
}

Future<void> _deleteMeasurement(Map<String, dynamic> measurement) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Elimina Misura'),
      content: const Text('Sei sicuro di voler eliminare questa rilevazione?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annulla'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: CleanTheme.accentRed),
          child: const Text('Elimina'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    // Preferiamo l'ID se presente, altrimenti usiamo la data come fallback
    final id = measurement['id'];
    final date = measurement['measurement_date'];
    final normalizedDate = date?.toString().split('T')[0];
    final identifier = id?.toString() ?? normalizedDate;
    
    if (identifier == null) return;

    try {
      final response = await _apiClient.delete('progress/measurements/$identifier');
      
      if (response['success'] == true) {
        _loadHistory();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Misura eliminata con successo'),
              backgroundColor: CleanTheme.accentGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossibile eliminare la misura al momento. Riprova più tardi.'),
              backgroundColor: CleanTheme.accentRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore di connessione durante l\'eliminazione.'),
            backgroundColor: CleanTheme.accentRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

  void _showAddMeasurementDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CleanTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Nuova Misura: ${_getPartName()}',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: CleanTheme.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: CleanTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0.0',
                suffixText: 'cm',
                suffixStyle: GoogleFonts.outfit(
                  fontSize: 16,
                  color: CleanTheme.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: CleanTheme.borderSecondary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: CleanTheme.borderSecondary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: CleanTheme.primaryColor, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annulla',
              style: GoogleFonts.inter(color: CleanTheme.textSecondary),
            ),
          ),
          CleanButton(
            text: 'Salva',
            onPressed: () {
              final value = double.tryParse(controller.text.replaceAll(',', '.'));
              if (value != null && value > 0) {
                Navigator.pop(context);
                _saveMeasurement(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveMeasurement(double value) async {
    setState(() => _isLoading = true);
    
    try {
      final date = DateTime.now().toIso8601String().split('T')[0];
      
      // Prepariamo i dati mantenendo quelli esistenti per la data odierna se presenti
      // o inviando solo quello specifico se il backend supporta il merge (di solito sì in Laravel updateOrCreate)
      final data = {
        'measurement_date': date,
        widget.partId: value,
      };

      final response = await _apiClient.post('progress/measurements', body: data);

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Misura salvata con successo!'),
              backgroundColor: CleanTheme.accentGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        _loadHistory(); // Ricarica lo storico per vedere l'aggiornamento
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Errore durante il salvataggio'),
              backgroundColor: CleanTheme.accentRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore di connessione. Riprova.'),
            backgroundColor: CleanTheme.accentRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Color _getColorForChange(String partId, double change) {
    if (change == 0) return CleanTheme.textSecondary;
    
    // For waist - decrease is good
    if (partId == 'waist_cm' || partId == 'hips_cm') {
      return change < 0 ? CleanTheme.accentGreen : CleanTheme.accentRed;
    }
    
    // For muscles - increase is good
    return change > 0 ? CleanTheme.accentGreen : CleanTheme.accentRed;
  }


  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CleanTheme.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: CleanTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'Nessun dato storico disponibile',
        style: GoogleFonts.inter(color: CleanTheme.textSecondary),
      ),
    );
  }

  Widget _buildChart() {
    final filteredHistory = _history
        .where((m) => m[widget.partId] != null)
        .toList()
        .reversed
        .toList();

    if (filteredHistory.isEmpty) return _buildEmptyState();

    final spots = <FlSpot>[];
    for (int i = 0; i < filteredHistory.length; i++) {
      final val = filteredHistory[i][widget.partId];
      if (val != null) {
        spots.add(FlSpot(i.toDouble(), _parseNum(val)));
      }
    }

    if (spots.length < 2) return _buildEmptyState();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < filteredHistory.length) {
                  final dateStr = filteredHistory[value.toInt()]['measurement_date'];
                  final date = DateTime.parse(dateStr);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('dd/MM').format(date),
                      style: GoogleFonts.inter(fontSize: 10, color: CleanTheme.textSecondary),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: CleanTheme.primaryColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: CleanTheme.primaryColor.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
