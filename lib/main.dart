import 'package:flutter/material.dart'; // 1. Import the UI library

void main() {
  // 2. The entry point. runApp needs a Widget to display.
  runApp(
    const MaterialApp(      // 3. The "Wrapper" widget for the whole app
      home: Center(         // 4. A widget to center things
        child: Text(        // 5. A widget to show text
            'Hello World',
            textDirection: TextDirection.ltr // Left-to-right
        ),
      ),
    ),
  );
}