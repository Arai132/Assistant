import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:http/http.dart' as http;

class GoogleCalendarService extends ChangeNotifier {
  static const _scopes = [gcal.CalendarApi.calendarReadonlyScope, gcal.CalendarApi.calendarEventsScope];

  final GoogleSignIn _signIn = GoogleSignIn(scopes: _scopes);
  GoogleSignInAccount? _account;
  gcal.CalendarApi? _api;

  bool get isSignedIn => _account != null;

  Future<void> signIn() async {
    _account = await _signIn.signIn();
    if (_account != null) {
      final headers = await _account!.authHeaders;
      _api = gcal.CalendarApi(_AuthClient(headers));
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    await _signIn.signOut();
    _account = null;
    _api = null;
    notifyListeners();
  }

  Future<List<gcal.Event>> getEventsForDay(DateTime date) async {
    if (_api == null) return [];
    final start = DateTime(date.year, date.month, date.day).toUtc();
    final end = start.add(const Duration(days: 1));
    try {
      final result = await _api!.events.list(
        'primary',
        timeMin: start,
        timeMax: end,
        singleEvents: true,
        orderBy: 'startTime',
      );
      return result.items ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<String?> createEvent({
    required String title,
    required DateTime start,
    required DateTime end,
  }) async {
    if (_api == null) return null;
    final event = gcal.Event()
      ..summary = title
      ..start = (gcal.EventDateTime()..dateTime = start.toUtc()..timeZone = 'UTC')
      ..end = (gcal.EventDateTime()..dateTime = end.toUtc()..timeZone = 'UTC');
    final created = await _api!.events.insert(event, 'primary');
    return created.id;
  }
}

class _AuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();
  _AuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}
