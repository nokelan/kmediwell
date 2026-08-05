import 'dart:js_interop';

@JS('window.prompt')
external JSString? _jsPrompt(JSString message, JSString defaultValue);

@JS('eval')
external void _jsEval(JSString code);

String? jsPrompt(String message, [String defaultValue = '']) =>
    _jsPrompt(message.toJS, defaultValue.toJS)?.toDart;

void jsEval(String code) => _jsEval(code.toJS);
