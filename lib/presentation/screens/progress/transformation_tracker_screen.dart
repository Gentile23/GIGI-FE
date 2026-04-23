import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart'; 
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';
import '../../widgets/animations/liquid_steel_container.dart';

class TransformationTrackerScreen extends StatefulWidget {
  const TransformationTrackerScreen({super.key});

  @override
  State<TransformationTrackerScreen> createState() => _TransformationTrackerScreenState();
}

class _TransformationTrackerScreenState extends State<TransformationTrackerScreen> {
  final List<TransformationEntry> _entries = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadSampleEntries();
  }

  void _loadSampleEntries() {
    // Simuliamo un utente che ha appena iniziato o è a metà percorso
    _entries.addAll([
      TransformationEntry(
        id: '1',
        date: DateTime.now().subtract(const Duration(days: 90)),
        weight: 85.0,
        notes: 'Giorno 1: La mia promessa.',
      ),
      // Decommenta per vedere lo stato "Dopo"
      TransformationEntry(
         id: '2',
         date: DateTime.now(),
         weight: 78.0,
         notes: '90 Giorni dopo. Non ci credo!',
         imagePath: 'assets/after_placeholder.png' // Simulato
       ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. IL CONSIGLIO DI GIGI (Psicologia & Motivazione)
                  _buildGigiAdviceCard(),
                  
                  const SizedBox(height: 24),
                  
                  // 2. LO STATO ATTUALE (La Sfida)
                  _buildChallengeStatus(),

                  const SizedBox(height: 32),

                  // 3. GUIDA ALLO SCATTO PERFETTO (Qualità = Condivisione)
                  if (_entries.isNotEmpty) _buildPhotoTipsSection(),

                  const SizedBox(height: 32),
                  
                  // 4. TIMELINE
                  Text(
                    'LA TUA STORIA',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: CleanTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTimeline(),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewEntry,
        backgroundColor: CleanTheme.primaryColor,
        elevation: 4,
        icon: const Icon(Icons.camera_alt, color: Colors.white),
        label: Text(
          _entries.isEmpty ? 'INIZIA LA SFIDA' : 'AGGIORNA PROGRESSO',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: CleanTheme.surfaceColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: CleanTheme.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Transformation Challenge',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: CleanTheme.textPrimary,
            fontSize: 18
          ),
        ),
        centerTitle: true,
      ),
      actions: [
        if (_entries.length >= 2)
          IconButton(
            icon: const Icon(Icons.ios_share, color: CleanTheme.primaryColor),
            onPressed: _generateAndShareContent,
          ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // 1. SEZIONE MOTIVAZIONALE "CONSIGLIO DI GIGI"
  // ════════════════════════════════════════════════════════════════
  Widget _buildGigiAdviceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [CleanTheme.accentOrange.withValues(alpha: 0.15), CleanTheme.surfaceColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CleanTheme.accentOrange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: CleanTheme.accentOrange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lightbulb_outline, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'IL CONSIGLIO DI GIGI',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  color: CleanTheme.accentOrange,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"Il tuo specchio mente, le foto no."',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CleanTheme.textPrimary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Il cambiamento avviene lentamente e poi tutto in una volta. Scatta una foto oggi e una tra 90 giorni. In quel lasso di tempo, io mi occuperò della tua nutrizione e del tuo allenamento. Tu devi solo presentarti. Questa foto sarà il trofeo della tua disciplina.',
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: CleanTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // 2. STATO DELLA SFIDA (PRIMA / DOPO)
  // ════════════════════════════════════════════════════════════════
  Widget _buildChallengeStatus() {
    // Caso 1: Utente nuovo (Nessuna foto)
    if (_entries.isEmpty) {
      return _buildEmptyState();
    }

    // Caso 2: Utente con almeno 2 foto (Challenge Completata/In corso)
    if (_entries.length >= 2) {
      return _buildBeforeAfterComparison();
    }

    // Caso 3: Utente con 1 foto (In attesa del risultato)
    return _buildInProgressState();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(Icons.photo_camera_front, size: 64, color: CleanTheme.textTertiary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Nessuna foto... ancora.',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: CleanTheme.textPrimary),
          ),
          Text(
            'Il momento migliore per iniziare era ieri.\nIl secondo migliore è adesso.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: CleanTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildInProgressState() {
    final daysPassed = DateTime.now().difference(_entries.first.date).inDays;
    final progress = (daysPassed / 90).clamp(0.0, 1.0);

    return Column(
      children: [
        LiquidSteelContainer(
          borderRadius: 20,
          child: Container(
            height: 200,
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Miniatura Prima Foto
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 100,
                    height: 120,
                    color: Colors.black26,
                    child: _entries.first.imagePath != null 
                      ? Image.asset(_entries.first.imagePath!, fit: BoxFit.cover) // In prod: FileImage
                      : const Icon(Icons.person, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'IN CORSO...',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: CleanTheme.accentOrange, letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Giorno $daysPassed di 90',
                        style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(CleanTheme.accentOrange),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mancano ${90 - daysPassed} giorni alla rivelazione.',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBeforeAfterComparison() {
    return Column(
      children: [
        // Branding Header per lo screenshot
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: CleanTheme.primaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'MY GIGI TRANSFORMATION',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  _buildPhotoFrame(_entries.first, 'PRIMA'),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('dd MMM').format(_entries.first.date),
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: CleanTheme.surfaceColor,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: const Icon(Icons.arrow_forward, size: 20, color: CleanTheme.primaryColor),
            ),
            Expanded(
              child: Column(
                children: [
                  _buildPhotoFrame(_entries.last, 'DOPO'),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('dd MMM').format(_entries.last.date),
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        CleanButton(
          text: 'CONDIVIDI IL SUCCESSO 🚀',
          onPressed: _generateAndShareContent,
          backgroundColor: CleanTheme.accentGreen,
          icon: Icons.share,
          width: double.infinity,
        ),
      ],
    );
  }

  Widget _buildPhotoFrame(TransformationEntry entry, String label) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            entry.imagePath != null
                ? Image.asset(entry.imagePath!, fit: BoxFit.cover) // In prod: FileImage
                : Container(color: CleanTheme.primaryLight.withValues(alpha: 0.3), child: const Icon(Icons.person)),
            
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // 3. GUIDA ALLO SCATTO PERFETTO (Tips)
  // ════════════════════════════════════════════════════════════════
  Widget _buildPhotoTipsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CleanTheme.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COME SCATTARE IL "DOPO" PERFETTO',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: CleanTheme.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          _buildTipRow(Icons.wb_sunny_outlined, 'Luce', 'Usa luce naturale frontale. Evita ombre dure.'),
          const SizedBox(height: 12),
          _buildTipRow(Icons.accessibility_new, 'Posa', 'Rilassato/a, braccia lungo i fianchi. Non trattenere il respiro.'),
          const SizedBox(height: 12),
          _buildTipRow(Icons.checkroom, 'Abbigliamento', 'Indossa abbigliamento simile alla prima foto (o intimo).'),
          const SizedBox(height: 12),
          _buildTipRow(Icons.photo_camera_back, 'Angolazione', 'Fotocamera all\'altezza del petto, non dall\'alto.'),
        ],
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: CleanTheme.primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(fontSize: 13, color: CleanTheme.textSecondary, height: 1.4),
              children: [
                TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold, color: CleanTheme.textPrimary)),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // 4. TIMELINE
  // ════════════════════════════════════════════════════════════════
  Widget _buildTimeline() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries.reversed.toList()[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Text(
                DateFormat('dd/MM').format(entry.date),
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: CleanTheme.textSecondary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CleanTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CleanTheme.borderPrimary),
                  ),
                  child: Row(
                    children: [
                      if (entry.weight != null) ...[
                        Text(
                          '${entry.weight} kg',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: CleanTheme.textPrimary),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          entry.notes ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 12, color: CleanTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════
  // ACTIONS
  // ════════════════════════════════════════════════════════════════
  Future<void> _addNewEntry() async {
    // 1. Mostra le linee guida prima di aprire la camera
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CleanTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Pronto per lo scatto?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_entries.isNotEmpty) ...[
              Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: AssetImage(_entries.first.imagePath ?? ''), // In prod: FileImage
                    fit: BoxFit.cover,
                    opacity: 0.5, // GHOST EFFECT
                  ),
                  color: Colors.black,
                ),
                child: const Center(
                  child: Text(
                    'Usa la foto precedente come guida',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text('Mantieni la stessa distanza e luce per un confronto valido.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          CleanButton(
            text: 'Apri Fotocamera', 
            onPressed: () {
              Navigator.pop(context);
              _pickImage();
            },
            width: 160,
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      // Qui salveremmo la foto. Per ora aggiungiamo una entry fittizia
      setState(() {
        _entries.add(TransformationEntry(
          id: DateTime.now().toString(),
          date: DateTime.now(),
          weight: 78.0,
          notes: 'Nuovo progresso!',
          imagePath: image.path,
        ));
      });
    }
  }

  void _generateAndShareContent() {
    // 1. Testo Promozionale Virale
    const String promoText = 
      "Ho accettato la sfida dei 90 giorni con GiGi! 🚀\n"
      "Guarda il mio cambiamento. La costanza paga sempre.\n\n"
      "Vuoi trasformare il tuo corpo? Scarica l'app qui: [LINK_STORE]\n"
      "#GigiApp #Transformation #FitnessJourney #90DaysChallenge";

    // 2. Simulazione Generazione Immagine Branding
    // In produzione useremmo il package 'screenshot' o 'image' per unire le foto e aggiungere il logo.
    
    // 3. Trigger Share
    Share.share(promoText);
    
    // Feedback Utente
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generazione post social in corso... ✨'),
        backgroundColor: CleanTheme.primaryColor,
      ),
    );
  }
}

class TransformationEntry {
  final String id;
  final DateTime date;
  final String? imagePath;
  final double? weight;
  final String? notes;

  TransformationEntry({required this.id, required this.date, this.imagePath, this.weight, this.notes});
}
