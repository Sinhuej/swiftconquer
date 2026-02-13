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
        theme: ThemeData.dark(),
        home: const GameScreen(),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Offset? dragStart;
  Offset? dragEnd;

  @override
  void initState() {
    super.initState();
    context.read<GameState>().startGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<GameState>(
        builder: (context, game, _) {
          return Row(
            children: [
              // Main game area
              Expanded(
                child: GestureDetector(
                  onTapDown: (details) => _handleTap(details.localPosition, game),
                  onPanStart: (details) => setState(() => dragStart = details.localPosition),
                  onPanUpdate: (details) => setState(() => dragEnd = details.localPosition),
                  onPanEnd: (_) {
                    if (dragStart != null && dragEnd != null) {
                      game.boxSelect(_getSelectionRect());
                    }
                    setState(() {
                      dragStart = null;
                      dragEnd = null;
                    });
                  },
                  onSecondaryTapDown: (details) => game.rightClick(details.localPosition),
                  child: Container(
                    color: Colors.green.shade900,
                    child: Stack(
                      children: [
                        CustomPaint(
                          painter: GamePainter(game),
                          size: Size.infinite,
                        ),
                        if (dragStart != null && dragEnd != null)
                          CustomPaint(
                            painter: SelectionBoxPainter(dragStart!, dragEnd!),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Right sidebar (build menu)
              Container(
                width: 200,
                color: Colors.black87,
                child: Column(
                  children: [
                    // Resources
                    Container(
                      padding: const EdgeInsets.all(10),
                      color: Colors.red.shade900,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ðŸ’° \$${game.credits}', style: const TextStyle(fontSize: 16)),
                          Text('âš¡ ${game.energy}', style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                    const Divider(),
                    
                    // Buildings tab
                    Expanded(
                      child: ListView(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('BUILDINGS', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          _buildButton('ðŸ­ Refinery\n\$800', 800, () => game.startBuildingConstruction('refinery')),
                          _buildButton('ðŸ° Barracks\n\$300', 300, () => game.startBuildingConstruction('barracks')),
                          _buildButton('ðŸ­ Factory\n\$600', 600, () => game.startBuildingConstruction('factory')),
                          _buildButton('ðŸ—¼ Defense Turret\n\$500', 500, () => game.startBuildingConstruction('turret')),
                          _buildButton('ðŸŽ¯ Intelligence\n\$700', 700, () => game.startBuildingConstruction('intelligence')),
                          
                          const Divider(),
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('INFANTRY', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          _buildButton('ðŸ‘· Rifleman\n\$100', 100, () => game.trainUnit('rifleman')),
                          _buildButton('ðŸ”§ Engineer\n\$150', 150, () => game.trainUnit('engineer')),
                          _buildButton('ðŸŽ¯ Sniper\n\$200', 200, () => game.trainUnit('sniper')),
                          _buildButton('ðŸ•µï¸ Spy\n\$300', 300, () => game.trainUnit('spy')),
                          
                          const Divider(),
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('VEHICLES', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          _buildButton('ðŸš— Light Tank\n\$400', 400, () => game.trainUnit('lighttank')),
                          _buildButton('ðŸšœ Heavy Tank\n\$700', 700, () => game.trainUnit('heavytank')),
                          _buildButton('ðŸ’¥ Artillery\n\$600', 600, () => game.trainUnit('artillery')),
                        ],
                      ),
                    ),
                    
                    // Selected unit info
                    if (game.selectedUnits.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(10),
                        color: Colors.blue.shade900,
                        child: Text(
                          '${game.selectedUnits.length} unit(s) selected',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildButton(String text, int cost, VoidCallback onPressed) {
    return Consumer<GameState>(
      builder: (context, game, _) {
        final canAfford = game.credits >= cost;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ElevatedButton(
            onPressed: canAfford ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade900,
              padding: const EdgeInsets.all(8),
            ),
            child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
          ),
        );
      },
    );
  }

  void _handleTap(Offset position, GameState game) {
    game.selectAt(position);
  }

  Rect _getSelectionRect() {
    if (dragStart == null || dragEnd == null) return Rect.zero;
    return Rect.fromPoints(dragStart!, dragEnd!);
  }
}

class GamePainter extends CustomPainter {
  final GameState game;
  
  GamePainter(this.game);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw buildings
    for (var building in game.buildings) {
      final color = building.owner == 'player' ? Colors.blue : Colors.red;
      final paint = Paint()..color = building.isInfiltrated ? Colors.purple : color;
      
      final icon = _getBuildingIcon(building.type);
      
      canvas.drawRect(
        Rect.fromCenter(center: building.position, width: 80, height: 80),
        paint,
      );
      
      // Building icon/text
      final textPainter = TextPainter(
        text: TextSpan(text: icon, style: const TextStyle(fontSize: 40)),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, building.position + const Offset(-20, -20));
      
      // Infiltration indicator
      if (building.isInfiltrated) {
        final glowPaint = Paint()
          ..color = Colors.purple
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawRect(
          Rect.fromCenter(center: building.position, width: 85, height: 85),
          glowPaint,
        );
        
        // Show reduced income
        final incomePainter = TextPainter(
          text: TextSpan(
            text: '\$${building.getIncome()}/s',
            style: const TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        incomePainter.paint(canvas, building.position + const Offset(-15, 45));
      }
      
      // Health bar
      _drawHealthBar(canvas, building.position, building.health, building.maxHealth);
    }
    
    // Draw units
    for (var unit in game.units) {
      final color = unit.owner == 'player' ? Colors.blue : Colors.red;
      final paint = Paint()..color = color;
      
      // Selection highlight
      if (game.selectedUnits.contains(unit)) {
        final highlightPaint = Paint()
          ..color = Colors.yellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(unit.position, 18, highlightPaint);
      }
      
      // Draw unit based on type
      final icon = _getUnitIcon(unit.type);
      final textPainter = TextPainter(
        text: TextSpan(text: icon, style: const TextStyle(fontSize: 20)),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, unit.position + const Offset(-10, -10));
      
      // Health bar for units
      _drawHealthBar(canvas, unit.position, unit.health, unit.maxHealth);
      
      // Draw movement path
      if (unit.destination != null) {
        final pathPaint = Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..strokeWidth = 1;
        canvas.drawLine(unit.position, unit.destination!, pathPaint);
      }
    }
  }

  void _drawHealthBar(Canvas canvas, Offset pos, double health, double maxHealth) {
    const barWidth = 30.0;
    const barHeight = 4.0;
    final healthPercent = (health / maxHealth).clamp(0.0, 1.0);
    
    final bgPaint = Paint()..color = Colors.red;
    final fgPaint = Paint()..color = Colors.green;
    
    canvas.drawRect(
      Rect.fromLTWH(pos.dx - barWidth/2, pos.dy - 25, barWidth, barHeight),
      bgPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(pos.dx - barWidth/2, pos.dy - 25, barWidth * healthPercent, barHeight),
      fgPaint,
    );
  }

  String _getBuildingIcon(String type) {
    switch (type) {
      case 'refinery': return 'ðŸ­';
      case 'barracks': return 'ðŸ°';
      case 'factory': return 'ðŸ—ï¸';
      case 'turret': return 'ðŸ—¼';
      case 'intelligence': return 'ðŸŽ¯';
      default: return 'ðŸ¢';
    }
  }

  String _getUnitIcon(String type) {
    switch (type) {
      case 'rifleman': return 'ðŸ‘·';
      case 'engineer': return 'ðŸ”§';
      case 'sniper': return 'ðŸŽ¯';
      case 'spy': return 'ðŸ•µï¸';
      case 'lighttank': return 'ðŸš—';
      case 'heavytank': return 'ðŸšœ';
      case 'artillery': return 'ðŸ’¥';
      default: return 'âš«';
    }
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) => true;
}

class SelectionBoxPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  
  SelectionBoxPainter(this.start, this.end);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final rect = Rect.fromPoints(start, end);
    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(SelectionBoxPainter oldDelegate) => true;
}

// ============================================================
// GAME STATE
// ============================================================

class GameState extends ChangeNotifier {
  int credits = 3000;
  int energy = 100;
  
  List<Unit> units = [];
  List<Building> buildings = [];
  List<Unit> selectedUnits = [];
  
  String? buildingToBuild;
  
  Timer? gameLoop;
  final random = Random();

  void startGame() {
    credits = 3000;
    energy = 100;
    
    // Player starts with Command HQ and Refinery
    buildings.add(Building(
      owner: 'player',
      position: const Offset(100, 200),
      type: 'refinery',
    ));
    
    buildings.add(Building(
      owner: 'player',
      position: const Offset(100, 350),
      type: 'barracks',
    ));
    
    // Enemy base
    buildings.add(Building(
      owner: 'enemy',
      position: const Offset(700, 200),
      type: 'refinery',
    ));
    
    buildings.add(Building(
      owner: 'enemy',
      position: const Offset(700, 350),
      type: 'barracks',
    ));
    
    // Starting units
    for (int i = 0; i < 3; i++) {
      units.add(Unit('player', 'rifleman', Offset(150 + i * 30, 250)));
      units.add(Unit('enemy', 'rifleman', Offset(650 - i * 30, 250)));
    }
    
    gameLoop = Timer.periodic(const Duration(milliseconds: 50), (_) => update());
    notifyListeners();
  }

  void update() {
    // Update units
    for (var unit in units) {
      unit.update(units, buildings);
    }
    
    // Generate income
    for (var building in buildings.where((b) => b.type == 'refinery')) {
      if (building.owner == 'player') {
        credits += (building.getIncome() / 20).round();
      }
    }
    
    // Simple AI
    if (random.nextDouble() < 0.01) {
      final enemyBarracks = buildings.where((b) => b.owner == 'enemy' && b.type == 'barracks').toList();
      if (enemyBarracks.isNotEmpty) {
        units.add(Unit('enemy', 'rifleman', enemyBarracks.first.position + const Offset(30, 0)));
      }
    }
    
    // Remove dead
    units.removeWhere((u) => u.health <= 0);
    buildings.removeWhere((b) => b.health <= 0);
    
    notifyListeners();
  }

  void selectAt(Offset position) {
    selectedUnits.clear();
    
    for (var unit in units.where((u) => u.owner == 'player')) {
      if ((unit.position - position).distance < 20) {
        selectedUnits.add(unit);
        break;
      }
    }
    
    notifyListeners();
  }

  void boxSelect(Rect rect) {
    selectedUnits.clear();
    
    for (var unit in units.where((u) => u.owner == 'player')) {
      if (rect.contains(unit.position)) {
        selectedUnits.add(unit);
      }
    }
    
    notifyListeners();
  }

  void rightClick(Offset position) {
    if (selectedUnits.isEmpty) return;
    
    // Check if clicking on enemy
    Unit? enemyTarget;
    for (var unit in units.where((u) => u.owner == 'enemy')) {
      if ((unit.position - position).distance < 20) {
        enemyTarget = unit;
        break;
      }
    }
    
    Building? buildingTarget;
    for (var building in buildings) {
      if ((building.position - position).distance < 50) {
        buildingTarget = building;
        break;
      }
    }
    
    for (var unit in selectedUnits) {
      if (enemyTarget != null) {
        unit.attackTarget = enemyTarget;
        unit.destination = null;
      } else if (buildingTarget != null && buildingTarget.owner != 'player' && unit.type == 'spy') {
        unit.targetBuilding = buildingTarget;
        unit.destination = null;
      } else {
        unit.destination = position;
        unit.attackTarget = null;
      }
    }
    
    notifyListeners();
  }

  void trainUnit(String type) {
    final cost = _getUnitCost(type);
    if (credits < cost) return;
    
    final barracks = buildings.firstWhere(
      (b) => b.owner == 'player' && (b.type == 'barracks' || b.type == 'factory'),
      orElse: () => buildings.first,
    );
    
    credits -= cost;
    units.add(Unit('player', type, barracks.position + Offset(random.nextDouble() * 50, 50)));
    notifyListeners();
  }

  void startBuildingConstruction(String type) {
    final cost = _getBuildingCost(type);
    if (credits < cost) return;
    
    buildingToBuild = type;
    // In full version, would let user place the building
    // For now, auto-place
    credits -= cost;
    buildings.add(Building(
      owner: 'player',
      position: Offset(100 + buildings.length * 120.0, 500),
      type: type,
    ));
    notifyListeners();
  }

  int _getUnitCost(String type) {
    switch (type) {
      case 'rifleman': return 100;
      case 'engineer': return 150;
      case 'sniper': return 200;
      case 'spy': return 300;
      case 'lighttank': return 400;
      case 'heavytank': return 700;
      case 'artillery': return 600;
      default: return 100;
    }
  }

  int _getBuildingCost(String type) {
    switch (type) {
      case 'refinery': return 800;
      case 'barracks': return 300;
      case 'factory': return 600;
      case 'turret': return 500;
      case 'intelligence': return 700;
      default: return 300;
    }
  }

  @override
  void dispose() {
    gameLoop?.cancel();
    super.dispose();
  }
}

// ============================================================
// ENTITIES
// ============================================================

class Unit {
  String owner;
  String type;
  Offset position;
  Offset? destination;
  Unit? attackTarget;
  Building? targetBuilding;
  
  double health;
  double maxHealth;
  double speed;
  double damage;
  double attackRange;
  
  Unit(this.owner, this.type, this.position)
    : health = _getMaxHealth(type),
      maxHealth = _getMaxHealth(type),
      speed = _getSpeed(type),
      damage = _getDamage(type),
      attackRange = _getRange(type);

  static double _getMaxHealth(String type) {
    switch (type) {
      case 'rifleman': return 50;
      case 'engineer': return 40;
      case 'sniper': return 30;
      case 'spy': return 25;
      case 'lighttank': return 150;
      case 'heavytank': return 300;
      case 'artillery': return 100;
      default: return 50;
    }
  }

  static double _getSpeed(String type) {
    switch (type) {
      case 'sniper': return 2.5;
      case 'spy': return 3.5;
      case 'lighttank': return 3.0;
      case 'heavytank': return 2.0;
      case 'artillery': return 1.5;
      default: return 3.0;
    }
  }

  static double _getDamage(String type) {
    switch (type) {
      case 'rifleman': return 5;
      case 'sniper': return 30;
      case 'lighttank': return 15;
      case 'heavytank': return 35;
      case 'artillery': return 50;
      default: return 5;
    }
  }

  static double _getRange(String type) {
    switch (type) {
      case 'sniper': return 150;
      case 'artillery': return 200;
      default: return 50;
    }
  }

  void update(List<Unit> units, List<Building> buildings) {
    // Spy infiltration
    if (type == 'spy' && targetBuilding != null) {
      final dist = (targetBuilding!.position - position).distance;
      if (dist < 60) {
        targetBuilding!.infiltrate(owner);
        targetBuilding = null;
      } else {
        _moveToward(targetBuilding!.position);
      }
      return;
    }
    
    // Attack target
    if (attackTarget != null && !attackTarget!.isDead) {
      final dist = (attackTarget!.position - position).distance;
      if (dist <= attackRange) {
        attackTarget!.health -= damage * 0.05;
      } else {
        _moveToward(attackTarget!.position);
      }
      return;
    }
    
    // Move to destination
    if (destination != null) {
      if ((destination! - position).distance < 5) {
        destination = null;
      } else {
        _moveToward(destination!);
      }
    }
  }

  void _moveToward(Offset target) {
    final direction = (target - position);
    final distance = direction.distance;
    if (distance > 0) {
      final normalized = Offset(direction.dx / distance, direction.dy / distance);
      position = position + (normalized * speed);
    }
  }

  bool get isDead => health <= 0;
}

class Building {
  String owner;
  Offset position;
  String type;
  
  double health;
  double maxHealth;
  bool isInfiltrated = false;
  String? infiltratedBy;
  
  Building({
    required this.owner,
    required this.position,
    required this.type,
  }) : health = _getMaxHealth(type),
       maxHealth = _getMaxHealth(type);

  static double _getMaxHealth(String type) {
    switch (type) {
      case 'refinery': return 500;
      case 'barracks': return 400;
      case 'factory': return 600;
      case 'turret': return 300;
      case 'intelligence': return 350;
      default: return 400;
    }
  }

  void infiltrate(String spyOwner) {
    isInfiltrated = true;
    infiltratedBy = spyOwner;
  }

  int getIncome() {
    if (type != 'refinery') return 0;
    return isInfiltrated ? 1 : 10;
  }
}
