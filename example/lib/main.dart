import 'package:ghost_logger/ghost_logger.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GhostLogger.configure(
    isDebugMode: true,
    loggerType: LoggerType.console,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ghost Logger Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Ghost Logger Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Stealing errors before they steal your users\' experience',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 32),
              _LogButton(
                label: '⚒️ Log Debug',
                onPressed: () {
                  GhostLogger.log(
                    message: 'This is a debug message',
                    level: LogLevel.debug,
                    tag: 'Example',
                  );
                },
              ),
              _LogButton(
                label: '👉 Log Info',
                onPressed: () {
                  GhostLogger.log(
                    message: 'User performed an action',
                    level: LogLevel.info,
                    tag: 'Example',
                  );
                },
              ),
              _LogButton(
                label: '⚠️ Log Warning',
                onPressed: () {
                  GhostLogger.log(
                    message: 'This might need attention',
                    level: LogLevel.warning,
                    tag: 'Example',
                  );
                },
              ),
              _LogButton(
                label: '❌ Log Error',
                onPressed: () {
                  GhostLogger.log(
                    message: 'An error occurred silently',
                    level: LogLevel.error,
                    tag: 'Example',
                    stackTrace: StackTrace.current,
                  );
                },
              ),
              const SizedBox(height: 32),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Check your console output to see the logged messages',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _LogButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ElevatedButton(onPressed: onPressed, child: Text(label)),
    );
  }
}
