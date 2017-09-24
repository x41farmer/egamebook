#import('/Users/filiph/Programs/egamebook/dart/egb_library.dart');

// this will be rewritten with the actual file
#import('/Users/filiph/Programs/egamebook/dart/library/tis_001.dart');

#import('dart:io');
#import('dart:isolate');

void DEBUG_CMD(String str) {
  // print("CMD: $str");
}

class CmdlineInterface implements UserInterface {
  ReceivePort _receivePort;
  SendPort _scripterPort;

  /**
    Constructor.
    */
  CmdlineInterface() {
    DEBUG_CMD("Command line interface starting.");

    // create [ReceivePort] and bind it to the callback method [receiveFromScripter].
    _receivePort = new ReceivePort();
    _receivePort.receive(receiveFromScripter);

    // create the isolate and send it the first handshake
    _scripterPort = spawnFunction(createScripter);
    _scripterPort.send(
        new Message.Start().toJson(),
        _receivePort.toSendPort()
    );

    cmdLine = new StringInputStream(stdin);
  }

  StringInputStream cmdLine;
  List choices;

  void receiveFromScripter(String messageJson, SendPort replyTo) {
    Message message = new Message.fromJson(messageJson);
    DEBUG_CMD("We have a message from Scripter: ${message.type}.");
    if (message.type == Message.MSG_END_OF_BOOK) {
      DEBUG_CMD("We are at the end of book. Closing.");
      stdin.close();
      _scripterPort.send(new Message.Quit().toJson());
      _receivePort.close();
    } else {
      if (message.type == Message.MSG_TEXT_RESULT) {
        DEBUG_CMD("Showing text from scripter.");
        print("\n${message.strContent}\n");
        _scripterPort.send(new Message.Continue().toJson(), _receivePort.toSendPort());
      } else if (message.type == Message.MSG_NO_RESULT) {
        DEBUG_CMD("No visible result. Continuing.");
        _scripterPort.send(new Message.Continue().toJson(), _receivePort.toSendPort());
      } else if (message.type == Message.MSG_SHOW_CHOICES) {
        DEBUG_CMD("We have choices to show!");
        if (message.listContent[0] != "")
          print("\n${message.listContent[0]}\n");
        choices = new List.from(message.listContent);
        for (int i = 1; i < choices.length; i++) {
          print("$i) ${choices[i]['string']}");
        }
        print("");
        // let player choose
        cmdLine.onLine = () {
          print("");
          try {
            int optionNumber = Math.parseInt(cmdLine.readLine());
            if (optionNumber > 0 && optionNumber < choices.length)
              _scripterPort.send(
                  new Message.OptionSelected(choices[optionNumber]['hash']).toJson(),
                  _receivePort.toSendPort()
                  );
          } catch (BadNumberFormatException e) {
            print("Input a number, please!");
          }
        };
      }
    }
  }
}

void main() {
  new CmdlineInterface();
}

/**
  Top-level function which is spawned by the [UserInterface] and which creates
  the [Scripter] instance.
  */
void createScripter() {
  new ScripterImpl();
}