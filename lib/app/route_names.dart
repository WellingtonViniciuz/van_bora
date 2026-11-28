class AppRoutes {
  AppRoutes._();

  static const welcome = '/';
  static const login = '/motorista/login';
  static const queue = '/motorista/fila';
  static const operation = '/motorista/painel';
  static const adminLogin = '/admin/login';
  static const adminDashboard = '/admin/dashboard';

  // Passageiro (sem login).
  static const passengerHome = '/passageiro';
  static const passengerVan = '/passageiro/van'; // argumento: id da van
  static const passengerRoute = '/passageiro/rota'; // argumento: id da rota
  static const passengerTracking = '/passageiro/acompanhar'; // argumento: id da van
}
