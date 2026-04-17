enum ObstacleType {
  trafficCone(true, 32, 48, 'cone'),
  barrel(true, 40, 40, 'barrel'),
  rock(true, 48, 32, 'rock'),
  puddle(true, 64, 16, 'puddle'),
  bird(false, 48, 32, 'bird');

  const ObstacleType(this.isGround, this.width, this.height, this.assetName);

  final bool isGround;
  final double width;
  final double height;
  final String assetName;

  bool get isAir => !isGround;

  String get asset => 'assets/images/obstacles/$assetName.png';

  static List<ObstacleType> get groundTypes =>
      values.where((t) => t.isGround).toList();

  static List<ObstacleType> get airTypes =>
      values.where((t) => t.isAir).toList();
}
