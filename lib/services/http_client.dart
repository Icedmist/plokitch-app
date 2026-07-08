import 'package:http/http.dart' as http;

import 'http_client_stub.dart'
    if (dart.library.html) 'http_client_web.dart' as http_client_impl;

final http.Client httpClient = http_client_impl.createHttpClient();
