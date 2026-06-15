import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_health_connect/flutter_health_connect.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keep Walking',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.robotoTextTheme(),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.robotoTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final List<DateTime> _dayDates;
  late final List<int> _daySteps;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeHistory();
    _loadSteps();
  }

  void _initializeHistory() {
    final today = _startOfDay(DateTime.now());
    _dayDates = List.generate(
      7,
      (index) => today.subtract(Duration(days: 6 - index)),
    );
    _daySteps = List.filled(7, 0);
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _loadSteps() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (!await HealthConnectFactory.isApiSupported()) {
        throw Exception('Health Connect API is not supported on this device.');
      }

      final hasPermissions = await HealthConnectFactory.hasPermissions(
        [HealthConnectDataType.Steps],
        readOnly: true,
      );

      if (!hasPermissions) {
        final granted = await HealthConnectFactory.requestPermissions(
          [HealthConnectDataType.Steps],
          readOnly: true,
        );

        if (!granted) {
          throw Exception('Health Connect permission denied.');
        }
      }

      await _refreshSteps();
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshSteps() async {
    final startTime = _dayDates.first;
    final endTime = _dayDates.last.add(const Duration(days: 1));

    final record = await HealthConnectFactory.getRecord(
      type: HealthConnectDataType.Steps,
      startTime: startTime,
      endTime: endTime,
    );

    final recordMap = Map<String, dynamic>.from(record);
    final records = recordMap['records'];

    if (records is List) {
      _initializeHistory();

      for (final item in records) {
        if (item is Map<String, dynamic>) {
          final start = item['startTime'];
          final end = item['endTime'];
          final count = item['count'];

          if (start is String && end is String && count is num) {
            final startDate = DateTime.parse(start).toLocal();
            final dateIndex = _dayDates.indexWhere((date) =>
                date.isAtSameMomentAs(DateTime(startDate.year, startDate.month, startDate.day)));
            if (dateIndex >= 0) {
              _daySteps[dateIndex] = _daySteps[dateIndex] + count.toInt();
            }
          }
        }
      }
    }
  }

  int get _todaySteps => _daySteps.last;

  int get _lastSevenDaysTotal => _daySteps.fold(0, (sum, value) => sum + value);

  Future<void> _onRefreshPressed() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _refreshSteps();
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keep Walking'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Today',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _isLoading ? 'Loading…' : '$_todaySteps steps',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 32),
            Text(
              'Last 7 days',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _isLoading ? 'Loading…' : '$_lastSevenDaysTotal steps',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            Expanded(
              child: ListView.separated(
                itemCount: _dayDates.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final date = _dayDates[index];
                  final steps = _daySteps[index];
                  final label =
                      index == _dayDates.length - 1 ? 'Today' : _weekdayLabel(date.weekday);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(label, style: Theme.of(context).textTheme.bodyLarge),
                        Text(
                          '$steps',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _onRefreshPressed,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Steps'),
            ),
          ],
        ),
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }
}
