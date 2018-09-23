import 'package:edgehead/egamebook/elements/choice_block_element.dart';
import 'package:edgehead/egamebook/elements/choice_element.dart';
import 'package:edgehead/egamebook/elements/choice_tree.dart';
import 'package:edgehead/egamebook/elements/save_element.dart';
import 'package:test/test.dart';

void main() {
  final emptySaveGame = SaveGameBuilder()..saveGameSerialized = '';

  test("generates no groups when no >> choices", () {
    final choice1 = Choice((b) => b
      ..markdownText = 'Slap him with a trout'
      ..isImplicit = false);
    final choice2 = Choice((b) => b
      ..markdownText = 'Slap him with a leaf'
      ..isImplicit = false);

    final choiceBlock = (ChoiceBlockBuilder()
          ..choices.addAll([
            choice1,
            choice2,
          ])
          ..saveGame = emptySaveGame)
        .build();

    final tree = ChoiceTree(choiceBlock);

    expect(tree.root.choices, unorderedMatches(<Choice>[choice1, choice2]));
    expect(tree.root.groups, isEmpty);
  });

  test("generates simple tree with two >> choices", () {
    final choice1 = Choice((b) => b
      ..markdownText = 'Slap him >> with a trout'
      ..isImplicit = false);
    final choice2 = Choice((b) => b
      ..markdownText = 'Slap him >> with a leaf'
      ..isImplicit = false);

    final choiceBlock = (ChoiceBlockBuilder()
          ..choices.addAll([
            choice1,
            choice2,
          ])
          ..saveGame = emptySaveGame)
        .build();

    final tree = ChoiceTree(choiceBlock);

    expect(tree.root.choices, isEmpty);
    expect(tree.root.groups, hasLength(1));
    expect(tree.root.groups.single.groups, isEmpty);
    expect(tree.root.groups.single.choices, hasLength(2));
  });

  test("generates tree with choices of order of 2 (have two >>)", () {
    final choice1 = Choice((b) => b
      ..markdownText = 'Attack goblin >> by slapping him >> with a trout'
      ..isImplicit = false);
    final choice2 = Choice((b) => b
      ..markdownText = 'Attack goblin >> by slapping him >> with a leaf'
      ..isImplicit = false);

    final choiceBlock = (ChoiceBlockBuilder()
          ..choices.addAll([
            choice1,
            choice2,
          ])
          ..saveGame = emptySaveGame)
        .build();

    final tree = ChoiceTree(choiceBlock);

    expect(tree.root.choices, isEmpty);
    expect(tree.root.groups, hasLength(1));
    expect(tree.root.groups.single.choices, isEmpty);
    expect(tree.root.groups.single.groups, hasLength(1));
    expect(tree.root.groups.single.groups.single.choices,
        unorderedMatches(<Choice>[choice1, choice2]));
  });
}
