import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akira_bites/main.dart';

void main() {
  test('App widget creates successfully', () {
    const app = SamosaTrackerApp();
    expect(app, isA<StatelessWidget>());
  });
}
