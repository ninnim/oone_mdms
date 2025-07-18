import 'package:flutter/material.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/app_lottie_state_widget.dart';

/// Test screen to demonstrate the fixed toast behavior
class ToastTestScreen extends StatefulWidget {
  const ToastTestScreen({super.key});

  @override
  State<ToastTestScreen> createState() => _ToastTestScreenState();
}

class _ToastTestScreenState extends State<ToastTestScreen> {
  int _errorCount = 0;
  int _successCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Toast Test - Fixed Behavior')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Toast Re-display Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            const Text(
              'Test Instructions:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            const Text(
              '1. Click "Show Error Toast" - A toast will appear\n'
              '2. Click the close button (X) on the toast to dismiss it\n'
              '3. Click "Show Error Toast" again - The toast should appear again\n'
              '4. Repeat multiple times to verify it always works',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Error Toast Test
            ElevatedButton.icon(
              onPressed: () {
                _errorCount++;
                AppToast.showError(
                  context,
                  error: 'This is test error #$_errorCount',
                  title: 'Test Error',
                  errorContext: 'test_operation',
                );
              },
              icon: const Icon(Icons.error),
              label: Text('Show Error Toast (#$_errorCount)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[100],
                foregroundColor: Colors.red[800],
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 16),

            // Success Toast Test
            ElevatedButton.icon(
              onPressed: () {
                _successCount++;
                AppToast.showSuccess(
                  context,
                  message: 'This is test success #$_successCount',
                  title: 'Test Success',
                );
              },
              icon: const Icon(Icons.check_circle),
              label: Text('Show Success Toast (#$_successCount)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[100],
                foregroundColor: Colors.green[800],
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 16),

            // Warning Toast Test
            ElevatedButton.icon(
              onPressed: () {
                AppToast.showWarning(
                  context,
                  message:
                      'This is a warning message that you can dismiss and show again',
                  title: 'Test Warning',
                );
              },
              icon: const Icon(Icons.warning),
              label: const Text('Show Warning Toast'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[100],
                foregroundColor: Colors.orange[800],
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 16),

            // Info Toast Test
            ElevatedButton.icon(
              onPressed: () {
                AppToast.showInfo(
                  context,
                  message:
                      'This is an info message that demonstrates the fixed behavior',
                  title: 'Test Info',
                );
              },
              icon: const Icon(Icons.info),
              label: const Text('Show Info Toast'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[100],
                foregroundColor: Colors.blue[800],
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 32),

            // Force Show Test
            ElevatedButton.icon(
              onPressed: () {
                AppToast.forceShow(
                  context,
                  title: 'Force Shown',
                  message:
                      'This toast was force-shown, replacing any existing toast',
                  type: ToastType.info,
                );
              },
              icon: const Icon(Icons.flash_on),
              label: const Text('Force Show Toast (Replaces Current)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[100],
                foregroundColor: Colors.purple[800],
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 16),

            // Dismiss All Test
            OutlinedButton.icon(
              onPressed: () {
                AppToast.dismiss();
              },
              icon: const Icon(Icons.clear),
              label: const Text('Dismiss Current Toast'),
            ),

            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✅ Fixed Issues:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Toast can now be shown again after manual dismissal\n'
                    '• Proper cleanup of overlay entries\n'
                    '• Safe removal prevents crashes\n'
                    '• Multiple toast handling improved\n'
                    '• Animation state properly managed',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Is toast showing: ${AppToast.isShowing ? "Yes" : "No"}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppToast.isShowing ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example of using the fixed toast in real scenarios
class ToastUsageExample {
  /// Example: Device operation with proper error handling
  static Future<void> performDeviceOperation(BuildContext context) async {
    try {
      // Simulate operation
      await Future.delayed(const Duration(seconds: 1));

      // Simulate random failure
      if (DateTime.now().millisecond % 2 == 0) {
        throw Exception('Device not found');
      }

      // Success
      AppToast.showSuccess(
        context,
        message: 'Device operation completed successfully',
        title: 'Success',
      );
    } catch (e) {
      // Error - now works correctly after dismissal
      AppToast.showError(
        context,
        error: e,
        title: 'Operation Failed',
        errorContext: 'device_operation',
      );
    }
  }

  /// Example: Multiple operations that might fail
  static void demonstrateMultipleErrors(BuildContext context) {
    // First error
    Future.delayed(const Duration(milliseconds: 500), () {
      AppToast.showError(
        context,
        error: 'First error occurred',
        errorContext: 'operation_1',
      );
    });

    // Second error (will replace the first)
    Future.delayed(const Duration(milliseconds: 2000), () {
      AppToast.showError(
        context,
        error: 'Second error occurred',
        errorContext: 'operation_2',
      );
    });

    // Third error (user can dismiss and this will still work)
    Future.delayed(const Duration(milliseconds: 4000), () {
      AppToast.showError(
        context,
        error: 'Third error occurred',
        errorContext: 'operation_3',
      );
    });
  }
}
