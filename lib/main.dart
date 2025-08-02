import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(AACApp());
}

class AACApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'AAC Flutter App',
      theme: CupertinoThemeData(
        brightness: Brightness.light,
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('AAC Communication'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: 9, // Placeholder for buttons
                itemBuilder: (context, index) {
                  return CupertinoButton(
                    color: CupertinoColors.activeBlue,
                    child: Text('Button ${index + 1}'),
                    onPressed: () {
                      // TODO: Add button functionality
                    },
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              child: CupertinoButton.filled(
                child: Text('Speak'),
                onPressed: () {
                  // TODO: Add text-to-speech functionality
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
