/// Source de l'heure courante, injectée pour pouvoir figer le temps en test.
abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
