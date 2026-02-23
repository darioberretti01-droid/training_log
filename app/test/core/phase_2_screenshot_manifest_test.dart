import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/screenshots_manifest.dart';

void main() {
  test('screenshot manifest uses unique ids/orders and expected size', () {
    expect(screenshotManifest, hasLength(27));

    final ids = screenshotManifest.map((entry) => entry.id).toList();
    final orders = screenshotManifest.map((entry) => entry.order).toList();

    expect(ids.toSet(), hasLength(ids.length));
    expect(orders.toSet(), hasLength(orders.length));
    expect(orders.toList()..sort(), List.generate(27, (index) => index + 1));
  });
}
