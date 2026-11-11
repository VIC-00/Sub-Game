import 'dart:js_interop';

@JS('deepSeaAudio.playPing')
external void _jsPlayPing(bool isLoud);

@JS('deepSeaAudio.playHeartbeat')
external void _jsPlayHeartbeat();

@JS('deepSeaAudio.playMonsterRoar')
external void _jsPlayMonsterRoar();

@JS('deepSeaAudio.playRelic')
external void _jsPlayRelic();

@JS('deepSeaAudio.playImpact')
external void _jsPlayImpact();

@JS('deepSeaAudio.playDecoy')
external void _jsPlayDecoy();

void platformPlayPing(bool isLoud) {
  try {
    _jsPlayPing(isLoud);
  } catch (_) {}
}

void platformPlayHeartbeat() {
  try {
    _jsPlayHeartbeat();
  } catch (_) {}
}

void platformPlayMonsterRoar() {
  try {
    _jsPlayMonsterRoar();
  } catch (_) {}
}

void platformPlayRelic() {
  try {
    _jsPlayRelic();
  } catch (_) {}
}

void platformPlayImpact() {
  try {
    _jsPlayImpact();
  } catch (_) {}
}

void platformPlayDecoy() {
  try {
    _jsPlayDecoy();
  } catch (_) {}
}

