import 'package:ghost_logger/ghost_logger.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GhostLogger.configure(
    loggerType: LoggerType.console,
    storeErrors: true,
    storeWarnings: true,
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
  // Simulate a rapid burst of logs to demonstrate the write queue
  void _logBurst() {
    for (var i = 1; i <= 10; i++) {
      GhostLogger.logDebug('Burst log #$i', tag: 'Example');
    }
  }

  @override
  void dispose() {
    // Drain the write queue before the widget tree tears down so no
    // buffered file entries are lost on app exit
    GhostLogger.flush();
    super.dispose();
  }

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
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '✨ Now with a serial write queue — zero dropped logs ✨',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 32),
              _LogButton(
                label: '⚒️ Log Debug',
                color: Colors.grey,
                onPressed: () {
                  GhostLogger.logDebug(
                    'This is a debug message using convenience method',
                    tag: 'Example',
                  );
                },
              ),
              _LogButton(
                label: '👉 Log Info',
                color: Colors.cyan,
                onPressed: () {
                  GhostLogger.logInfo(
                    'User performed an action',
                    tag: 'Example',
                  );
                },
              ),
              _LogButton(
                label: '⚠️ Log Warning',
                color: Colors.orange,
                onPressed: () {
                  GhostLogger.logWarning(
                    'This might need attention',
                    tag: 'Example',
                  );
                },
              ),
              _LogButton(
                label: '❌ Log Error',
                color: Colors.red,
                onPressed: () {
                  GhostLogger.logError(
                    'An error occurred silently',
                    tag: 'Example',
                    stackTrace: StackTrace.current,
                  );
                },
              ),
              const Divider(height: 48),
              _LogButton(
                label: '🚀 Burst 10 Logs (tests write queue)',
                color: Colors.deepPurple,
                onPressed: _logBurst,
              ),
              _LogButton(
                label: '💾 Flush pending writes',
                color: Colors.teal,
                onPressed: () async {
                  await GhostLogger.flush();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All pending writes flushed')),
                    );
                  }
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
  final Color color;
  final VoidCallback onPressed;

  const _LogButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
