class GameConstants {
  GameConstants._();

  // Player physics — parabolic arc, peak ~2× character height
  static const double jumpVelocity = -640.0;
  static const double gravity = 850.0;
  // Forward momentum during jump — persists after landing so the player
  // gains ground by jumping. If they don't jump, backwardDriftSpeed pulls
  // them back each frame.
  static const double jumpForwardVelocity = 300.0;
  static const double backwardDriftSpeed = 70.0;
  // Horizontal movement bounds (fraction of screen width)
  static const double minPlayerX = 40.0;
  static const double maxPlayerXFactor = 0.55;
  static const int maxLives = 5;
  static const double invincibilityDuration = 1.5;
  static const double blinkInterval = 0.1;

  // Game speed & difficulty
  static const double initialSpeed = 200.0;
  static const double maxSpeed = 500.0;
  static const double speedIncrement = 10.0;
  static const double speedIncrementInterval = 5.0; // seconds
  static const double initialSpawnInterval = 2.5;
  static const double minSpawnInterval = 0.8;
  static const double spawnIntervalDecrement = 0.1;
  static const double spawnIntervalDecrementEvery = 10.0; // seconds

  // Score thresholds
  static const double airObstacleThreshold = 500.0;
  static const double comboObstacleThreshold = 1000.0;

  // Easy mode: slower & simpler for the first N seconds so kids can learn
  static const double easyModeDuration = 180.0; // 3 minutes
  static const double easyModeSpeed = 150.0; // slower than initialSpeed
  static const double easyModeSpawnInterval = 4.0; // sparser obstacles

  // Scoring
  static const double scoreMultiplier = 0.1;

  // Layout
  static const double groundY = 0.75; // fraction of screen height
  static const double playerWidth = 120.0;
  static const double playerHeight = 120.0;
  static const double duckHeight = 60.0;
  static const int maxPlayers = 8;

  // Multi-player scaling
  static const double smallScaleFactor = 0.75;
  static const int smallScaleThreshold = 5;

  // Network
  static const int defaultPort = 8080;
  static const String websocketPath = '/ws';

  // Countdown
  static const int countdownSeconds = 3;

  // Motion detection — balanced sensitivity (kids game, web+native)
  static const int sensorSampleRateHz = 50;
  static const int sensorSampleIntervalMs = 20;
  static const int filterWindowSize = 5;
  static const int jumpDebounceDurationMs = 600; // prevent rapid double-jumps
  static const int duckSustainMs = 200; // must hold crouch briefly
  static const double jumpThresholdFactor = 0.65; // less sensitive to noise
  static const double calibrationStandStillSeconds = 2.0;
  static const int calibrationJumpCount = 2;
}
