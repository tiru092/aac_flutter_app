import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SubscriptionScreenTest extends StatefulWidget {
  const SubscriptionScreenTest({super.key});

  @override
  State<SubscriptionScreenTest> createState() => _SubscriptionScreenTestState();
}

class _SubscriptionScreenTestState extends State<SubscriptionScreenTest> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Test Subscription'),
      ),
      child: const Center(
        child: Text('Test subscription screen'),
      ),
    );
  }
}
