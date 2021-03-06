import 'package:edgehead/edgehead_ids.dart';
import 'package:edgehead/fractal_stories/item.dart';
import 'package:edgehead/fractal_stories/items/weapon_type.dart';

final Item akxe = Item.weapon(
  akxeId,
  WeaponType.axe,
  name: 'akxe',
  adjective: 'steel',
  firstOwnerId: dargId,
  isCleaving: true,
);

final Item banner = Item(
  bannerId,
  name: 'banner',
  adjective: 'red',
);

final Item compass = Item(
  compassId,
  name: 'compass',
  adjective: 'iron',
);

final Item dragonEgg = Item.weapon(
  dragonEggId,
  WeaponType.rock,
  name: 'egg',
  adjective: 'dragon',
);

final Item familyPortrait = Item(
  familyPortraitId,
  name: 'portrait',
  adjective: 'family',
  firstOwnerId: ladyHopeId,
);

final Item katana = Item.weapon(
  katanaId,
  WeaponType.sword,
  name: "katana",
  adjective: "ancient",
  firstOwnerId: ladyHopeId,
  isCleaving: true,
);

final Item lairOfGodStar = Item(
  lairOfGodStarId,
  name: "the Artifact Star",
  nameIsProperNoun: true,
);

final Item letterFromFather = Item(
  letterFromFatherId,
  name: "letter",
  adjective: "father's",
);

final Item northSkull = Item.weapon(
  northSkullId,
  WeaponType.rock,
  name: "the North Skull",
  nameIsProperNoun: true,
);

final Item rockFromMeadow = Item.weapon(
  rockFromMeadowId,
  WeaponType.rock,
  name: "rock",
  adjective: "moldy",
);

final Item sarnHammer = Item.weapon(
  sarnHammerId,
  WeaponType.club,
  name: 'hammer',
  adjective: 'giant',
  bluntDamage: 2,
);

final Item sixtyFiverShield = Item.weapon(
  sixtyFiverShieldId,
  WeaponType.shield,
  name: 'shield',
  adjective: 'sixty-fiver',
  firstOwnerId: sixtyFiverOrcId,
);

final Item tamarasDagger = Item.weapon(
  tamarasDaggerId,
  WeaponType.dagger,
  name: "dagger",
  adjective: "long",
  firstOwnerId: tamaraId,
);
