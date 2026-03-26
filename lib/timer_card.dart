import 'package:flutter/material.dart';

class TimerCard extends StatelessWidget {
  const TimerCard({super.key});

  @override
  Widget build(BuildContext context) {
    // A 'Card' gives us a nice white box with a slight shadow
    return const Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(Icons.timer_outlined), // Icon on the left
        title: Text('Egg Timer'),           // Placeholder Title
        trailing: Text(
          '05:00',                           // Placeholder Time
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
