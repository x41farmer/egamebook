/**
 * This library allows authors to create game environment similar to those
 * found in Interactive Fiction (IF) like Zork. It takes inspiration from ZIL,
 * the language that Infocom created for their games in the 1980s. (If you're
 * interested, you can read the internal [Infocom manual for ZIL].)
 * 
 * [Infocom manual for ZIL]: http://www.xlisp.org/zil.pdf
 * 
 * The original ZIL is a dialect of Lisp and had great limitations for 
 * performance and memory reasons. These limitations are largely lifted. For
 * this reason, and for convenience of the author, this library is _not_
 * a recreation of the original ZIL. It is inspired by the capabilities of that
 * engine, because Infocom spent many years building games in it and improving
 * on it.
 * 
 * This library will not let you make IF. The egamebook play format is not
 * about writing text, it's about choosing options. But it should make it
 * possible for you to create living, simulated, explorable environments with
 * items in them, NPCs, wandering enemies, etc.
 * 
 * TODO: why ZIL and not Inform7, for example? hint: this is not IF
 */
library zil;

import 'package:egamebook/src/book/scripter.dart' show goto, echo, choice, throwIfNotInInitBlock, gotoCalledRecently; 
import 'actor.dart';
import 'storyline.dart';
import 'randomly.dart' show Randomly;

part 'zil_room.dart';
part 'zil_exit.dart';
part 'zil_roomnetwork.dart';
part 'zil_item.dart';
part 'zil_actor.dart';
part 'zil_action.dart';

Zil zil = new Zil(rooms);

class Zil {
  RoomNetwork rooms;
  Zil(this.rooms);
  
  void describe(int ticks) {
    rooms.current.showDescription();
    // npcs.describe(ticks, roomsToShow: [rooms.current]);
    if (gotoCalledRecently) return;
    rooms.current.showItems();
    rooms.current.showExits();
    //rooms.update(ticks);
    //npcs.update(ticks);
  }
}