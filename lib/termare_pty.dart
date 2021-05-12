library termare_pty;

import 'dart:async';
import 'dart:convert';

import 'package:dart_pty/dart_pty.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:termare_view/termare_view.dart';

export 'package:dart_pty/dart_pty.dart';

class TermarePty extends StatefulWidget {
  const TermarePty({
    Key key,
    this.controller,
    this.pseudoTerminal,
    this.enableInput = true,
  }) : super(key: key);
  final TermareController controller;
  final PseudoTerminal pseudoTerminal;
  final bool enableInput;
  @override
  _TermarePtyState createState() => _TermarePtyState();
}

class _TermarePtyState extends State<TermarePty> with TickerProviderStateMixin {
  TermareController _controller;
  PseudoTerminal pseudoTerminal;
  StreamSubscription streamSubscription;
  @override
  void initState() {
    super.initState();

    _controller = widget.controller ?? TermareController();

    pseudoTerminal = widget.pseudoTerminal;
    _controller.input = (String data) {
      pseudoTerminal.write(data);
    };
    _controller.sizeChanged = (TermSize size) {
      pseudoTerminal.resize(size.row, size.column);
    };
    pseudoTerminal.startPolling();
    print('$this init');
    print('\x1b[31m监听的id 为${pseudoTerminal.pseudoTerminalId}');
    // 延时有用，是termare_app引起的。
    // PageView.builder会在短时间init与dispose这个widget
    Future<void>.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) {
        return;
      }
      streamSubscription = pseudoTerminal.out.transform(utf8.decoder).listen(
        (String data) {
          _controller.writeCodeUnits(utf8.encode(data));
          _controller.enableAutoScroll();
          _controller.notifyListeners();
        },
      );
    });
    // init();
  }

  @override
  void dispose() {
    streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: TermareView(
        keyboardInput: widget.enableInput
            ? (String data) {
                pseudoTerminal.write(data);
              }
            : null,
        controller: _controller,
      ),
    );
  }
}
