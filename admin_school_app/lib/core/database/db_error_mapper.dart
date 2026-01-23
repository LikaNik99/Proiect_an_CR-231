/// Maps low-level Postgres/Socket errors to user-friendly messages.
class DbErrorMapper {
  static String toUserMessage(Object e) {
    final msg = e.toString();


    if (msg.contains('no pg_hba.conf entry') || msg.contains('pg_hba.conf')) {
      if (msg.contains('no encryption')) {
        return 'Conexiunea directă la DB a fost refuzată (pg_hba.conf): serverul cere SSL. Activează "Use SSL" în Settings → Bază de date (Direct DB), sau ajustează pg_hba.conf.';
      }
      if (msg.contains('SSL off') || msg.contains('ssl')) {
        return 'Conexiunea directă la DB a fost refuzată (pg_hba.conf/SSL). Verifică setarea "Use SSL" și regulile pg_hba.conf pe serverul Postgres.';
      }
      return 'Conexiunea directă la DB a fost refuzată (pg_hba.conf). Verifică permisiunile/host-ul în Postgres.';
    }

    if (msg.contains('password authentication failed')) {
      return 'Conexiune DB eșuată: username/parola sunt greșite.';
    }

    if (msg.contains('Connection refused') || msg.contains('No route to host') || msg.contains('SocketException')) {
      return 'Conexiune DB eșuată: serverul Postgres nu răspunde (host/port).';
    }

    return 'Conexiune DB eșuată: $msg';
  }
}
