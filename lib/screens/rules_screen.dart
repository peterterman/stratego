import 'package:flutter/material.dart';

import '../services/game_variant_service.dart';

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  GameVariant _variant = GameVariant.eighteenTwelve;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVariant();
  }

  Future<void> _loadVariant() async {
    final variant = await GameVariantService.getVariant();

    if (!mounted) return;

    setState(() {
      _variant = variant;
      _loading = false;
    });
  }

  String get _title {
    switch (_variant) {
      case GameVariant.eighteenTwelve:
        return 'Regler for 1812';
      case GameVariant.classic:
        return 'Klassiske regler';
    }
  }

  List<_RuleSection> get _sections {
    switch (_variant) {
      case GameVariant.eighteenTwelve:
        return _rules1812;
      case GameVariant.classic:
        return _rulesClassic;
    }
  }

  static const List<_RankItem> _classicRanks = [
    _RankItem('marshal', 'Feltmarskal', 'Stærkeste brik'),
    _RankItem('general', 'General', ''),
    _RankItem('oberst', 'Oberst', ''),
    _RankItem('major', 'Major', ''),
    _RankItem('kaptajn', 'Kaptajn', ''),
    _RankItem('lojtnant', 'Løjtnant', ''),
    _RankItem('sergent', 'Sergent', ''),
    _RankItem('minor', 'Minør', 'Kan uskadeliggøre bomber'),
    _RankItem('spejder', 'Spejder', 'Kan rykke flere frie felter i lige linje'),
    _RankItem(
      'spion',
      'Spion',
      'Kan slå Feltmarskal, hvis Spion angriber først',
    ),
    _RankItem('bombe', 'Bombe', 'Kan ikke flytte'),
    _RankItem('flag', 'Fane', 'Skal beskyttes'),
  ];

  static const List<_RankItem> _ranks1812 = [
    _RankItem('marshal', 'Hærfører', 'Stærkeste brik'),
    _RankItem('general', 'General', ''),
    _RankItem('oberst', 'Oberst', ''),
    _RankItem('major', 'Major', ''),
    _RankItem('kaptajn', 'Kaptajn', ''),
    _RankItem('lojtnant', 'Løjtnant', ''),
    _RankItem('sergent', 'Sergent', ''),
    _RankItem('minor', 'Ingeniør', 'Kan uskadeliggøre fælder'),
    _RankItem(
      'spejder',
      'Ordonnans',
      'Kan rykke flere frie felter i lige linje',
    ),
    _RankItem('spion', 'Spion', 'Kan slå Hærfører, hvis Spion angriber først'),
    _RankItem('bombe', 'Fælde', 'Kan ikke flytte'),
    _RankItem('flag', 'Fane', 'Skal beskyttes'),
  ];

  static const List<_RuleSection> _rulesClassic = [
    _RuleSection(
      'Resume af spillet',
      'Begge spillere råder over 40 spillebrikker, inklusive en fane. '
          'Du skal forsøge at erobre modstanderens fane og forsvare din egen fane.\n\n'
          'Brikkerne er underlagt en rangorden. En brik med højere rang slår en brik med lavere rang. '
          'Hvis to brikker med samme rang mødes, fjernes begge.',
    ),
    _RuleSection(
      'Spillets forløb',
      'Du spiller blå og begynder. Derefter skiftes spillerne til at flytte én brik.\n\n'
          'Du kan flytte en brik til et ledigt felt eller angribe en modstanders brik.',
    ),
    _RuleSection(
      'Flytning af brikker',
      'De fleste brikker flytter ét felt vandret eller lodret. Man kan ikke flytte diagonalt.\n\n'
          'Bomber og fane kan ikke flyttes.\n\n'
          'Spejderen kan rykke flere frie felter i lige linje.\n\n'
          'Brikker kan ikke stå på eller springe over søerne midt på spillepladen.',
    ),
    _RuleSection(
      'Angreb',
      'Når en af dine brikker står ved siden af, foran eller bag en fjendtlig brik, kan du angribe den. '
          'Spejderen kan angribe fra længere afstand, hvis der er fri bane.\n\n'
          'Hvis Minøren angriber en Bombe, uskadeliggøres bomben, og Minøren indtager feltet.\n\n'
          'Spionen har laveste rang, men kan slå Feltmarskal, hvis Spionen angriber først. '
          'Hvis Feltmarskallen angriber Spionen, vinder Feltmarskallen.\n\n'
          'Fanen kan erobres af alle modstanderens bevægelige brikker.',
    ),
    _RuleSection(
      'Vinderen',
      'Du vinder spillet, hvis du erobrer modstanderens fane.\n\n'
          'Du kan også vinde, hvis modstanderen ikke længere kan flytte nogen brikker.',
    ),
  ];

  static const List<_RuleSection> _rules1812 = [
    _RuleSection(
      'Resume af spillet',
      'Begge spillere råder over 40 spillebrikker, inklusive en fane. '
          'Du skal forsøge at erobre modstanderens fane og forsvare din egen fane.\n\n'
          '1812 bruger egne briknavne og egne symboler, men grundideen er den samme: '
          'skjul din fane, find modstanderens fane, og brug rangordenen taktisk.',
    ),
    _RuleSection(
      'Spillets forløb',
      'Du spiller blå og begynder. Derefter skiftes spillerne til at flytte én brik.\n\n'
          'Du kan flytte en brik til et ledigt felt eller angribe en modstanders brik.',
    ),
    _RuleSection(
      'Flytning af brikker',
      'De fleste brikker flytter ét felt vandret eller lodret. Man kan ikke flytte diagonalt.\n\n'
          'Fælder og fane kan ikke flyttes.\n\n'
          'Ordonnansen kan rykke flere frie felter i lige linje.',
    ),
    _RuleSection(
      'Ingen søer',
      'I 1812 er der ingen søer på brættet. Alle 100 felter kan bruges.',
    ),
    _RuleSection(
      'Angreb',
      'Når en af dine brikker står ved siden af, foran eller bag en fjendtlig brik, kan du angribe den. '
          'Ordonnansen kan angribe fra længere afstand, hvis der er fri bane.\n\n'
          'Hvis Ingeniøren angriber en Fælde, uskadeliggøres fælden, og Ingeniøren indtager feltet.\n\n'
          'Spionen har laveste rang, men kan slå Hærfører, hvis Spionen angriber først. '
          'Hvis Hærføreren angriber Spionen, vinder Hærføreren.\n\n'
          'Fanen kan erobres af alle modstanderens bevægelige brikker.',
    ),
    _RuleSection(
      'Vinderen',
      'Du vinder spillet, hvis du erobrer modstanderens fane.\n\n'
          'Du kan også vinde, hvis modstanderen ikke længere kan flytte nogen brikker.',
    ),
  ];

  List<_RankItem> get _rankItems {
    switch (_variant) {
      case GameVariant.eighteenTwelve:
        return _ranks1812;
      case GameVariant.classic:
        return _classicRanks;
    }
  }

  String _imagePath(String type) {
    return GameVariantService.imagePath(
      type: type,
      isRed: false,
      variant: _variant,
    );
  }

  Widget _section(_RuleSection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              color: Color(0xFFE0B080),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            section.body,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rang',
          style: TextStyle(
            color: Color(0xFFE0B080),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ..._rankItems.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 46,
                  height: 46,
                  child: Image.asset(
                    _imagePath(item.type),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.help_outline, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.note.isEmpty
                        ? item.name
                        : '${item.name} - ${item.note}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06420B),
      appBar: AppBar(
        title: Text(_loading ? 'Regler' : _title),
        backgroundColor: const Color(0xFF06420B),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF093B09),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ..._sections.map(_section),
                          _rankTable(),
                          const SizedBox(height: 18),
                          const Text(
                            'God fornøjelse',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE0B080),
                      foregroundColor: const Color(0xFF8B0000),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _RuleSection {
  final String title;
  final String body;

  const _RuleSection(this.title, this.body);
}

class _RankItem {
  final String type;
  final String name;
  final String note;

  const _RankItem(this.type, this.name, this.note);
}
