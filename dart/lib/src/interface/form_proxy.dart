library egb_form_proxy;

import "../shared/form.dart";
import "package:jsonml/jsonml2html5lib.dart";
import 'dart:async';

/**
 * Library that takes the Map generated by [Form.toMap()] and parses it. The
 * [EgbInterface] is then responsible for creating the actual form (for example,
 * by adding DOM elements to page) and listening to user input.
 */
class FormProxy extends FormBase implements BlueprintWithUiRepresentation {
  FormProxy.fromMap(Map<String,Object> map) {
    assert((map["jsonml"] as List)[0] == "Form");
    submitText = (map["jsonml"] as List)[1]["submitText"];
    createElementsFromJsonML(map["jsonml"]);
    FormConfiguration values = new FormConfiguration.fromMap(map["values"]);
    allFormElementsBelowThisOne.forEach((FormElement element) {
      Map<String,Object> elementValues = values.getById(element.id);
      if (elementValues != null) {
        element.updateFromMap(elementValues);
      }
    });
  }

  UiElement buildUiElements(Map<String,UiElementBuilder> builders) {
    return _recursiveCreateUiElement(builders, this);
  }

  /// Mapping from [FormElement] (blueprint) to actual UI representations.
  UiElement uiElement;

  UiElement _recursiveCreateUiElement(Map<String,UiElementBuilder> builders,
                        BlueprintWithUiRepresentation element) {
    if (!builders.containsKey(element.localName)) {
      throw new UnimplementedError("The tag '${element.localName}' is not "
          "among the implemented interface builders "
          "(${builders.keys.join(', ')}).");
    }
    UiElement uiElement = builders[element.localName](element);
    element.uiElement = uiElement;
    if (uiElement.onChange != null) {
      var subscription = uiElement.onChange.listen((_) {
        // Send the state to the Scripter.
        CurrentState state = _createCurrentState(element);
        _streamController.add(state);
      });
      _onChangeSubscriptions.add(subscription);
    }
    for (BlueprintWithUiRepresentation child in element.formElementChildren) {
      UiElement childUiElement = _recursiveCreateUiElement(builders, child);
      uiElement.appendChild(childUiElement.uiRepresentation);
    }
    return uiElement;
  }

  /// Updates all elements according to the provided [config]. If
  /// [unsetWaitingForUpdate] is not [:true:] (default), the elements will stay
  /// in the [UiElement.waitingForUpdate] state (i.e., disabled).
  void update(FormConfiguration config, {bool unsetWaitingForUpdate: true}) {
    allFormElementsBelowThisOne.where((element) => element is UpdatableByMap)
    .forEach((FormElement element) {
      Map<String,Object> map = config.getById(element.id);
      if (map != null) {
        element.updateFromMap(map);
        (element as BlueprintWithUiRepresentation).uiElement.update();
      }
    });
    if (unsetWaitingForUpdate) {
      allFormElementsBelowThisOne.where((element) => element is Input)
      .forEach((element) {
        (element as BlueprintWithUiRepresentation).uiElement.waitingForUpdate =
            false;
      });
    }
  }

  /// Utility function that gathers values from the form. When [submitted] is
  /// [:true:], the form gets disabled. When [setWaitingForUpdate] is [:true:],
  /// all elements are temporarily 'disabled' in order to wait for update from
  /// Scripter.
  CurrentState _createCurrentState(BlueprintWithUiRepresentation elementTouched,
                                   [bool setWaitingForUpdate=true]) {
    CurrentState state = new CurrentState();
    allFormElementsBelowThisOne.where((element) => element is Input)
    .forEach((element) {
      state.add(element.id, (element as BlueprintWithUiRepresentation).uiElement.current);
      if (setWaitingForUpdate) {
        (element as BlueprintWithUiRepresentation).uiElement.waitingForUpdate = true;
      }
    });
    if (setWaitingForUpdate) {
      this.uiElement.waitingForUpdate = true;
    }
    // Events from the Form UiElement itself are Submit events. And events from
    // submit buttons are also Submit events.
    state.submitted = elementTouched is BaseSubmitButton || elementTouched is FormBase;
    if (state.submitted) {
      this.uiElement.disabled = true;
      state.submitterId = elementTouched.id;
      _cancelSubscriptions();
    }
    return state;
  }

  Set<StreamSubscription> _onChangeSubscriptions =
      new Set<StreamSubscription>();
  void _cancelSubscriptions() {
    _onChangeSubscriptions.forEach((StreamSubscription s) => s.cancel());
  }

  StreamController<CurrentState> _streamController =
        new StreamController<CurrentState>();
    Stream<CurrentState> get stream => _streamController.stream;

  void createElementsFromJsonML(List<Object> jsonml) {
    InterfaceForm node = decodeToHtml5Lib(jsonml, customTags: customTagHandlers,
        unsafe: true);
    id = node.id;
    children.addAll(node.children);
  }
}

typedef UiElement UiElementBuilder(FormElement elementBlueprint);

abstract class BlueprintWithUiRepresentation extends FormElement {
  UiElement uiElement;

  BlueprintWithUiRepresentation(String elementClass) : super(elementClass);
}

abstract class UiElement {
  /// The same as the subclass's blueprint, but not typed to a particular
  /// FormElement subtype. This is just convenience, and probably could be
  /// solved more elegantly.
  FormElement _blueprint;
  UiElement(this._blueprint);

  /// Updates the UiElement after the blueprint is changed. Sets
  /// [waitingForUpdate] back to [:false:].
  void update() {
    waitingForUpdate = false;
    disabled = _blueprint.disabledOrInsideDisabledParent;
    hidden = _blueprint.hidden;
  }

  /// Fired every time user interacts with Element and changes something.
  Stream get onChange;

  set disabled(bool value);
  bool get disabled;

  set hidden(bool value);
  bool get hidden;

  /// This is set to [:true:] after the user has interacted with the form and
  /// each [UiElement] in it should be disabled until [update] is called. This
  /// prevents user form setting the form's inputs into an invalid state.
  /// ([EgbScripter] always has a chance to act first, changing values,
  /// hiding inputs, disabling ranges, etc.)
  ///
  /// This can be manifested the same way as [disabled], but is automatically
  /// called on all elements and is meant to be set to false after [EgbScripter]
  /// has had a chance to react to player's input. It shouldn't override
  /// [disabled] state.
  bool waitingForUpdate;
  /// The current value of the UiElement. Only getter, because the values are
  /// set through element blueprint and by calling [update].
  Object get current;
  /// This is the representation of the object in the UI. For HTML, this would
  /// be the [DivElement] that encompasses the [Form], or the [ParagraphElement]
  /// that materializes the [TextOutput].
  Object get uiRepresentation;
  void appendChild(Object childUiRepresentation);
}

/// Maps [FormElement.elementClass] name to a function that takes the JSON
/// objects and returns
Map<String,CustomTagHandler> customTagHandlers = {
  FormBase.elementClass: (Object jsonObject) {
    Map attributes = _getAttributesFromJsonML(jsonObject);
    return new InterfaceForm(attributes["id"]);
  },
  FormSection.elementClass: (Object jsonObject) {
    Map attributes = _getAttributesFromJsonML(jsonObject);
    return new InterfaceFormSection(attributes["name"], attributes["id"]);
  },
  BaseSubmitButton.elementClass: (Object jsonObject) {
    Map attributes = _getAttributesFromJsonML(jsonObject);
    return new InterfaceSubmitButton(attributes["name"], attributes["id"]);
  },
  BaseCheckboxInput.elementClass: (Object jsonObject) {
      Map attributes = _getAttributesFromJsonML(jsonObject);
      return new InterfaceCheckboxInput(attributes["name"], attributes["id"]);
  },
  BaseRangeInput.elementClass: (Object jsonObject) {
    Map attributes = _getAttributesFromJsonML(jsonObject);
    return new InterfaceRangeInput(attributes["name"], attributes["id"]);
  },
  BaseRangeOutput.elementClass: (Object jsonObject) {
    Map attributes = _getAttributesFromJsonML(jsonObject);
    return new InterfaceRangeOutput(attributes["name"], attributes["id"]);
  },
  BaseTextOutput.elementClass: (Object jsonObject) {
    Map attributes = _getAttributesFromJsonML(jsonObject);
    return new InterfaceTextOutput(attributes["id"]);
  },
  BaseMultipleChoiceInput.elementClass: (Object jsonObject) {
    Map attributes = _getAttributesFromJsonML(jsonObject);
    return new InterfaceMultipleChoiceInput(attributes["name"],
        attributes["id"]);
  },
  BaseOption.elementClass: (Object jsonObject) {
    Map attributes = _getAttributesFromJsonML(jsonObject);
    return new InterfaceOption(attributes["text"],
        attributes["selected"] == "true", attributes["id"]);
  }
};

Map<String,Object> _getAttributesFromJsonML(Object jsonObject) {
  // A JsonML element has it's attribute on the second position. Ex.:
  // <a href="#"></a> is ["a", {"href": "#"}].
  return (jsonObject as List)[1] as Map<String,Object>;
}

class InterfaceForm extends FormBase {
  InterfaceForm(String id) {
    this.id = id;
  }
}

class InterfaceFormSection extends FormSection implements BlueprintWithUiRepresentation {
  InterfaceFormSection(String name, String id) : super(name) {
    this.id = id;
  }

  UiElement uiElement;
}

class InterfaceSubmitButton extends BaseSubmitButton implements BlueprintWithUiRepresentation {
  InterfaceSubmitButton(String name, String id) : super(name) {
    this.id = id;
  }

  UiElement uiElement;
}

class InterfaceCheckboxInput extends BaseCheckboxInput
    implements BlueprintWithUiRepresentation {
  InterfaceCheckboxInput(String name, String id) : super(name) {
    this.id = id;
  }

  UiElement uiElement;
}

class InterfaceRangeInput extends BaseRangeInput implements StringRepresentationHolder, BlueprintWithUiRepresentation {
  InterfaceRangeInput(String name, String id) : super(name) {
    this.id = id;
  }
  /// The string representation. This is computed on the [EgbScripter] side
  /// and can be, for example, something like "90%" for [:0.9:] (percentage) or
  /// "intelligent" for [:120:] (IQ).
  String currentStringRepresentation;

  @override
  void updateFromMap(Map<String, Object> map) {
    super.updateFromMap(map);
    currentStringRepresentation = map["__string__"];
  }

  UiElement uiElement;
}

class InterfaceRangeOutput extends BaseRangeOutput implements StringRepresentationHolder, BlueprintWithUiRepresentation {
  InterfaceRangeOutput(String name, String id) : super(name) {
    this.id = id;
  }
  String currentStringRepresentation;

  @override
  void updateFromMap(Map<String, Object> map) {
    super.updateFromMap(map);
    currentStringRepresentation = map["__string__"];
  }

  UiElement uiElement;
}

class InterfaceTextOutput extends BaseTextOutput implements BlueprintWithUiRepresentation {
  InterfaceTextOutput(String id) : super() {
    this.id = id;
  }

  UiElement uiElement;
}

class InterfaceMultipleChoiceInput extends BaseMultipleChoiceInput implements BlueprintWithUiRepresentation {
  InterfaceMultipleChoiceInput(String name, String id) : super(name) {
    this.id = id;
  }

  UiElement uiElement;
}

class InterfaceOption extends BaseOption implements BlueprintWithUiRepresentation {
  InterfaceOption(String text, bool selected, String id) :
    super(text, selected: selected) {
    this.id = id;
  }

  UiElement uiElement;
}