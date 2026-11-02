enum Occupancy {
  vazia('Vazia', 'vazia'),
  metade('Metade', 'metade'),
  cheia('Cheia', 'cheia');

  const Occupancy(this.label, this.codigo);

  final String label;
  final String codigo;
}
