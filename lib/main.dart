import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  runApp(const SwiftConquerApp());
}

class SwiftConquerApp extends StatelessWidget {
  const SwiftConquerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameState(),
      child: MaterialApp(
        title: 'SwiftConquer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.red,
          scaffoldBackgroundColor: Colors.black,
        ),
        home: const MainMenuScreen(),
      ),
    );
  }
}

// ============================================================
// MAIN MENU
// ============================================================

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade900, Colors.black],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'SWIFTCONQUER',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FactionSelectScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade900,
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                ),
                child: const Text('START GAME', style: TextStyle(fontSize: 20)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// FACTION SELECTION
// ============================================================

class FactionSelectScreen extends StatefulWidget {
  const FactionSelectScreen({super.key});

  @override
  State<FactionSelectScreen> createState() => _FactionSelectScreenState();
}

class _FactionSelectScreenState extends State<FactionSelectScreen> {
  String? selectedFaction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SELECT FACTION'),
        backgroundColor: Colors.red.shade900,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildFactionCard(
                  'Iron Dominion',
                  '20% cheaper vehicles',
                  Colors.grey,
                ),
                _buildFactionCard(
                  'Solar Compact',
                  '25% better market trades',
                  Colors.amber,
                ),
                _buildFactionCard(
                  'Shadow Accord',
                  '50% more effective SPIES!',
                  Colors.purple,
                ),
              ],
            ),
          ),
          if (selectedFaction != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () {
                  context.read<GameState>().startGame(selectedFaction!);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const GameScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('BEGIN MISSION', style: TextStyle(fontSize: 18)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFactionCard(String name, String bonus, Color color) {
    final isSelected = selectedFaction == name;
    
    return Card(
      color: isSelected ? color.withOpacity(0.3) : Colors.grey.shade900,
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: Icon(Icons.shield, color: color, size: 40),
        title: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text(bonus),
        trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
        onTap: () => setState(() => selectedFaction = name),
      ),
    );
  }
}

// ============================================================
// GAME SCREEN
// ============================================================

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<GameState>(
        builder: (context, game, _) {
          return Stack(
            children: [
              // Game field
              Container(
                color: Colors.green.shade900,
                child: CustomPaint(
                  painter: GamePainter(game),
                  size: Size.infinite,
                ),
              ),
              
              // Top HUD
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  color: Colors.black.withOpacity(0.7),
                  child: Row(
                    children: [
                      Text('ðŸ’° Credits: ${game.credits}', style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 20),
                      Text('âš¡ Energy: ${game.energy}', style: const TextStyle(fontSize: 16)),
                      const Spacer(),
                      if (game.selectedBuilding != null && game.selectedBuilding!.isInfiltrated)
                        const Text('ðŸ•µï¸ BUILDING INFILTRATED!', 
                          style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              
              // Build menu
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 100,
                  color: Colors.black.withOpacity(0.8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildButton(context, 'ðŸ‘· Infantry\n\$100', () => game.trainUnit('infantry')),
                      _buildButton(context, 'ðŸšœ Tank\n\$500', () => game.trainUnit('tank')),
                      _buildButton(context, 'ðŸ•µï¸ SPY\n\$300', () => game.trainUnit('spy')),
                      _buildButton(context, 'ðŸ­ Refinery\n\$800', () => game.buildRefinery()),
                    ],
                  ),
                ),
              ),
              
              // Victory/Defeat message
              if (game.gameOver)
                Container(
                  color: Colors.black.withOpacity(0.9),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          game.playerWon ? 'VICTORY!' : 'DEFEAT',
                          style: TextStyle(
                            fontSize: 60,
                            color: game.playerWon ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('BACK TO MENU'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade900,
        padding: const EdgeInsets.all(10),
      ),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
    );
  }
}

// ============================================================
// GAME PAINTER
// ============================================================

class GamePainter extends CustomPainter {
  final GameState game;
  
  GamePainter(this.game);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw buildings
    for (var building in game.buildings) {
      final paint = Paint()
        ..color = building.isInfiltrated 
            ? Colors.purple.shade400  // Purple if infiltrated by spy!
            : (building.owner == 'player' ? Colors.blue : Colors.red);
      
      canvas.drawRect(
        Rect.fromCenter(
          center: building.position,
          width: 60,
          height: 60,
        ),
        paint,
      );
      
      // Draw infiltration indicator
      if (building.isInfiltrated) {
        final glowPaint = Paint()
          ..color = Colors.purple.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawCircle(building.position, 35, glowPaint);
      }
      
      // Draw income (reduced if infiltrated!)
      final income = building.getIncome();
      final textPainter = TextPainter(
        text: TextSpan(
          text: '\$${income}/s',
          style: TextStyle(
            color: building.isInfiltrated ? Colors.purple : Colors.white,
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      
      textPainter.paint(
        canvas,
        building.position + const Offset(-20, 35),
      );
    }
    
    // Draw units
    for (var unit in game.units) {
      final paint = Paint()
        ..color = unit.owner == 'player' ? Colors.blue : Colors.red;
      
      if (unit.type == 'spy') {
        // Draw spy as triangle
        final path = Path()
          ..moveTo(unit.position.dx, unit.position.dy - 10)
          ..lineTo(unit.position.dx - 8, unit.position.dy + 10)
          ..lineTo(unit.position.dx + 8, unit.position.dy + 10)
          ..close();
        canvas.drawPath(path, paint);
        
        // Spy icon
        final textPainter = TextPainter(
          text: const TextSpan(text: 'ðŸ•µï¸', style: TextStyle(fontSize: 16)),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, unit.position + const Offset(-8, -20));
      } else if (unit.type == 'tank') {
        canvas.drawRect(
          Rect.fromCenter(center: unit.position, width: 20, height: 15),
          paint,
        );
      } else {
        canvas.drawCircle(unit.position, 8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) => true;
}

// ============================================================
// GAME STATE & LOGIC
// ============================================================

class GameState extends ChangeNotifier {
  String playerFaction = '';
  int credits = 2000;
  int energy = 100;
  
  List<GameUnit> units = [];
  List<GameBuilding> buildings = [];
  
  GameBuilding? selectedBuilding;
  bool gameOver = false;
  bool playerWon = false;
  
  Timer? gameLoop;
  final random = Random();

  void startGame(String faction) {
    playerFaction = faction;
    credits = 2000;
    energy = 100;
    units.clear();
    buildings.clear();
    gameOver = false;
    
    // Create starting buildings
    buildings.add(GameBuilding(
      owner: 'player',
      position: const Offset(100, 200),
      type: 'refinery',
    ));
    
    buildings.add(GameBuilding(
      owner: 'enemy',
      position: const Offset(700, 200),
      type: 'refinery',
    ));
    
    // Start game loop
    gameLoop = Timer.periodic(const Duration(milliseconds: 100), (_) => update());
    
    // Spawn initial units
    for (int i = 0; i < 3; i++) {
      units.add(GameUnit('player', 'infantry', Offset(120 + i * 30, 250)));
      units.add(GameUnit('enemy', 'infantry', Offset(680 - i * 30, 250)));
    }
    
    notifyListeners();
  }

  void update() {
    if (gameOver) return;
    
    // Update units
    for (var unit in units) {
      unit.update(buildings, units);
    }
    
    // Generate income from buildings
    for (var building in buildings) {
      if (building.owner == 'player') {
        credits += (building.getIncome() / 10).round(); // Per 100ms
      }
    }
    
    // AI behavior
    _updateAI();
    
    // Check victory
    final playerBuildings = buildings.where((b) => b.owner == 'player').length;
    final enemyBuildings = buildings.where((b) => b.owner == 'enemy').length;
    
    if (playerBuildings == 0) {
      gameOver = true;
      playerWon = false;
    } else if (enemyBuildings == 0) {
      gameOver = true;
      playerWon = true;
    }
    
    notifyListeners();
  }

  void _updateAI() {
    // Simple AI: occasionally train units
    if (random.nextDouble() < 0.02) {
      final enemyRefinery = buildings.firstWhere((b) => b.owner == 'enemy');
      units.add(GameUnit('enemy', 'infantry', enemyRefinery.position + const Offset(30, 0)));
    }
  }

  void trainUnit(String type) {
    final cost = type == 'spy' ? 300 : (type == 'tank' ? 500 : 100);
    if (credits < cost) return;
    
    credits -= cost;
    
    final playerBase = buildings.firstWhere((b) => b.owner == 'player');
    units.add(GameUnit('player', type, playerBase.position + Offset(random.nextDouble() * 50, 50)));
    notifyListeners();
  }

  void buildRefinery() {
    if (credits < 800) return;
    
    credits -= 800;
    buildings.add(GameBuilding(
      owner: 'player',
      position: Offset(100 + buildings.length * 80.0, 300),
      type: 'refinery',
    ));
    notifyListeners();
  }

  @override
  void dispose() {
    gameLoop?.cancel();
    super.dispose();
  }
}

// ============================================================
// GAME ENTITIES
// ============================================================

class GameUnit {
  String owner;
  String type;
  Offset position;
  Offset? target;
  GameBuilding? targetBuilding; // For spy infiltration!
  double health = 100;
  
  GameUnit(this.owner, this.type, this.position);

  void update(List<GameBuilding> buildings, List<GameUnit> units) {
    // Spies move toward enemy buildings
    if (type == 'spy' && targetBuilding == null) {
      final enemyBuildings = buildings.where((b) => b.owner != owner).toList();
      if (enemyBuildings.isNotEmpty) {
        targetBuilding = enemyBuildings.first;
      }
    }
    
    // Move toward target
    if (targetBuilding != null) {
      final dx = targetBuilding!.position.dx - position.dx;
      final dy = targetBuilding!.position.dy - position.dy;
      final dist = sqrt(dx * dx + dy * dy);
      
      if (dist < 50 && type == 'spy') {
        // INFILTRATE THE BUILDING!
        targetBuilding!.infiltrate(owner);
        targetBuilding = null;
      } else if (dist > 5) {
        position = Offset(
          position.dx + (dx / dist) * 2,
          position.dy + (dy / dist) * 2,
        );
      }
    } else {
      // Move toward enemy base
      final enemyBuildings = buildings.where((b) => b.owner != owner).toList();
      if (enemyBuildings.isNotEmpty) {
        final target = enemyBuildings.first.position;
        final dx = target.dx - position.dx;
        final dy = target.dy - position.dy;
        final dist = sqrt(dx * dx + dy * dy);
        
        if (dist > 5) {
          position = Offset(
            position.dx + (dx / dist) * (type == 'tank' ? 1.5 : 2),
            position.dy + (dy / dist) * (type == 'tank' ? 1.5 : 2),
          );
        }
      }
    }
  }
}

class GameBuilding {
  String owner;
  Offset position;
  String type;
  bool isInfiltrated = false;
  String? infiltratedBy;
  double baseIncome = 10.0;
  
  GameBuilding({
    required this.owner,
    required this.position,
    required this.type,
  });

  void infiltrate(String spyOwner) {
    if (!isInfiltrated) {
      isInfiltrated = true;
      infiltratedBy = spyOwner;
    }
  }

  int getIncome() {
    // SPY MECHANIC: Infiltrated buildings only give 10% income!
    return (isInfiltrated ? baseIncome * 0.1 : baseIncome).round();
  }
}
