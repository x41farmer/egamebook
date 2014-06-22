library storyline;

import 'randomly.dart';

part 'storyline_pronoun.dart';
part 'storyline_entity.dart';

/**
 * The global instance of storyline which can be used for reporting. The 
 * contents are output to Scripter's [:textBuffer:] either manualy or 
 * automatically by LoopedEvent (before each player interaction).
 */
final Storyline storyline = new Storyline();

/**
 * A single report about an event, atomic part of a story. It can be "John
 * picks up a shovel", "John approaches Jack" or "Jack is dead".
 * 
 * These events are stringed together by [Storyline] to create a coherent,
 * naturally sounding narrative.
 */
class Report {
  Report(this.string, {this.subject, this.object, this.owner, this.but: false, 
    this.positive: false, this.negative: false, this.endSentence: false, 
    this.startSentence: false, this.wholeSentence: false, this.time});
  
  Report.empty() : string = "", subject = null, object = null, owner = null,
      but = false, positive = false, negative = false, endSentence = false,
      startSentence = false, wholeSentence = false, time = null;
  
  final String string;
  final Entity subject;
  final Entity object;
  final Entity owner;
  bool but;
  final bool positive;
  final bool negative;
  final bool endSentence;
  final bool startSentence;
  final bool wholeSentence;
  final int time;
  
  operator [](key) {
    // TODO: get rid of Report field accessed via inefficient [] operator
    switch (key) {
      case 'string': 
        return string;
      case 'subject':
        return subject;
      case 'object':
        return object;
      case 'owner':
        return owner;
      case 'but':
        return but;
      case 'positive':
        return positive;
      case 'negative':
        return negative;
      case 'endSentence':
        return endSentence;
      case 'startSentence':
        return startSentence;
      case 'wholeSentence':
        return wholeSentence;
      case 'time':
        return time;
      default:
        throw new ArgumentError("Invalid key $key.");
    }
  }
  
  // TODO: startOfAction - if there is no report before startOfAction and
  // endOfAction, don't report startOfAction.
  // Prevents: "You set up the laser. The laser is now set up to fire at target."
}

/**
 * Class for reporting a sequence of events in 'natural' language.
 */
class Storyline {
  final StringBuffer strBuf = new StringBuffer();
  final List<Report> reports = new List<Report>();
  int time = 0;

  static const String SUBJECT = "<subject>";
  static const String SUBJECT_POSSESIVE = "<subject's>";
  static const String OWNER = "<owner>";
  static const String OWNER_POSSESIVE = "<owner's>";
  static const String OBJECT_OWNER_POSSESIVE = "<object-owner's>";
  static const String OBJECT = "<object>";
  static const String OBJECT_POSSESIVE = "<object's>";
  static const String SUBJECT_PRONOUN = "<subjectPronoun>";
  static const String SUBJECT_PRONOUN_POSSESIVE = "<subjectPronoun's>";
  static const String SUBJECT_NOUN = "<subjectNoun>";
  static const String OBJECT_PRONOUN = "<objectPronoun>";
  static const String OBJECT_PRONOUN_POSSESIVE = "<objectPronoun's>";
  static const String OWNER_PRONOUN = "<ownerPronoun>";
  static const String OWNER_PRONOUN_POSSESIVE = "<ownerPronoun's>";
  static const String OBJECT_OWNER_PRONOUN_POSSESIVE = "<object-ownerPronoun's>";
  static const String ACTION = "<action>";
  static const String VERB_S = "<s>";
  static const String VERB_ES = "<es>"; // e.g. in "goes"
  static const String VERB_IES = "<ies>"; // e.g. in "tries", "flies"
  static const String VERB_DO = "<does>";
  static const String VERB_BE = "<is>";
  static const String VERB_HAVE = "<has>";
  
  static final RegExp QUOTE_INTERPUNCTION_DUPLICATION = 
      new RegExp(r'''(\w)([\.\?\!])(["'])\.(?=$|\s)''');
  
  /**
   * Add another event to the story.
   * 
   * When [str] ends with [:.:] or [:!:] or [:?:] and starts with a capital
   * letter, [wholeSentence] will automatically be [:true:] for convenience.
   */
  void add(String str, {Entity subject, Entity object, Entity owner, 
    bool but: false, bool positive: false, bool negative: false, 
    bool endSentence: false, bool startSentence: false, 
    bool wholeSentence: false, int time}) {
    
    if (str == null || str == "") {
      return;  // Ignore empty records. 
    }
    
    if (time != null) {
      this.time = time;
    }
    
    if ((str.endsWith(".") || str.endsWith("!") || str.endsWith("?")) &&
        str.startsWith(new RegExp("[A-Z]"))) {
      wholeSentence = true;
    }
    
    reports.add(new Report(str, subject: subject, object: object, owner: owner,
        but: but, positive: positive, negative: negative, 
        endSentence: endSentence, startSentence: startSentence, 
        wholeSentence: wholeSentence, time: time));
  }
  
  /**
   * Add a sentence (or more) enumerating several things ([articles]) at once.
   * Example: "You can see a handkerchief, a brush and a mirror here."
   * You can provide "<also>" for a more human-like enumeration.
   */
  void addEnumeration(String start, Iterable<String> articles, String end, 
                      {Entity subject, Entity object, Entity owner, 
                       int maxPerSentence: 3, String conjuction: "and"}) {
    assert(start != null);
    assert(articles != null);
    if (articles.length == 0) {
      return;  // Don't create any report.
    }
    StringBuffer buf = new StringBuffer();
    buf.write(start.replaceAll("<also>", "").replaceAll("  ", " ").trim()); // TODO: less hacky
    buf.write(" ");
    int i = 0;
    for (String article in articles) {
      if (i > 0) {
        if (i == 1 && article == articles.last) {
          buf.write(" ");
          buf.write(conjuction);
        } else if (i == maxPerSentence - 1) {
          buf.write(", $conjuction");
        } else {
          buf.write(",");
        }
        buf.write(" ");
      }
      buf.write(article);
      i++;
      if (i > maxPerSentence - 1 || article == articles.last) {
        if (end != null) {
          buf.write(" ");
          buf.write(end.replaceAll("<also>", "also"));
        }
        buf.write(".");
        add(buf.toString(), subject: subject, object: object, owner: owner, 
            wholeSentence: true);
        i = 0;
        buf.clear();
        buf.write(start.replaceAll("<also>", "also"));
        buf.write(" ");
      }
    }
  }
  
  void addParagraph() => add("\n\n", wholeSentence: true);

  static String capitalize(String str) {
    str = str.trimLeft();
    if (str.isEmpty) return str;
    String firstLetter = str[0].toUpperCase();
    if (str.length == 1)
      return firstLetter;
    else 
      return "$firstLetter${str.substring(1)}";
  }
  
  String string(int i) {
    if (i < 0 || i >= reports.length)
      return null;
    else
      return reports[i].string;
  }
  
  Entity subject(int i) {
    if (i < 0 || i >= reports.length)
      return null;
    else
      return reports[i].subject;
  }
  
  Entity object(int i) {
    if (i < 0 || i >= reports.length)
      return null;
    else
      return reports[i].object;
  }

  static const int SHORT_TIME = 4;
  static const int VERY_LONG_TIME = 1000;
  int timeSincePrevious(int i) {
    if (reports[i].time == null || !valid(i-1) || reports[i-1].time == null)
      return VERY_LONG_TIME;
    else
      return reports[i].time - reports[i-1].time;
  }

  /// taking care of all the exceptions and rules when comparing different reports
  /// call: [: same('subject', i, i+1) ... :]
  bool same(String key, int i, int j) {
    if (!valid(i) || !valid(j))
      return false;
    if (reports[i][key] == null || reports[j][key] == null)
      return false;
    if (reports[i][key] == reports[j][key])
      return true;
    else
      return false;
  }

  bool exchanged(String key1, String key2, int i, int j) {
    if (!valid(i) || !valid(j))
      return false;
    if (reports[i][key1] == null || reports[j][key1] == null)
      return false;
    if (reports[i][key2] == null || reports[j][key2] == null)
      return false;
    if (reports[i][key1] == reports[j][key2]
     && reports[i][key2] == reports[j][key1])
      return true;
    else
      return false;
  }

  bool valid(int i) {
    if (i >= reports.length || i < 0)
      return false;
    else
      return true;
  }

  bool sameSentiment(int i, int j) {
    if (!valid(i) || !valid(j))
      return false;
    // subject(i) == object(j), opposite sentiments => same sentiment
    if (exchanged('subject', 'object', i, j) && subject(i).isEnemyOf(subject(j))) {
      if (reports[i].positive && reports[j].negative)
        return true;
      if (reports[i].negative && reports[j].positive)
        return true;
    }
    if (!same('subject', i, j))
      return false;
    if (reports[i].positive && reports[j].positive)
      return true;
    if (reports[i].negative && reports[j].negative)
      return true;
    else
      return false;
  }

  bool oppositeSentiment(int i, int j) {
    if (!valid(i) || !valid(j))
      return false;
    // subject(i) == object(j), both have same sentiment => opposite sentiment
    if (exchanged('subject', 'object', i, j) && subject(i).isEnemyOf(subject(j))) {
      if (reports[i].positive && reports[j].positive)
        return true;
      if (reports[i].negative && reports[j].negative)
        return true;
    }
    if (_sameTeam(reports[i].subject, reports[j].subject)) {
      if (reports[i].positive && reports[j].negative)
        return true;
      if (reports[i].negative && reports[j].positive)
        return true;
    }
    return false;
  }
  
  bool _sameTeam(Entity a, Entity b) {
    if (a == null || b == null) return false;
    return a.team == b.team;
  }

  /// makes sure the sentence flows well with the previous sentence(s), then 
  /// calls getString to do in-sentence substitution
  String substitute(int i, String str, {bool useSubjectPronoun: false, 
      bool useObjectPronoun: false}) {
    String result = str.replaceAll(ACTION, string(i));
    if ((useObjectPronoun || same('object', i, i-1)) &&
        !(object(i).pronoun == Pronoun.IT && 
          subject(i).pronoun == Pronoun.IT)) { 
      // if doing something to someone in succession, use pronoun
      // but not if the pronoun is "it" for both subject and object, 
      // that makes sentences like "it makes it"
      
      // Never show "the guard's it".
      result = result.replaceAll("$OBJECT_OWNER_POSSESIVE $OBJECT", 
        object(i).pronoun.nominative);
      result = result.replaceAll("$OBJECT_OWNER_PRONOUN_POSSESIVE $OBJECT", 
        object(i).pronoun.nominative);
      result = result.replaceAll(OBJECT, object(i).pronoun.accusative);
      result = result.replaceAll(OBJECT_POSSESIVE, object(i).pronoun.genitive);
    }
    if (useSubjectPronoun || same('subject', i, i-1)) {
      // Never show "the guard's it".
      result = result.replaceAll("$OWNER_POSSESIVE $SUBJECT", 
          subject(i).pronoun.nominative);
      result = result.replaceAll("$OWNER_PRONOUN_POSSESIVE $SUBJECT", 
          subject(i).pronoun.nominative);
      result = result.replaceAll(SUBJECT, subject(i).pronoun.nominative);
      result = result.replaceAll(SUBJECT_POSSESIVE, subject(i).pronoun.genitive);
    }
    // if someone who was object last sentence is now subject 
    // (and it's not misleading), use pronoun
    if (object(i-1) != null && subject(i) != null && subject(i-1) != null
        && object(i-1) == subject(i) && subject(i-1).pronoun != subject(i).pronoun) {
      
       // Never show "the guard's it".
       result = result.replaceAll("$OWNER_POSSESIVE $SUBJECT", 
           subject(i).pronoun.nominative);
       result = result.replaceAll("$OWNER_PRONOUN_POSSESIVE $SUBJECT", 
           subject(i).pronoun.nominative);
       result = result.replaceAll(SUBJECT, subject(i).pronoun.nominative);
       result = result.replaceAll(SUBJECT_POSSESIVE, subject(i).pronoun.genitive);
    }
    // same as previous, but with object-subject reversed
    if (subject(i-1) != null && object(i) != null && subject(i-1) != null
        && subject(i-1) == object(i) && subject(i-1).pronoun != subject(i).pronoun) {
      
      // Never show "the guard's it".
      result = result.replaceAll("$OBJECT_OWNER_POSSESIVE $OBJECT", 
        object(i).pronoun.nominative);
      result = result.replaceAll("$OBJECT_OWNER_PRONOUN_POSSESIVE $OBJECT", 
        object(i).pronoun.nominative);
      result = result.replaceAll(OBJECT, object(i).pronoun.accusative);
      result = result.replaceAll(OBJECT_POSSESIVE, object(i).pronoun.genitive);
    }
    return getString(result, subject: reports[i].subject, 
        object: reports[i].object, owner: reports[i].owner);
  }

  /// Takes care of substitution of stopwords. Called by substitute().
  static String getString(String str, {Entity subject, Entity object, 
      Entity owner}) {
    String result = str;
    if (subject != null) {
      if (subject.isPlayer) {
        // don't talk like a robot: "player attack wolf" -> "you attack wolf"
        result = result.replaceAll(SUBJECT, Pronoun.YOU.nominative);
        result = result.replaceAll(SUBJECT_POSSESIVE, Pronoun.YOU.genitive);
      }
      
      if (subject.pronoun == Pronoun.YOU || subject.pronoun == Pronoun.THEY) {
        // "you fly there", "they pick up the bananas" ...
        result = result.replaceAll(VERB_S, "");
        result = result.replaceAll(VERB_ES, "");
        result = result.replaceAll(VERB_IES, "y");
        result = result.replaceAll(VERB_DO, "do");
        result = result.replaceAll(VERB_BE, "are");
        result = result.replaceAll(VERB_HAVE, "have");
      } else { 
        // "he flies there", "it picks up the bananas" ...
        result = result.replaceAll(VERB_S, "s");
        result = result.replaceAll(VERB_ES, "es");
        result = result.replaceAll(VERB_IES, "ies");
        result = result.replaceAll(VERB_DO, "does");
        result = result.replaceAll(VERB_BE, "is");
        result = result.replaceAll(VERB_HAVE, "has");
      }
      
      result = result.replaceFirst(SUBJECT, SUBJECT_NOUN);
      result = result.replaceAll(SUBJECT, subject.pronoun.nominative);
      
      result = addParticleToFirstOccurence(result, SUBJECT_NOUN, subject);
      result = result.replaceFirst(SUBJECT_NOUN, subject.name);
      
      result = result.replaceAll(SUBJECT_PRONOUN, subject.pronoun.nominative);
      if (str.contains(new RegExp("$SUBJECT.+$SUBJECT_POSSESIVE"))) {
        // "actor takes his weapon"
        result = result.replaceAll(SUBJECT_POSSESIVE, subject.pronoun.genitive);
      }
      result = addParticleToFirstOccurence(result, SUBJECT_POSSESIVE, subject);
      result = result.replaceFirst(SUBJECT_POSSESIVE, "${subject.name}'s");
      result = result.replaceAll(SUBJECT_POSSESIVE, subject.pronoun.genitive);
      result = result.replaceAll(SUBJECT_PRONOUN_POSSESIVE, subject.pronoun.genitive);
    }
    
    if (object != null) {
      if (object.isPlayer) {
        result = result.replaceAll(OBJECT, Pronoun.YOU.accusative);
        result = result.replaceAll(OBJECT_POSSESIVE, Pronoun.YOU.genitive);
      } else {
        result = addParticleToFirstOccurence(result, OBJECT, object);
        result = result.replaceAll(OBJECT, object.name);
        // TODO: change first to name, next to pronoun?
      }
      result = result.replaceAll(OBJECT_PRONOUN, object.pronoun.accusative);
      if (str.contains(new RegExp("$OBJECT.+$OBJECT_POSSESIVE"))) { // "actor takes his weapon"
        result = result.replaceAll(OBJECT_POSSESIVE, object.pronoun.genitive);
      }
      result = addParticleToFirstOccurence(result, OBJECT_POSSESIVE, object);
      result = result.replaceFirst(OBJECT_POSSESIVE, "${object.name}'s");
      result = result.replaceAll(OBJECT_POSSESIVE, object.pronoun.genitive);
      result = result.replaceAll(OBJECT_PRONOUN_POSSESIVE, object.pronoun.genitive);
    }
    if (owner != null) {
      if (owner.isPlayer) { 
        result = result.replaceAll(OWNER, Pronoun.YOU.accusative);
        result = result.replaceAll(OWNER_POSSESIVE, Pronoun.YOU.genitive);
      } else {
        result = addParticleToFirstOccurence(result, OWNER, owner);
        result = result.replaceAll(OWNER, owner.name);
      }
      result = result.replaceAll(OWNER_PRONOUN, owner.pronoun.nominative);
      if (str.contains(new RegExp("$OWNER.+$OWNER_POSSESIVE"))) {
        //print("owner < owner_possessive: $str");
        // "the ship and her gun"
        result = result.replaceAll(OWNER_POSSESIVE, owner.pronoun.genitive);
      }
      result = addParticleToFirstOccurence(result, OWNER_POSSESIVE, owner);
      result = result.replaceFirst(OWNER_POSSESIVE, "${owner.name}'s");
      result = result.replaceAll(OWNER_POSSESIVE, owner.pronoun.genitive);
      result = result.replaceAll(OWNER_PRONOUN_POSSESIVE, owner.pronoun.genitive);
    } else {
      // owner == null
      // Get rid of <owner's> and <owner> when none is set up.
      result = result.replaceAll(OWNER, "");
      result = result.replaceAll(OWNER_POSSESIVE, "");
    }

    return Randomly.parse(result);
  }

  /// Adds [:the:] or [:a:] to first occurence of [SUB_STRING] (like 
  /// [:<subject>:]) in [string]. The next occurences will be automatically
  /// converted to pronouns. 
  static String addParticleToFirstOccurence(String string, String SUB_STRING, 
                                            Entity entity) {
    // Make sure we don't add particles to "your car" etc.
    if (string.indexOf("$OWNER_POSSESIVE $SUB_STRING") != -1 ||
        string.indexOf("$OWNER_PRONOUN_POSSESIVE $SUB_STRING") != -1) {
      return string;
    }
    
    if (!entity.nameIsProperNoun) {
      if (entity.alreadyMentioned) {
        string = string.replaceFirst(SUB_STRING, "the $SUB_STRING");
      } else {
        if (entity.name.startsWith(new RegExp(r"[aeiouy]", 
            caseSensitive: false))) {
          string = string.replaceFirst(SUB_STRING, "an $SUB_STRING");
        } else {
          string = string.replaceFirst(SUB_STRING, "a $SUB_STRING");
        }
        entity.alreadyMentioned = true;
      }
    }
    return string;
  }
  
  Storyline();

  void clear() {
    reports.clear();
    strBuf.clear();
  }

  /// The main function that strings reports together into a coherent story.
  String toString() {
    reports.removeWhere((report) => report.string == "");
    final int length = reports.length;
    if (length < 1)
      return "";
    final int MAX_SENTENCE_LENGTH = 3;
    int lastEndSentence = -1;
    bool endPreviousSentence = true; // previous sentence was ended
    bool endThisSentence = false; // this sentence needs to be ended
    bool but = false; // this next sentence needs to start with but
    for (int i=0; i < length; i++) {
      // TODO: look into future - make sentences like "Although __, __" 
      // TODO: ^^ can be done by 2 for loops
      // TODO: add "while you're still sweeping your legs" when it's been a long time since we said that
      // TODO: glue sentences together first (look ahead, optimize)
      if (i != 0) {
        // solve flow with previous sentence
        bool objectSubjectSwitch = exchanged('subject', 'object', i-1, i);
        but = (reports[i].but || oppositeSentiment(i, i-1)) 
              && !reports[i-1].but;
        reports[i].but = but;
        endPreviousSentence = 
          (i - lastEndSentence >= MAX_SENTENCE_LENGTH) 
          || endThisSentence
          || reports[i].startSentence 
          || reports[i-1].endSentence
          || reports[i].wholeSentence
          || !(same('subject', i, i-1) || objectSubjectSwitch)
          || (but && (i - lastEndSentence > 1))
          || (but && reports[i-1].but)
          || (timeSincePrevious(i) > SHORT_TIME);
        endThisSentence = false;

        if (endPreviousSentence) {
          if (reports[i-1].wholeSentence) // don't write period after "Boom!"
            strBuf.write(" ");
          else
            strBuf.write(". ");
          if (but && !reports[i].wholeSentence)
            strBuf.write(Randomly.choose(["But ", "But ", "However, ", 
                                       "Nonetheless, ", "Nevertheless, "]));
        } else { // let's try and glue [i-1] and [i] into one sentence
          if (but) {
            strBuf.write(Randomly.choose([" but ", " but ", " yet ", ", but "]));
            if (!sameSentiment(i, i+1))
              endThisSentence = true;
          } else {
            if (same('subject', i, i-1) && string(i).startsWith("$SUBJECT ")
                && i < length - 1  && i - lastEndSentence < MAX_SENTENCE_LENGTH - 1 &&
                !(timeSincePrevious(i+1) > SHORT_TIME) /* Makes the sentence end. TODO: check for all sentence ending logic. */) {
              strBuf.write(", ");
            } else {
              strBuf.write(Randomly.choose([" and ", " and ", ", and "]));
              endThisSentence = true;
            }
          }
        }
      }

      String report = string(i);
      // clear subjects when e.g. "Wolf hits you, it growls, it strikes again."
      if (!endPreviousSentence)
        if (same('subject', i, i-1))
          if (string(i-1).startsWith("$SUBJECT "))
            if (report.startsWith("$SUBJECT "))
              report = report.replaceFirst("$SUBJECT ", "");

      report = substitute(i, report);

      if ((endPreviousSentence || i == 0) && !but)
        report = capitalize(report);

      // add the actual report
      strBuf.write(report);

      // set variables for next iteration
      if (endPreviousSentence)
        lastEndSentence = i;
      if (reports[i].wholeSentence)
        endThisSentence = true;
    }

    // add last dot
    if (!reports[length-1].wholeSentence)
      strBuf.write(".");
    
    String s = strBuf.toString();
    
    // Fix extra dots after quotes.
    s = s.replaceAllMapped(QUOTE_INTERPUNCTION_DUPLICATION, (Match m) {
      return "${m[1]}${m[2]}${m[3]}";
    });

    return s;
  }
}