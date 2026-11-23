import 'failure.dart';

/// Résultat d'une opération qui peut échouer de façon attendue.
///
/// Les échecs prévisibles sont des valeurs et non des exceptions : comme la
/// classe est scellée, un `switch` doit traiter les deux cas, sinon le code ne
/// compile pas.
sealed class Result<T> {
  const Result();
}

/// Succès. Les noms `Ok` / `Err` évitent le conflit avec la classe [Failure].
final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

/// Échec attendu, décrit par une [Failure].
final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}
