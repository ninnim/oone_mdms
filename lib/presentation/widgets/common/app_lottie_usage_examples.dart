import 'package:flutter/material.dart';
import '../common/app_lottie_state_widget.dart';
import '../../../core/constants/app_sizes.dart';

/// Example usage of AppLottieStateWidget in different scenarios
class AppLottieUsageExamples extends StatelessWidget {
  const AppLottieUsageExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lottie State Widget Examples')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          children: [
            _buildExampleSection(
              'Loading State',
              const AppLottieStateWidget.loading(),
            ),
            const SizedBox(height: AppSizes.spacing32),
            _buildExampleSection(
              'Error State',
              AppLottieStateWidget.error(
                onButtonPressed: () => _showMessage(context, 'Retry clicked!'),
              ),
            ),
            const SizedBox(height: AppSizes.spacing32),
            _buildExampleSection(
              'Coming Soon State',
              const AppLottieStateWidget.comingSoon(),
            ),
            const SizedBox(height: AppSizes.spacing32),
            _buildExampleSection(
              'No Data State',
              AppLottieStateWidget.noData(
                onButtonPressed: () =>
                    _showMessage(context, 'Refresh clicked!'),
              ),
            ),
            const SizedBox(height: AppSizes.spacing32),
            _buildExampleSection(
              'Custom Loading State',
              const AppLottieStateWidget.loading(
                title: 'Processing Your Request',
                message: 'Please wait while we process your data...',
                lottieSize: 150,
              ),
            ),
            const SizedBox(height: AppSizes.spacing32),
            _buildExampleSection(
              'Custom Error State',
              AppLottieStateWidget.error(
                title: 'Network Error',
                message:
                    'Unable to connect to the server. Please check your internet connection.',
                buttonText: 'Retry Connection',
                onButtonPressed: () =>
                    _showMessage(context, 'Retry connection clicked!'),
                lottieSize: 120,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleSection(String title, Widget widget) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSizes.spacing8),
        Container(
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          ),
          child: widget,
        ),
      ],
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Extension methods for common usage patterns
extension AppLottieStateWidgetExtensions on Widget {
  /// Wrap any widget with a loading overlay
  Widget withLoadingOverlay(bool isLoading) {
    return Stack(
      children: [
        this,
        if (isLoading) AppLottieStateWidgetExtension.loadingOverlay(),
      ],
    );
  }
}

/// Example of how to use in data loading scenarios
class DataLoadingExample extends StatefulWidget {
  const DataLoadingExample({super.key});

  @override
  State<DataLoadingExample> createState() => _DataLoadingExampleState();
}

class _DataLoadingExampleState extends State<DataLoadingExample> {
  bool _isLoading = false;
  List<String> _data = [];
  String? _error;

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (_isLoading && _data.isEmpty) {
      return const AppLottieStateWidget.loading(
        title: 'Loading Data',
        message: 'Fetching your information...',
      );
    }

    // Show error state
    if (_error != null && _data.isEmpty) {
      return AppLottieStateWidget.error(
        title: 'Failed to Load Data',
        message: _error!,
        onButtonPressed: _loadData,
      );
    }

    // Show no data state
    if (!_isLoading && _data.isEmpty) {
      return AppLottieStateWidget.noData(
        title: 'No Data Available',
        message: 'There is no data to display.',
        buttonText: 'Load Data',
        onButtonPressed: _loadData,
      );
    }

    // Show data
    return Column(
      children: [
        ElevatedButton(onPressed: _loadData, child: const Text('Reload Data')),
        Expanded(
          child: ListView.builder(
            itemCount: _data.length,
            itemBuilder: (context, index) =>
                ListTile(title: Text(_data[index])),
          ),
        ),
      ],
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Simulate different outcomes
      final random = DateTime.now().millisecond % 3;
      if (random == 0) {
        throw Exception('Network error occurred');
      } else if (random == 1) {
        setState(() {
          _data = [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _data = List.generate(10, (index) => 'Item ${index + 1}');
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
}
