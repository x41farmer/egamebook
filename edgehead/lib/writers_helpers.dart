import 'dart:math';

import 'package:edgehead/edgehead_actors.dart';
import 'package:edgehead/edgehead_event_callbacks_gather.dart';
import 'package:edgehead/edgehead_facts.dart';
import 'package:edgehead/edgehead_facts_strings.dart';
import 'package:edgehead/edgehead_ids.dart';
import 'package:edgehead/edgehead_simulation.dart';
import 'package:edgehead/egamebook/elements/stat_update_element.dart';
import 'package:edgehead/fractal_stories/actor.dart';
import 'package:edgehead/fractal_stories/context.dart';
import 'package:edgehead/fractal_stories/item.dart';
import 'package:edgehead/fractal_stories/items/weapon_type.dart';
import 'package:edgehead/fractal_stories/room.dart';
import 'package:edgehead/fractal_stories/simulation.dart';
import 'package:edgehead/fractal_stories/storyline/storyline.dart';
import 'package:edgehead/fractal_stories/team.dart';
import 'package:edgehead/fractal_stories/world_state.dart';
import 'package:edgehead/src/fight/fight_situation.dart';
import 'package:edgehead/src/room_roaming/room_roaming_situation.dart';
import 'package:meta/meta.dart';

export 'package:edgehead/edgehead_facts_enums.dart';
export 'package:edgehead/edgehead_facts_strings.dart';
export 'package:edgehead/edgehead_ids.dart';
export 'package:edgehead/edgehead_items.dart';

final Entity cultists = Entity(
  id: 978001,
  name: "the Deathless",
  nameIsProperNoun: true,
  pronoun: Pronoun.THEY,
);

final Entity farmers = Entity(
  id: 978002,
  name: "farmers",
  pronoun: Pronoun.THEY,
);

final Entity oracle = Entity(
  id: 978003,
  name: "the Oracle",
  nameIsProperNoun: true,
  pronoun: Pronoun.SHE,
);

bool bothAreAlive(Actor a, Actor b) {
  return a.isAnimatedAndActive && b.isAnimatedAndActive;
}

/// Describes the usage of the compass.
void describeCompass(ActionContext c) {
  final w = c.world;
  final s = c.outputStoryline;

  assert(c.world.currentSituation is RoomRoamingSituation);
  final room = c.playerRoom;
  assert(room.isOnMap);

  Room target;
  if (c.hasItem(northSkullId)) {
    // The skull is with the player.
    target = room;
  } else if (w.actionHasBeenPerformed('give_north_skull_to_oracle')) {
    if (c.hasHappened(evOrcOffensive)) {
      target = c.simulation.getRoomByName('big_o_observatory');
    } else {
      target = c.simulation.getRoomByName('oracle_main');
    }
  } else {
    target = c.simulation.getRoomByName('keep_servants');
  }
  assert(target.isOnMap);

  final dx = target.positionX - room.positionX;
  final dy = target.positionY - room.positionY;

  /// The direction computation is taken from package:piecemeal.
  /// https://github.com/munificent/piecemeal/blob/71aa6567b75aad358328ee8eab0f062c1ea3ed2d/lib/src/vec.dart#L64-L102
  String getDirection(int x, int y) {
    if (x == 0) {
      if (y < 0) {
        return 'above';
      } else if (y == 0) {
        return 'to the skull-shaped device';
      } else {
        return 'below';
      }
    }

    var slope = y / x;

    if (x < 0) {
      if (slope >= 2.0) {
        return 'above';
      } else if (slope >= 0.5) {
        return 'above and to the west';
      } else if (slope >= -0.5) {
        return 'to the west';
      } else if (slope >= -2.0) {
        return 'below and to the west';
      } else {
        return 'below';
      }
    } else {
      if (slope >= 2.0) {
        return 'below';
      } else if (slope >= 0.5) {
        return 'below and to the east';
      } else if (slope >= -0.5) {
        return 'to the east';
      } else if (slope >= -2.0) {
        return 'above and to the east';
      } else {
        return 'above';
      }
    }
  }

  s.add('The compass points ${getDirection(dx, dy)}.', isRaw: true);

  if (room.name == 'keep_bedroom' && !c.knows(kbKeepServantsLocation)) {
    s.add('After a short while, I realize the compass is pointing to a hidden '
        'door in the wall. I open it, and the compass leads me through '
        'twisty little passages to the servants room.');
    c.learn(kbKeepServantsLocation);
    c.movePlayer('keep_servants');
  }
}

/// Battlefield fight.
FightSituation generateBattlefieldFight(ActionContext c,
    RoomRoamingSituation roomRoamingSituation, List<Actor> party) {
  final w = c.outputWorld;
  final weak = _orcsLackCockroaches(c);
  if (weak) {
    c.outputStoryline.add('They seem famished.', isRaw: true);
  }
  final stripped = _orcsLackWeapons(c);
  if (stripped) {
    c.outputStoryline.add('Their weapons look battered.', isRaw: true);
  }
  final leatherJerkinOrcId = w.randomInt();
  final leatherJerkinOrc = Actor.initialized(
      leatherJerkinOrcId, w.randomInt, "orc",
      adjective: 'ordinary',
      nameIsProperNoun: false,
      pronoun: Pronoun.HE,
      currentWeapon: Item.weapon(w.randomInt(), WeaponType.axe,
          adjective: 'battle', firstOwnerId: leatherJerkinOrcId),
      constitution: 1,
      dexterity: weak ? 50 : 100,
      team: defaultEnemyTeam,
      foldFunctionHandle: carelessMonsterFoldFunctionHandle);

  w.actors.addAll([sixtyFiverOrc, leatherJerkinOrc]);

  return FightSituation.initialized(
    w.randomInt(),
    party,
    [sixtyFiverOrc, leatherJerkinOrc],
    "{battlefield|concrete} floor",
    roomRoamingSituation,
    {},
    items: const [],
  );
}

/// The fight west of The Bleeds.
FightSituation generateBleedsGoblinSkirmishPatrol(ActionContext c,
    RoomRoamingSituation roomRoamingSituation, List<Actor> party) {
  final w = c.outputWorld;
  var goblinId = w.randomInt();
  var goblin = Actor.initialized(goblinId, w.randomInt, "goblin",
      adjective: "snarky",
      nameIsProperNoun: false,
      pronoun: Pronoun.HE,
      currentWeapon: Item.weapon(w.randomInt(), WeaponType.spear,
          adjective: "gray", firstOwnerId: goblinId),
      team: defaultEnemyTeam,
      foldFunctionHandle: carelessMonsterFoldFunctionHandle);
  w.actors.add(goblin);
  return FightSituation.initialized(w.randomInt(), party, [goblin],
      "{muddy |wet |}ground", roomRoamingSituation, {});
}

/// God's lair fight.
FightSituation generateGodsLairFight(ActionContext c,
    RoomRoamingSituation roomRoamingSituation, List<Actor> party) {
  final w = c.outputWorld;
  final weak = _orcsLackCockroaches(c);
  if (weak) {
    c.outputStoryline.add('They seem famished.', isRaw: true);
  }
  final stripped = _orcsLackWeapons(c);
  if (stripped) {
    c.outputStoryline.add('Their weapons look battered.', isRaw: true);
  }
  final orcBerserkerId = w.randomInt();
  final orcBerserker = Actor.initialized(
      orcBerserkerId, w.randomInt, "berserker",
      adjective: 'orc',
      nameIsProperNoun: false,
      pronoun: Pronoun.HE,
      currentWeapon: Item.weapon(w.randomInt(), WeaponType.axe,
          name: 'battle axe',
          adjective: 'berserker',
          firstOwnerId: orcBerserkerId),
      constitution: weak ? 2 : 3,
      team: defaultEnemyTeam,
      foldFunctionHandle: carelessMonsterFoldFunctionHandle);
  final orcCaptainId = w.randomInt();
  final orcCaptain = Actor.initialized(orcCaptainId, w.randomInt, 'captain',
      adjective: 'orc',
      nameIsProperNoun: false,
      pronoun: Pronoun.HE,
      currentWeapon: Item.weapon(w.randomInt(), WeaponType.sword,
          adjective: 'labelled', firstOwnerId: orcCaptainId),
      constitution: weak ? 1 : 2,
      team: defaultEnemyTeam,
      foldFunctionHandle: carelessMonsterFoldFunctionHandle);

  w.actors.addAll([orcBerserker, orcCaptain]);

  return FightSituation.initialized(
    w.randomInt(),
    party,
    [orcBerserker, orcCaptain],
    "{|concrete} floor",
    roomRoamingSituation,
    {},
    items: const [],
  );
}

/// "Random encounter"
FightSituation generateRandomEncounter(ActionContext c,
    RoomRoamingSituation roomRoamingSituation, Iterable<Actor> party) {
  final w = c.outputWorld;
  final s = c.outputStoryline;
  final initialPlayer = c.actor;

  final isInside = w.randomBool();
  final groundMaterial = isInside ? "{cold|gray} floor" : "{wet|muddy} ground";

  final enemies = <Actor>[];

  switch (w.randomInt(3)) {
    case 0:
      final hasSpear = w.randomBool();
      enemies.add(_makeGoblin(w, spear: hasSpear, spearAdjective: 'black'));
      s.add(
          "A goblin stands in front of me, "
          "wielding a ${hasSpear ? 'black spear' : 'rusty sword'}.",
          isRaw: true);
      break;
    case 1:
      enemies.add(_makeOrc(w));
      s.add("An orc stands in front of me, wielding a sword.", isRaw: true);
      break;
    case 2:
      final orc = Actor.initialized(6000, w.randomInt, "orc",
          pronoun: Pronoun.HE,
          constitution: 2,
          team: defaultEnemyTeam,
          initiative: 100,
          foldFunctionHandle: carelessMonsterFoldFunctionHandle);
      final equippedOrc = orc.rebuild((b) => b.inventory.equip(
          Item.weapon(w.randomInt(), WeaponType.sword,
              adjective: 'crude', firstOwnerId: orc.id),
          orc.anatomy));
      enemies.add(equippedOrc);
      final goblin = _makeGoblin(w, spear: true);
      enemies.add(goblin);
      s.add(
          "An orc and a goblin stand in front of me. "
          "The orc is wielding a crude sword, the goblin is holding a spear.",
          isRaw: true);
      break;
    default:
      throw UnimplementedError();
  }
  w.actors.addAll(enemies);

  final items = <Item>[];
  if (w.randomBool()) {
    String name;
    if (w.randomBool()) {
      name = w.randomBool() ? "dagger" : "knife";
      items.add(Item.weapon(w.randomInt(), WeaponType.dagger,
          name: name, adjective: 'plain'));
    } else {
      name = w.randomBool() ? "axe" : "hatchet";
      items.add(Item.weapon(w.randomInt(), WeaponType.axe,
          name: name, adjective: 'plain'));
    }

    final numberOfUs = enemies.length == 1 ? "the two of " : "";
    s.add(
        "Between ${numberOfUs}us, "
        "{a plain|an ordinary} $name lies on the $groundMaterial.",
        isRaw: true);
  }

  if (w.randomBool()) {
    String name;

    if (w.randomBool()) {
      name = w.randomBool() ? "rock" : "brick";
      items.add(Item.weapon(w.randomInt(), WeaponType.rock,
          name: name, adjective: 'hefty'));
    } else {
      name = "branch";
      items.add(Item.weapon(w.randomInt(), WeaponType.club,
          name: 'branch', adjective: 'hefty'));
    }

    s.add(
        "I ${items.isNotEmpty ? 'also' : ''} notice "
        "a nice, hefty $name in the ${isInside ? 'rubble' : 'puddle'} "
        "on the ground.",
        isRaw: true);
  }

  if (items.isEmpty) {
    s.add("A quick glance reveals there's nothing useful on the ground.",
        isRaw: true);
  }

  s.addParagraph();

  switch (w.randomInt(4)) {
    case 0:
      initialPlayer.report(s, "<subject> <is> barehanded");
      break;
    case 1:
    case 2:
      final name = w.randomBool() ? "sword" : "scimitar";
      final adjective = w.randomBool() ? "shiny" : "family";
      final sword = Item.weapon(w.randomInt(), WeaponType.sword,
          name: name, adjective: adjective, firstOwnerId: playerId);
      w.updateActorById(
          playerId, (b) => b.inventory.equip(sword, initialPlayer.anatomy));
      initialPlayer.report(s, "<subject> <is> {holding|wielding} a $name");
      break;
    case 3:
      final name = w.randomBool() ? "spear" : "pike";
      final spear = Item.weapon(w.randomInt(), WeaponType.spear,
          name: name, adjective: 'moldy', firstOwnerId: playerId);
      w.updateActorById(
          playerId, (b) => b.inventory.equip(spear, initialPlayer.anatomy));
      initialPlayer.report(s, "<subject> <is> {holding|wielding} a $name");
      break;
    default:
      throw UnimplementedError();
  }

  return FightSituation.initialized(
    w.randomInt(),
    party.where((a) => a.isPlayer).toList(),
    enemies,
    groundMaterial,
    roomRoamingSituation,
    {
      // TODO: optional reinforcement
    },
    items: items,
  );
}

/// The fight at the start of Knights of San Francisco, with Tamara.
FightSituation generateStartFight(ActionContext c,
    RoomRoamingSituation roomRoamingSituation, List<Actor> party) {
  final w = c.outputWorld;
  var firstGoblin = Actor.initialized(firstGoblinId, w.randomInt, "goblin",
      adjective: "feral",
      nameIsProperNoun: false,
      pronoun: Pronoun.HE,
      currentWeapon: Item.weapon(w.randomInt(), WeaponType.sword,
          name: "sword", adjective: "rusty", firstOwnerId: firstGoblinId),
      dexterity: 150,
      // The goblin starts the fight.
      initiative: 2000,
      // For the first 2 rounds, the goblin is invincible. We don't want
      // Tamara to kill him before the player has any chance to do something.
      isInvincible: true,
      team: defaultEnemyTeam,
      foldFunctionHandle: carelessMonsterFoldFunctionHandle);
  w.actors.add(firstGoblin);
  return FightSituation.initialized(
    w.randomInt(),
    party,
    [firstGoblin],
    "{muddy |wet |}ground",
    roomRoamingSituation,
    {
      3: start_make_goblin_not_invincible,
      2: start_tamara_bellows,
    },
  );
}

/// Either returns `we` or `I`, depending on the current state of the party.
///
/// Calls [getPartyOf] in the background.
String getWeOrI(Actor a, Simulation sim, WorldState originalWorld,
    {@required bool capitalized}) {
  final party = getPartyOf(a, sim, originalWorld);
  if (party.length > 1) {
    return capitalized ? 'We' : 'we';
  } else {
    return 'I';
  }
}

Actor _makeGoblin(WorldStateBuilder w,
    {int id,
    bool spear = false,
    String spearAdjective = 'crude',
    String swordAdjective = 'rusty',
    String currentRoomName}) {
  final goblinId = id ?? w.randomInt();
  return Actor.initialized(goblinId, w.randomInt, "goblin",
      nameIsProperNoun: false,
      pronoun: Pronoun.HE,
      currentWeapon: spear
          ? Item.weapon(w.randomInt(), WeaponType.spear,
              adjective: spearAdjective, firstOwnerId: goblinId)
          : Item.weapon(w.randomInt(), WeaponType.sword,
              adjective: swordAdjective, firstOwnerId: goblinId),
      team: defaultEnemyTeam,
      currentRoomName: currentRoomName,
      foldFunctionHandle: carelessMonsterFoldFunctionHandle);
}

Actor _makeOrc(WorldStateBuilder w,
    {int id, int constitution = 2, String swordAdjective = 'orcish'}) {
  final orcId = id ?? w.randomInt();
  return Actor.initialized(orcId, w.randomInt, "orc",
      nameIsProperNoun: false,
      pronoun: Pronoun.HE,
      currentWeapon: Item.weapon(w.randomInt(), WeaponType.sword,
          adjective: swordAdjective, firstOwnerId: orcId),
      constitution: constitution,
      team: defaultEnemyTeam,
      foldFunctionHandle: carelessMonsterFoldFunctionHandle);
}

/// Returns `true` if the cockroach farm has been destroyed and so the orcs
/// and goblins are weak.
bool _orcsLackCockroaches(ApplicabilityContext c) {
  final event = c.world.customHistory.query(name: evOpenedDam).latest;
  if (event == null) return false;

  if (c.world.time.difference(event.time) > const Duration(minutes: 60)) {
    // It's been more than enough time for the lack of food to affect
    // performance.
    return true;
  }
  return false;
}

/// Returns `true` if Sarn has been saved and so the orcs
/// and goblins have worse weapons.
bool _orcsLackWeapons(ApplicabilityContext c) {
  final event = c.world.customHistory.query(name: evSavedSarn).latest;
  if (event == null) return false;

  if (c.world.time.difference(event.time) > const Duration(minutes: 60)) {
    // It's been more than enough time for the lack of a smith to affect
    // weaponry.
    return true;
  }
  return false;
}

extension ActionContextHelpers on ActionContext {
  void movePlayer(String locationName) {
    getRoomRoaming().moveActor(this, locationName);
  }

  /// Learns a fact in a chain of facts.
  void learn(Object o) {
    ChainedFacts.singleton.learnFact(this, o);
  }

  void markHappened(String eventId) {
    outputWorld.recordCustom(eventId);
  }

  void giveStaminaToPlayer(int amount) {
    outputStoryline
        .addCustomElement(StatUpdate.stamina(player.stamina, amount));
    outputWorld.updateActorById(playerId, (b) => b..stamina += amount);
  }

  void giveNewItemToPlayer(Item item) {
    outputWorld.updateActorById(playerId, (b) => b..inventory.add(item));
  }

  void removeItemFromPlayer(int itemId) {
    final item =
        player.inventory.items.singleWhere((item) => item.id == itemId);
    outputWorld.updateActorById(playerId, (b) => b..inventory.remove(item));
  }

  Actor get player {
    return outputWorld.getActorById(playerId);
  }

  void describeWorthiness(
      {@required Entity who,
      @required List<int> what,
      List<int> especially = const [],
      String how = 'approvingly'}) {
    const customEventName = "described_worthiness";

    // Player's items that...
    final items = player.inventory.items
        // ... are impressing the [who] actor ...
        .where((item) => what.contains(item.id))
        // ... and haven't been mentioned by them.
        .where((item) => !world.customHistory
            .query(name: customEventName, actorId: who.id, data: item.id)
            .hasHappened)
        .toList(growable: false);

    if (items.isEmpty) {
      // Nothing to say.
      return;
    }

    final especiallyItems = items
        .where((item) => especially.contains(item.id))
        .toList(growable: false);

    outputStoryline.addEnumeration(
      "<subject> <also> look<s> $how at",
      items,
      null,
      subject: who,
    );

    if (especiallyItems.isNotEmpty && especiallyItems.length < items.length) {
      outputStoryline.addEnumeration(
        "<subject> <is> especially "
        "{entranced|captivated|mesmerized|delighted} by",
        especiallyItems,
        null,
        maxPerSentence: 5,
      );
    }

    for (final item in items) {
      outputWorld.recordCustom(customEventName, data: item.id, actor: who);
    }
  }
}

extension ApplicabilityContextHelpers on ApplicabilityContext {
  /// Returns `true` while player is roaming through Knights and is in an idle
  /// room (i.e. can do things like chatting or reading).
  bool get isInIdleRoom {
    if (world.currentSituation is! RoomRoamingSituation) return false;
    final situation = world.currentSituation as RoomRoamingSituation;
    if (situation.monstersAlive) return false;
    return simulation.getRoomByName(situation.currentRoomName).isIdle;
  }

  Actor get player {
    return world.getActorById(playerId);
  }

  /// The room the player is currently in. If they are in a variant,
  /// then this reports the variant.
  Room get playerRoom {
    return simulation.getRoomByName(player.currentRoomName);
  }

  /// Checks if player knows this fact, or a higher fact.
  ///
  /// For example, if checking [Doghead.somethingCalledDoghead], this method
  /// will return `true` if the player knows the whole
  /// [Doghead.dogheadMyth]. Because of course if you know the whole Doghead
  /// myth, you'll also know that there is something called Doghead.
  bool knows(Object o) {
    return ChainedFacts.singleton.knowsFact(this, o);
  }

  /// Same as [playerRoom] if the player is in a "base" room. If they are in
  /// a variant room, then this getter returns the base (i.e. parent) room.
  Room get playerParentRoom {
    return simulation.getRoomParent(playerRoom);
  }

  RoomRoamingSituation getRoomRoaming() {
    return world.getSituationByName<RoomRoamingSituation>(
        RoomRoamingSituation.className);
  }

  bool hasHappened(String eventId, {int actorId}) {
    return world.customHistory
        .query(name: eventId, actorId: actorId)
        .hasHappened;
  }

  /// Returns `true` if player currently is in a room with [roomName],
  /// or a variant of that room.
  bool inRoomParent(String roomName) {
    final parentRoom = simulation.getRoomParent(playerRoom);
    return parentRoom.name == roomName;
  }

  bool get inPopulatedRoom =>
      inRoomParent('bleeds_main') ||
      inRoomParent('farmers_village') ||
      inRoomParent('staging_area') ||
      inRoomParent('slopes') ||
      inRoomParent('knights_hq_main') ||
      inRoomParent('deathless_village');

  /// Returns `true` if the player is currently in the same room as [actorId].
  ///
  /// Ignores variants, so it's safe even if one of the actors is in
  /// a different "variant".
  bool inRoomWith(int actorId) {
    final playerRoom = simulation.getRoomByName(player.currentRoomName);
    assert(playerRoom.parent == null, "Player is in a variant room.");
    final actor = world.getActorById(actorId);
    final actorRoom = simulation.getRoomByName(actor.currentRoomName);
    assert(actorRoom.parent == null, "Actor is in a variant room.");
    return playerRoom == actorRoom;
  }

  int minutesSinceFirstVisit(String roomName) {
    final first = world.visitHistory
        .query(player, simulation.getRoomByName(roomName))
        .oldest;
    if (first == null) {
      // Player has never been to [roomName].
      return -1;
    }

    final difference = world.time.difference(first.time);
    final result = difference.inMinutes;

    return result;
  }

  /// Returns `true` if [actorId] is currently hurt.
  bool isHurt(int actorId) {
    final actor = world.getActorById(actorId);
    return actor.anatomy.woundedParts.isNotEmpty;
  }

  bool hasItem(int itemId) {
    return player.inventory.items.where((item) => item.id == itemId).isNotEmpty;
  }

  double playerDistanceTo(String roomName) {
    final otherRoom = simulation.getRoomByName(roomName);
    assert(
        otherRoom.isOnMap,
        'Trying to learn player distance to $roomName, '
        'which doesn\'t have position.');
    final room = playerParentRoom;
    if (!room.isOnMap) {
      // Fail silently. The player is in a room with no position.
      return double.infinity;
    }
    return sqrt(pow(otherRoom.positionX - room.positionX, 2) +
        pow(otherRoom.positionY - room.positionY, 2));
  }

  /// Returns `true` if player has ever visited [roomName].
  bool playerHasVisited(String roomName, {bool includeVariants = false}) {
    final room = simulation.getRoomByName(roomName);
    return world.visitHistory
        .query(player, room, includeVariants: includeVariants)
        .hasHappened;
  }
}
