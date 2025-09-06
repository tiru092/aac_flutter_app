import 'package:flutter/material.dart';
import 'widgets/goals_section.dart';
import 'utils/aac_logger.dart';

void main() {
  AACLogger.info('Testing GoalsSection import', tag: 'Test');
  const widget = GoalsSection();
  AACLogger.info('GoalsSection imported successfully: ${widget.runtimeType}', tag: 'Test');
}
