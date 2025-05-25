import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
      title: 'Random Pokédex',
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

  Pokemon({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.types,
    required this.height,
    required this.weight,
  });

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    List<String> types = [];
    for (var type in json['types']) {
      types.add(type['type']['name']);
    }

    return Pokemon(
      id: json['id'],
      name: json['name'],
      imageUrl: json['sprites']['front_default'] ?? '',
      types: types,
      height: json['height'],
      weight: json['weight'],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Random Pokédex'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (pokemonHistory.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  'List ${currentIndex + 1} of ${pokemonHistory.length}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Navigation buttons
          if (pokemonHistory.length > 1)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: currentIndex > 0 ? _goToPreviousList : null,
                    child: const Text('Previous List'),
                  ),
                  ElevatedButton(
                    onPressed: currentIndex < pokemonHistory.length - 1
                        ? _goToNextList
                        : null,
                    child: const Text('Next List'),
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
                          return Card(
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
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isLoading ? null : _fetchRandomPokemon,
        tooltip: 'Get New Random Pokemon',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
