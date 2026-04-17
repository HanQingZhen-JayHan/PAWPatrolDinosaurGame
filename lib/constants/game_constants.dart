class GameConstants {
  GameConstants._();

  // Player physics
  static const double jumpVelocity = -600.0;
  static const double gravity = 1800.0;
  static const int maxLives = 3;
  static const double invincibilityDuration = 1.5;
  static const double blinkInterval = 0.1;

  // Game speed & difficulty
  static const double initialSpeed = 300.0;
  static const double maxSpeed = 800.0;
  static const double speedIncrement = 10.0;
  static const double speedIncrementInterval = 5.0; // seconds
  static const double initialSpawnInterval = 2.5;
  static const double minSpawnInterval = 0.8;
  static const double spawnIntervalDecrement = 0.1;
  static const double spawnIntervalDecrementEvery = 10.0; // seconds

  // Score thresholds
  static const double airObstacleThreshold = 500.0;
  static const double comboObstacleThreshold = 1000.0;

  // Scoring
  static const double scoreMultiplier = 0.1;

  // Layout
  static const double groundY = 0.75; // fraction of screen height
  static const double playerWidth = 64.0;
  static const double playerHeight = 64.0;
  static const double duckHeight = 32.0;
  static const int maxPlayers = 8;

  // Multi-player scaling
  static const double smallScaleFactor = 0.75;
  static const int smallScaleThreshold = 5;

  // Network
  static const int defaultPort = 8080;
  static const String websocketPath = '/ws';

  // Countdown
  static const int countdownSeconds = 3;

  // Motion detection
  static const int sensorSampleRateHz = 50;
  static const int sensorSampleIntervalMs = 20;
  static const int filterWindowSize = 5;
  static const int jumpDebounceDurationMs = 500;
  static const int duckSustainMs = 200;
  static const double jumpThresholdFactor = 0.6;
  static const double calibrationStandStillSeconds = 3.0;
  static const int calibrationJumpCount = 3;
}
