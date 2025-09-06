import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'main.dart';
import 'models/symbol.dart';

class SymbolGridScreen extends StatefulWidget {
  final Category category;
  const SymbolGridScreen({Key? key, required this.category}) : super(key: key);

  @override
  State<SymbolGridScreen> createState() => _SymbolGridScreenState();
}

class _SymbolGridScreenState extends State<SymbolGridScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final ImagePicker picker = ImagePicker();

  Future<String> _showEditDialog(BuildContext context, String title, String initial) async {
    TextEditingController controller = TextEditingController(text: initial);
    String result = '';
    await showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: CupertinoTextField(controller: controller),
          actions: [
            CupertinoDialogAction(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              child: Text('Save'),
              onPressed: () {
                result = controller.text;
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
    return result;
  }

  void _editSymbol(int index) async {
    String newLabel = await _showEditDialog(context, 'Edit Symbol', widget.category.symbols[index].label);
    if (newLabel.isNotEmpty) {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          widget.category.symbols[index] = SymbolItem(
            label: newLabel,
            imagePath: image.path,
          );
        });
      }
    }
  }

  void _addSymbol() async {
    String label = await _showEditDialog(context, 'New Symbol', '');
    if (label.isNotEmpty) {
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          widget.category.symbols.add(
            SymbolItem(
              label: label,
              imagePath: image.path,
            ),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.category.name),
      ),
      child: Stack(
        children: [
          SafeArea(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: widget.category.symbols.length,
              itemBuilder: (context, index) {
                final symbol = widget.category.symbols[index];
                return GestureDetector(
                  onTap: () async {
                    await flutterTts.speak(symbol.label);
                    if (!context.mounted) return;
                    
                    await showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 24,
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  symbol.imagePath.startsWith('assets/')
                                      ? Image.asset(symbol.imagePath, height: 180)
                                      : Image.file(File(symbol.imagePath), height: 180),
                                  const SizedBox(height: 18),
                                  Text(
                                    symbol.label,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ],
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: CupertinoButton(
                                    padding: const EdgeInsets.all(2),
                                    minSize: 32,
                                    child: const Icon(
                                      CupertinoIcons.pencil,
                                      size: 24,
                                      color: Colors.black87
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _editSymbol(index);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        symbol.imagePath.startsWith('assets/')
                            ? Image.asset(symbol.imagePath, height: 70)
                            : Image.file(File(symbol.imagePath), height: 70),
                        const SizedBox(height: 10),
                        Text(
                          symbol.label,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              backgroundColor: CupertinoColors.activeBlue,
              onPressed: _addSymbol,
              child: const Icon(CupertinoIcons.add, color: Colors.white, size: 32),
            ),
          ),
        ],
      ),
    );
  }
}
