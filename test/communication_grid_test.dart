import 'package:flutter/cupertino.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:aac_flutter_app/widgets/communication_grid.dart';
import 'package:aac_flutter_app/models/symbol.dart';
import 'package:aac_flutter_app/utils/aac_helper.dart';

void main() {
  group('CommunicationGrid Widget Tests', () {
    late List<Symbol> testSymbols;
    late List<Category> testCategories;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Mock TTS and sound channels
      const MethodChannel('flutter_tts').setMockMethodCallHandler((methodCall) async {
        return true;
      });
      
      const MethodChannel('flutter/platform').setMockMethodCallHandler((methodCall) async {
        return null;
      });
      
      // Mock audioplayers
      const MethodChannel('xyz.luan/audioplayers').setMockMethodCallHandler((methodCall) async {
        return true;
      });
    });

    setUp(() {
      // Create test data
      testCategories = [
        Category(
          name: 'Food',
          iconPath: 'assets/food.png',
          colorCode: 0xFF00FF00,
        ),
        Category(
          name: 'Emotions',
          iconPath: 'assets/emotions.png',
          colorCode: 0xFFFF0000,
        ),
      ];

      testSymbols = [
        Symbol(
          label: 'Apple',
          imagePath: 'assets/apple.png',
          category: 'Food',
          description: 'A red fruit',
        ),
        Symbol(
          label: 'Happy',
          imagePath: 'assets/happy.png',
          category: 'Emotions',
          description: 'Feeling joy',
        ),
        Symbol(
          label: 'Water',
          imagePath: 'assets/water.png',
          category: 'Food',
          description: 'A glass of water',
        ),
      ];
    });

    group('Category Grid Tests', () {
      testWidgets('should display categories correctly', (WidgetTester tester) async {
        bool categoryTapped = false;
        Category? tappedCategory;

        await tester.pumpWidget(
          CupertinoApp(
            home: CommunicationGrid(
              symbols: testSymbols,
              categories: testCategories,
              viewType: ViewType.categories,
              onSymbolTap: (symbol) {},
              onCategoryTap: (category) {
                categoryTapped = true;
                tappedCategory = category;
              },
            ),
          ),
        );

        // Wait for animations
        await tester.pumpAndSettle();

        // Check if categories are displayed
        expect(find.text('Food'), findsOneWidget);
        expect(find.text('Emotions'), findsOneWidget);

        // Check if symbol counts are displayed
        expect(find.text('2 symbols'), findsOneWidget); // Food has 2 symbols
        expect(find.text('1 symbols'), findsOneWidget); // Emotions has 1 symbol

        // Test category tap
        await tester.tap(find.text('Food'));
        await tester.pumpAndSettle();

        expect(categoryTapped, isTrue);
        expect(tappedCategory?.name, equals('Food'));
      });

      testWidgets('should display category emojis correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          CupertinoApp(
            home: CommunicationGrid(
              symbols: testSymbols,
              categories: testCategories,
              viewType: ViewType.categories,
              onSymbolTap: (symbol) {},
              onCategoryTap: (category) {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check for emoji presence (they should be in the UI)
        expect(find.text('🍎'), findsOneWidget); // Food emoji
        expect(find.text('😊'), findsOneWidget); // Emotions emoji
      });

      testWidgets('should handle empty categories gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          CupertinoApp(
            home: CommunicationGrid(
              symbols: [],
              categories: [],
              viewType: ViewType.categories,
              onSymbolTap: (symbol) {},
              onCategoryTap: (category) {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show empty state
        expect(find.text('No symbols yet!'), findsOneWidget);
        expect(find.text('Tap the + button to add your first symbol'), findsOneWidget);
      });
    });

    group('Symbol Grid Tests', () {
      testWidgets('should display symbols correctly', (WidgetTester tester) async {
        bool symbolTapped = false;
        Symbol? tappedSymbol;

        await tester.pumpWidget(
          CupertinoApp(
            home: CommunicationGrid(
              symbols: testSymbols,
              categories: testCategories,
              viewType: ViewType.symbols,
              onSymbolTap: (symbol) {
                symbolTapped = true;
                tappedSymbol = symbol;
              },
              onCategoryTap: (category) {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check if symbols are displayed
        expect(find.text('Apple'), findsOneWidget);
        expect(find.text('Happy'), findsOneWidget);
        expect(find.text('Water'), findsOneWidget);

        // Test symbol tap
        await tester.tap(find.text('Apple'));
        await tester.pumpAndSettle();

        expect(symbolTapped, isTrue);
        expect(tappedSymbol?.label, equals('Apple'));
      });

      testWidgets('should handle empty symbols gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          CupertinoApp(
            home: CommunicationGrid(
              symbols: [],
              categories: testCategories,
              viewType: ViewType.symbols,
              onSymbolTap: (symbol) {},
              onCategoryTap: (category) {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show empty state
        expect(find.text('No symbols yet!'), findsOneWidget);
      });
    });

    group('Symbol Popup Tests', () {
      testWidgets('should show symbol popup when symbol is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(
          CupertinoApp(
            home: CommunicationGrid(
              symbols: testSymbols,
              categories: testCategories,
              viewType: ViewType.symbols,
              onSymbolTap: (symbol) {},
              onCategoryTap: (category) {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap on a symbol
        await tester.tap(find.text('Apple'));
        await tester.pumpAndSettle();

        // Check if popup is displayed
        expect(find.text('Speak Again'), findsOneWidget);
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Close'), findsOneWidget);
      });

      testWidgets('should close popup when close button is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(
          CupertinoApp(
            home: CommunicationGrid(
              symbols: testSymbols,
              categories: testCategories,
              viewType: ViewType.symbols,
              onSymbolTap: (symbol) {},
              onCategoryTap: (category) {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap on a symbol to open popup
        await tester.tap(find.text('Apple'));
        await tester.pumpAndSettle();

        // Tap close button
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        // Popup should be closed
        expect(find.text('Speak Again'), findsNothing);
        expect(find.text('Edit'), findsNothing);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should have proper semantic labels for categories', (WidgetTester tester) async {
        await tester.pumpWidget(
          CupertinoApp(
            home: CommunicationGrid(
              symbols: testSymbols,
              categories: testCategories,
              viewType: ViewType.categories,
              onSymbolTap: (symbol) {},
              onCategoryTap: (category) {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check for semantic labels
        final semantics = tester.getSemantics(find.text('Food').first);
        expect(semantics.label, contains('Category: Food'));
        expect(semantics.label, contains('symbols available'));
        expect(semantics.label, contains('Double tap to open'));
      });

      testWidgets('should have proper semantic labels for symbols', (WidgetTester tester) async {
        await tester.pumpWidget(
          CupertinoApp(
            home: CommunicationGrid(
              symbols: testSymbols,
              categories: testCategories,
              viewType: ViewType.symbols,
              onSymbolTap: (symbol) {},
              onCategoryTap: (category) {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check for semantic labels
        final semantics = tester.getSemantics(find.text('Apple').first);
        expect(semantics.label, contains('Symbol: Apple'));
        expect(semantics.label, contains('A red fruit'));
        expect(semantics.label, contains('Category: Food'));
        expect(semantics.label, contains('Double tap to speak'));
      });

      testWidgets('should be accessible with screen readers', (WidgetTester tester) async {
        await tester.pumpWidget(
          CupertinoApp(
            home: CommunicationGrid(
              symbols: testSymbols,
              categories: testCategories,
              viewType: ViewType.categories,
              onSymbolTap: (symbol) {},
              onCategoryTap: (category) {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify accessibility tree structure
        expect(tester.semantics, hasAGoodToStringDeep);
        
        // Check that interactive elements are marked as buttons
        final categorySemantics = tester.getSemantics(find.text('Food').first);
        expect(categorySemantics.hasFlag(SemanticsFlag.isButton), isTrue);
        expect(categorySemantics.hasFlag(SemanticsFlag.isEnabled), isTrue);
      });
    });

    group('Animation Tests', () {
      testWidgets('should animate grid items on load', (WidgetTester tester) async {
        await tester.pumpWidget(
          CupertinoApp(
            home: CommunicationGrid(
              symbols: testSymbols,
              categories: testCategories,
              viewType: ViewType.categories,
              onSymbolTap: (symbol) {},
              onCategoryTap: (category) {},
            ),
          ),
        );

        // Pump a few frames to test animation
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        // Should not throw during animation
        expect(find.text('Food'), findsOneWidget);
        expect(find.text('Emotions'), findsOneWidget);
      });
    });

    group('High Contrast Mode Tests', () {
      testWidgets('should adapt to high contrast mode', (WidgetTester tester) async {
        // Enable high contrast mode
        await AACHelper.setHighContrast(true);

        await tester.pumpWidget(
          CupertinoApp(
            home: CommunicationGrid(
              symbols: testSymbols,
              categories: testCategories,
              viewType: ViewType.symbols,
              onSymbolTap: (symbol) {},
              onCategoryTap: (category) {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify that elements are still displayed properly
        expect(find.text('Apple'), findsOneWidget);
        expect(find.text('Happy'), findsOneWidget);

        // Reset to normal mode
        await AACHelper.setHighContrast(false);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('should handle image loading errors gracefully', (WidgetTester tester) async {
        final symbolsWithBadImages = [
          Symbol(
            label: 'Bad Image',
            imagePath: 'nonexistent/path.png',
            category: 'Test',
          ),
        ];

        await tester.pumpWidget(
          CupertinoApp(
            home: CommunicationGrid(
              symbols: symbolsWithBadImages,
              categories: testCategories,
              viewType: ViewType.symbols,
              onSymbolTap: (symbol) {},
              onCategoryTap: (category) {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should still show the symbol label even if image fails
        expect(find.text('Bad Image'), findsOneWidget);
      });
    });
  });
}