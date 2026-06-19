import 'package:flutter/material.dart';
import 'package:health/health.dart';

final health = Health();

void main() => runApp(const HealthApp());

class HealthApp extends StatefulWidget {
  const HealthApp({super.key});

  @override
  State<HealthApp> createState() => _HealthAppState();
}

enum AppState {
  dataNotFetched,
  fetchingData,
  dataReady,
  noData,
  authorized,
  authNotGranted,
  stepsReady,
}

class _HealthAppState extends State<HealthApp> {
  final List<HealthDataPoint> _healthDataList = [];
  final List<HealthDataPoint> _dailyStepData = [];
  AppState _state = AppState.dataNotFetched;
  int _nofSteps = 0;

  @override
  void initState() {
    super.initState();
    health.configure();
  }

  List<HealthDataType> get types => const [HealthDataType.STEPS];
  List<HealthDataAccess> get permissions => const [HealthDataAccess.READ];

  Future<void> authorize() async {
    await health.configure();

    bool? hasPermissions = await health.hasPermissions(
      types,
      permissions: permissions,
    );

    if (hasPermissions != true) {
      try {
        hasPermissions = await health.requestAuthorization(
          types,
          permissions: permissions,
        );
      } catch (error) {
        debugPrint('Exception in authorize: $error');
      }
    }

    setState(
      () => _state = (hasPermissions == true) ? AppState.authorized : AppState.authNotGranted,
    );
  }

  Future<void> fetchData() async {
    setState(() => _state = AppState.fetchingData);

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));

    _healthDataList.clear();

    try {
      final healthData = await health.getHealthDataFromTypes(
        types: types,
        startTime: yesterday,
        endTime: now,
      );

      healthData.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      _healthDataList.addAll(healthData);
    } catch (error) {
      debugPrint('Exception in fetchData: $error');
    }

    setState(
      () => _state = _healthDataList.isEmpty ? AppState.noData : AppState.dataReady,
    );
  }

  Future<void> fetchStepData() async {
    await health.configure();

    bool? hasPermissions = await health.hasPermissions(
      types,
      permissions: permissions,
    );

    if (hasPermissions != true) {
      try {
        hasPermissions = await health.requestAuthorization(
          types,
          permissions: permissions,
        );
      } catch (error) {
        debugPrint('Exception in fetchStepData authorization: $error');
      }
    }

    if (hasPermissions != true) {
      setState(() => _state = AppState.authNotGranted);
      return;
    }

    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 7));

    _dailyStepData.clear();
    int totalSteps = 0;

    try {
      final intervalData = await health.getHealthIntervalDataFromTypes(
        startDate: startDate,
        endDate: now,
        types: types,
        interval: 86400,
      );

      intervalData.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      _dailyStepData.addAll(intervalData);
      totalSteps = intervalData.fold<int>(0, (sum, point) {
        final value = point.value;
        if (value is NumericHealthValue) {
          return sum + value.numericValue.toInt();
        }
        return sum;
      });
    } catch (error) {
      debugPrint('Exception in fetchStepData: $error');
    }

    setState(() {
      _nofSteps = totalSteps;
      _state = _dailyStepData.isEmpty ? AppState.noData : AppState.stepsReady;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Health Example')),
        body: Column(
          children: [
            Wrap(
              spacing: 10,
              children: [
                TextButton(
                  onPressed: authorize,
                  style: const ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.blue),
                  ),
                  child: const Text(
                    'Authenticate',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: fetchData,
                  style: const ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.blue),
                  ),
                  child: const Text(
                    'Fetch Data',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: fetchStepData,
                  style: const ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.blue),
                  ),
                  child: const Text(
                    'Fetch Step Data',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const Divider(thickness: 3),
            Expanded(child: Center(child: _content)),
          ],
        ),
      ),
    );
  }

  Widget get _content {
    switch (_state) {
      case AppState.dataReady:
        return _contentDataReady;
      case AppState.fetchingData:
        return _contentFetchingData;
      case AppState.noData:
        return _contentNoData;
      case AppState.authorized:
        return _authorized;
      case AppState.authNotGranted:
        return _authorizationNotGranted;
      case AppState.stepsReady:
        return _stepsFetched;
      case AppState.dataNotFetched:
        return _contentNotFetched;
    }
  }

  Widget get _contentDataReady => ListView.builder(
        itemCount: _healthDataList.length,
        itemBuilder: (context, index) {
          final data = _healthDataList[index];
          return ListTile(
            title: Text('${data.typeString}: ${data.value}'),
            subtitle: Text('${data.dateFrom} - ${data.dateTo}'),
            trailing: Text(data.unitString),
          );
        },
      );

  Widget get _contentFetchingData => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(strokeWidth: 10),
          ),
          Text('Fetching data...'),
        ],
      );

  Widget get _contentNoData => const Text('No Data to show');

  Widget get _contentNotFetched => const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Press 'Authenticate' to grant step count permission."),
          Text("Then use 'Fetch Data' or 'Fetch Step Data' to view daily steps."),
        ],
      );

  Widget get _authorized => const Text('Authorization granted!');

  Widget get _authorizationNotGranted => const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Authorization not granted.'),
          Text('Step count permission is required.'),
        ],
      );

  Widget get _stepsFetched {
    if (_dailyStepData.isEmpty) {
      return const Text('No step data available.');
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('Daily step totals (last 7 days): $_nofSteps steps'),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _dailyStepData.length,
            itemBuilder: (context, index) {
              final data = _dailyStepData[index];
              final start = data.dateFrom;
              final dayLabel =
                  '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
              return ListTile(
                title: Text(dayLabel),
                subtitle: Text('${data.dateFrom} - ${data.dateTo}'),
                trailing: Text('${data.value} ${data.unitString}'),
              );
            },
          ),
        ),
      ],
    );
  }
}
