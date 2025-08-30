import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/symbol.dart';
import '../utils/sample_data.dart';

/// Test utility for overflow scenarios
class OverflowTest {
  
  /// Generate many test symbols to test overflow scenarios
  static List<Symbol> generateManyTestSymbols() {
    final testSymbols = <Symbol>[];
    final sampleSymbols = SampleData.getSampleSymbols();
    
    // Add many symbols to test overflow
    for (int i = 0; i < 20; i++) {
      for (final symbol in sampleSymbols.take(5)) {
        testSymbols.add(Symbol(
          id: 'test_${symbol.id}_$i',
          label: '${symbol.label}$i',
          category: symbol.category,
          imagePath: symbol.imagePath,
        ));
      }
    }
    
    return testSymbols;
  }
  
  /// Create a test button widget for adding many symbols quickly
  static Widget createTestButton(BuildContext context, Function(Symbol) onSymbolTap) {
    return Positioned(
      top: 100,
      right: 10,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CupertinoButton(
          padding: const EdgeInsets.all(8),
          onPressed: () {
            final testSymbols = generateManyTestSymbols();
            for (final symbol in testSymbols.take(15)) {
              onSymbolTap(symbol);
            }
          },
          child: const Text(
            'TEST\nOVERFLOW',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
