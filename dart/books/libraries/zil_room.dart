part of zil;

/**
 * A [Room] is the a location in the game space. It's [name] must correspond to
 * an [EgbPage] name.
 */
class Room extends Entity implements Described {
  //PerformFunction onEnter;
  final List<int> coordinates;
  final Set<Item> items;
  final Set<Exit> exits;
  
  String description;
  // TODO: custom "you are in"
  
  bool visited = false;
  
  Room(String name, this.description, Iterable exits, 
      { //this.onEnter, 
       this.coordinates: const [0, 0, 0], Iterable items: const []}) 
      : this.exits = new Set.from(exits),
        this.items = new Set.from(items),
        super(name) {
    //throwIfNotInInitBlock("Cannot create room on the fly.");
    if (description == null) description = name;
    this.exits.forEach((exit) => exit.from = this);
    items.forEach((Item item) => item.location = this);
  }
  
  /// The RoomNetwork this Room is a part of.
  RoomNetwork network;
  
  /// Shows the room, it's inhabitants, items and exits during the next [ticks].
  /// TODO: don't repeat yourself (naive implementation = save storyline, compare)
  void describe(int ticks) {
    showDescription();
    storyline.addParagraph();
    if (rooms.actors != null) {
      showActors();
      actors.updateAll(ticks, currentRoom: rooms.current);
      if (gotoCalledRecently) return;
    }
    storyline.addParagraph();
    showItems();
    showExits();
  }
  
  showActors() {
    // TODO custom reports from actors
    var presentActors = actors.npcs.where((ZilActor actor) => actor.isIn(this));
    if (presentActors.length > 1) {
      storyline.addEnumeration("<subject> {|can }see<s>", 
          presentActors.map((ZilActor actor) => actor.name), 
          "{|in }here", subject: player);
    } else if (presentActors.length == 1) {
      presentActors.single.report("<subject> is {|in }here");
    }
  }
  
  /// Shows the text associated with the room.
  void showDescription() {
    // TODO  custom
    storyline.add("<subject> <is> in $description", subject: player);
    visited = true;
  }

  /// Shows all items currently visible in the room.
  void showItems() {
    // TODO: first, show items that can handle their own description.
    storyline.addEnumeration("{<subject> can see|there is} <also>", 
        items.map((item) => item.description), "{in |}here", subject: player);
  }
  
  /// Example: "You can leave to corridor left, squeeze through the hatchway 
  /// or use the ladder to ..."
  void showExits() {
    storyline.addEnumeration("<subject> can {leave|go}", 
        exits.map((exit) => "to ${exit.to.description}"), null, 
        subject: player, conjuction: "or");
  }
  
  bool contains(Item item) => items.contains(item);  // TODO: freestanding vs in possession
}

typedef void PerformFunction();
