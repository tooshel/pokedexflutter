import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokéizer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const PokemonListPage(),
    );
  }
}

class Pokemon {
  final int id;
  final String name;
  final String imageUrl;
  final List<String> types;
  final int height;
  final int weight;
  final int baseExperience;
  final List<PokemonAbility> abilities;
  final List<PokemonStat> stats;
  final PokemonSprites sprites;
  final PokemonCries? cries;
  final List<PokemonMove> moves;

  Pokemon({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.types,
    required this.height,
    required this.weight,
    required this.baseExperience,
    required this.abilities,
    required this.stats,
    required this.sprites,
    this.cries,
    required this.moves,
  });

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    List<String> types = [];
    for (var type in json['types']) {
      types.add(type['type']['name']);
    }

    List<PokemonAbility> abilities = [];
    for (var ability in json['abilities']) {
      abilities.add(PokemonAbility.fromJson(ability));
    }

    List<PokemonStat> stats = [];
    for (var stat in json['stats']) {
      stats.add(PokemonStat.fromJson(stat));
    }

    List<PokemonMove> moves = [];
    for (var move in json['moves'].take(10)) { // Limit to first 10 moves
      moves.add(PokemonMove.fromJson(move));
    }

    return Pokemon(
      id: json['id'],
      name: json['name'],
      imageUrl: json['sprites']['front_default'] ?? '',
      types: types,
      height: json['height'],
      weight: json['weight'],
      baseExperience: json['base_experience'] ?? 0,
      abilities: abilities,
      stats: stats,
      sprites: PokemonSprites.fromJson(json['sprites']),
      cries: json['cries'] != null ? PokemonCries.fromJson(json['cries']) : null,
      moves: moves,
    );
  }
}

class PokemonAbility {
  final String name;
  final bool isHidden;

  PokemonAbility({required this.name, required this.isHidden});

  factory PokemonAbility.fromJson(Map<String, dynamic> json) {
    return PokemonAbility(
      name: json['ability']['name'],
      isHidden: json['is_hidden'],
    );
  }
}

class PokemonStat {
  final String name;
  final int baseStat;

  PokemonStat({required this.name, required this.baseStat});

  factory PokemonStat.fromJson(Map<String, dynamic> json) {
    return PokemonStat(
      name: json['stat']['name'],
      baseStat: json['base_stat'],
    );
  }
}

class PokemonSprites {
  final String? frontDefault;
  final String? frontShiny;
  final String? backDefault;
  final String? backShiny;
  final String? frontFemale;
  final String? backFemale;

  PokemonSprites({
    this.frontDefault,
    this.frontShiny,
    this.backDefault,
    this.backShiny,
    this.frontFemale,
    this.backFemale,
  });

  factory PokemonSprites.fromJson(Map<String, dynamic> json) {
    return PokemonSprites(
      frontDefault: json['front_default'],
      frontShiny: json['front_shiny'],
      backDefault: json['back_default'],
      backShiny: json['back_shiny'],
      frontFemale: json['front_female'],
      backFemale: json['back_female'],
    );
  }

  List<String> getAllSprites() {
    List<String> sprites = [];
    if (frontDefault != null) sprites.add(frontDefault!);
    if (backDefault != null) sprites.add(backDefault!);
    if (frontShiny != null) sprites.add(frontShiny!);
    if (backShiny != null) sprites.add(backShiny!);
    if (frontFemale != null) sprites.add(frontFemale!);
    if (backFemale != null) sprites.add(backFemale!);
    return sprites;
  }
}

class PokemonCries {
  final String? latest;
  final String? legacy;

  PokemonCries({this.latest, this.legacy});

  factory PokemonCries.fromJson(Map<String, dynamic> json) {
    return PokemonCries(
      latest: json['latest'],
      legacy: json['legacy'],
    );
  }
}

class PokemonMove {
  final String name;

  PokemonMove({required this.name});

  factory PokemonMove.fromJson(Map<String, dynamic> json) {
    return PokemonMove(
      name: json['move']['name'],
    );
  }
}

class PokemonListPage extends StatefulWidget {
  const PokemonListPage({super.key});

  @override
  State<PokemonListPage> createState() => _PokemonListPageState();
}

class _PokemonListPageState extends State<PokemonListPage> {
  List<List<Pokemon>> pokemonHistory = [];
  int currentIndex = -1;
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchRandomPokemon();
  }

  Future<void> _fetchRandomPokemon() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      List<Pokemon> newPokemonList = [];
      Set<int> usedIds = {};
      Random random = Random();

      // Fetch 10 random Pokemon (there are 1010+ Pokemon, so we'll use 1-1000 range)
      while (newPokemonList.length < 10) {
        int randomId = random.nextInt(1000) + 1;

        if (!usedIds.contains(randomId)) {
          usedIds.add(randomId);

          final response = await http.get(
            Uri.parse('https://pokeapi.co/api/v2/pokemon/$randomId'),
          );

          if (response.statusCode == 200) {
            final pokemonData = json.decode(response.body);
            newPokemonList.add(Pokemon.fromJson(pokemonData));
          }
        }
      }

      setState(() {
        // Remove any lists after current index when adding new list
        if (currentIndex < pokemonHistory.length - 1) {
          pokemonHistory = pokemonHistory.sublist(0, currentIndex + 1);
        }

        pokemonHistory.add(newPokemonList);
        currentIndex = pokemonHistory.length - 1;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to fetch Pokemon: $e';
        isLoading = false;
      });
    }
  }

  void _goToPreviousList() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
    }
  }

  void _goToNextList() {
    if (currentIndex < pokemonHistory.length - 1) {
      setState(() {
        currentIndex++;
      });
    }
  }

  List<Pokemon> get currentPokemonList {
    if (currentIndex >= 0 && currentIndex < pokemonHistory.length) {
      return pokemonHistory[currentIndex];
    }
    return [];
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return Colors.red;
      case 'water':
        return Colors.blue;
      case 'grass':
        return Colors.green;
      case 'electric':
        return Colors.yellow;
      case 'psychic':
        return Colors.pink;
      case 'ice':
        return Colors.lightBlue;
      case 'dragon':
        return Colors.indigo;
      case 'dark':
        return Colors.black87;
      case 'fairy':
        return Colors.pinkAccent;
      case 'fighting':
        return Colors.brown;
      case 'poison':
        return Colors.purple;
      case 'ground':
        return Colors.orange;
      case 'flying':
        return Colors.cyan;
      case 'bug':
        return Colors.lightGreen;
      case 'rock':
        return Colors.grey;
      case 'ghost':
        return Colors.deepPurple;
      case 'steel':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  int _getCrossAxisCount(double screenWidth) {
    if (screenWidth < 600) {
      return 2; // Mobile
    } else if (screenWidth < 900) {
      return 3; // Tablet
    } else if (screenWidth < 1200) {
      return 4; // Small desktop
    } else {
      return 5; // Large desktop
    }
  }

  void _showPokemonDetail(Pokemon pokemon) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PokemonDetailPage(pokemon: pokemon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pokéizer',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Your Random Pokémon Encounter',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (pokemonHistory.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  'Team ${currentIndex + 1} of ${pokemonHistory.length}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Navigation buttons - always visible
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: currentIndex > 0 ? _goToPreviousList : null,
                  icon: const Icon(Icons.arrow_back_ios),
                  label: const Text('Previous Team'),
                ),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : _fetchRandomPokemon,
                  icon: const Icon(Icons.refresh),
                  label: const Text('New Team'),
                ),
                ElevatedButton.icon(
                  onPressed: currentIndex < pokemonHistory.length - 1
                      ? _goToNextList
                      : null,
                  icon: const Icon(Icons.arrow_forward_ios),
                  label: const Text('Next Team'),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchRandomPokemon,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : currentPokemonList.isEmpty
                ? const Center(child: Text('No Pokemon loaded'))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
                      return GridView.builder(
                        padding: const EdgeInsets.all(8.0),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                        ),
                        itemCount: currentPokemonList.length,
                        itemBuilder: (context, index) {
                          final pokemon = currentPokemonList[index];
                          return GestureDetector(
                            onTap: () => _showPokemonDetail(pokemon),
                            child: Card(
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Pokemon image
                                    Expanded(
                                      flex: 3,
                                      child: pokemon.imageUrl.isNotEmpty
                                          ? Image.network(
                                              pokemon.imageUrl,
                                              fit: BoxFit.contain,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return const Icon(
                                                      Icons.catching_pokemon,
                                                      size: 64,
                                                      color: Colors.grey,
                                                    );
                                                  },
                                            )
                                          : const Icon(
                                              Icons.catching_pokemon,
                                              size: 64,
                                              color: Colors.grey,
                                            ),
                                    ),

                                    // Pokemon name
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        pokemon.name.toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),

                                    // Pokemon ID
                                    Text(
                                      '#${pokemon.id.toString().padLeft(3, '0')}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),

                                    // Pokemon types
                                    Expanded(
                                      flex: 1,
                                      child: Wrap(
                                        spacing: 4.0,
                                        children: pokemon.types.map((type) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0,
                                              vertical: 2.0,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getTypeColor(type),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              type.toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),

                                    // Height and weight
                                    Text(
                                      'H: ${(pokemon.height / 10).toStringAsFixed(1)}m W: ${(pokemon.weight / 10).toStringAsFixed(1)}kg',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class PokemonDetailPage extends StatefulWidget {
  final Pokemon pokemon;

  const PokemonDetailPage({super.key, required this.pokemon});

  @override
  State<PokemonDetailPage> createState() => _PokemonDetailPageState();
}

class _PokemonDetailPageState extends State<PokemonDetailPage> {
  int currentSpriteIndex = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlayingAudio = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return Colors.red;
      case 'water':
        return Colors.blue;
      case 'grass':
        return Colors.green;
      case 'electric':
        return Colors.yellow;
      case 'psychic':
        return Colors.pink;
      case 'ice':
        return Colors.lightBlue;
      case 'dragon':
        return Colors.indigo;
      case 'dark':
        return Colors.black87;
      case 'fairy':
        return Colors.pinkAccent;
      case 'fighting':
        return Colors.brown;
      case 'poison':
        return Colors.purple;
      case 'ground':
        return Colors.orange;
      case 'flying':
        return Colors.cyan;
      case 'bug':
        return Colors.lightGreen;
      case 'rock':
        return Colors.grey;
      case 'ghost':
        return Colors.deepPurple;
      case 'steel':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _playCry(String? audioUrl) async {
    if (audioUrl == null) return;

    setState(() {
      isPlayingAudio = true;
    });

    try {
      await _audioPlayer.play(UrlSource(audioUrl));
      await _audioPlayer.onPlayerComplete.first;
    } catch (e) {
      print('Error playing audio: $e');
    } finally {
      setState(() {
        isPlayingAudio = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sprites = widget.pokemon.sprites.getAllSprites();
    final currentSprite = sprites.isNotEmpty ? sprites[currentSpriteIndex] : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pokemon.name.toUpperCase()),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pokemon Image and Basic Info
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Pokemon Image with navigation
                    Container(
                      height: 200,
                      child: Row(
                        children: [
                          if (sprites.length > 1)
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  currentSpriteIndex = (currentSpriteIndex - 1 + sprites.length) % sprites.length;
                                });
                              },
                              icon: const Icon(Icons.arrow_back_ios),
                            ),
                          Expanded(
                            child: currentSprite != null
                                ? Image.network(
                                    currentSprite,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.catching_pokemon,
                                        size: 100,
                                        color: Colors.grey,
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons.catching_pokemon,
                                    size: 100,
                                    color: Colors.grey,
                                  ),
                          ),
                          if (sprites.length > 1)
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  currentSpriteIndex = (currentSpriteIndex + 1) % sprites.length;
                                });
                              },
                              icon: const Icon(Icons.arrow_forward_ios),
                            ),
                        ],
                      ),
                    ),
                    if (sprites.length > 1)
                      Text(
                        'Sprite ${currentSpriteIndex + 1} of ${sprites.length}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    const SizedBox(height: 16),
                    
                    // Basic Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '#${widget.pokemon.id.toString().padLeft(3, '0')}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const Text('ID', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${(widget.pokemon.height / 10).toStringAsFixed(1)}m',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Height', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${(widget.pokemon.weight / 10).toStringAsFixed(1)}kg',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Weight', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${widget.pokemon.baseExperience}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Base EXP', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Types
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Types',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      children: widget.pokemon.types.map((type) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          decoration: BoxDecoration(
                            color: _getTypeColor(type),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            type.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Pokemon Cries
            if (widget.pokemon.cries != null)
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pokémon Cries',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (widget.pokemon.cries!.latest != null)
                            ElevatedButton.icon(
                              onPressed: isPlayingAudio ? null : () => _playCry(widget.pokemon.cries!.latest),
                              icon: Icon(isPlayingAudio ? Icons.volume_up : Icons.play_arrow),
                              label: const Text('Latest Cry'),
                            ),
                          const SizedBox(width: 8),
                          if (widget.pokemon.cries!.legacy != null)
                            ElevatedButton.icon(
                              onPressed: isPlayingAudio ? null : () => _playCry(widget.pokemon.cries!.legacy),
                              icon: Icon(isPlayingAudio ? Icons.volume_up : Icons.play_arrow),
                              label: const Text('Legacy Cry'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Stats
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Base Stats',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...widget.pokemon.stats.map((stat) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                stat.name.replaceAll('-', ' ').toUpperCase(),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${stat.baseStat}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: stat.baseStat / 255.0, // Max stat is usually around 255
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  stat.baseStat > 100 ? Colors.green : 
                                  stat.baseStat > 50 ? Colors.orange : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Abilities
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Abilities',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...widget.pokemon.abilities.map((ability) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                ability.name.replaceAll('-', ' ').toUpperCase(),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            if (ability.isHidden)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.purple,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'HIDDEN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Moves
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sample Moves',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: widget.pokemon.moves.map((move) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            move.name.replaceAll('-', ' ').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
