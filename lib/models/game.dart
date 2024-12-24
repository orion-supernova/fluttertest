class Location {
  final String name;
  final List<String> roles;

  const Location({
    required this.name,
    required this.roles,
  });
}

class GameState {
  final String gameId;
  final List<String> players;
  final Location? selectedLocation;
  final String? spy;
  final bool isGameStarted;

  const GameState({
    required this.gameId,
    required this.players,
    this.selectedLocation,
    this.spy,
    this.isGameStarted = false,
  });
}
