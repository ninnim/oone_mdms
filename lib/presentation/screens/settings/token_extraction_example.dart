// import 'package:flutter/material.dart';
// import '../../../core/services/service_locator.dart';

// /// Example showing how to use the dynamic token management system
// class TokenExtractionExample {
//   /// Initialize the service locator and test token extraction
//   static Future<void> demonstrateTokenExtraction() async {
//     try {
//       print('🚀 Initializing ServiceLocator...');
      
//       // Initialize all services
//       final serviceLocator = ServiceLocator();
//       await serviceLocator.initialize();
      
//       print('✅ Services initialized successfully');
      
//       // Get token management service
//       final tokenService = serviceLocator.tokenManagementService;
      
//       // Display extracted token information
//       print('\n📊 Token Information:');
//       print('Tenant: ${tokenService.currentTenant}');
//       print('Allowed Roles: ${tokenService.allowedRoles}');
//       print('Selected Role: ${tokenService.currentRole}');
//       print('Token Valid: ${tokenService.isTokenValid}');
//       print('Token Expires: ${tokenService.tokenExpiry}');
      
//       // Get dynamic headers
//       final headers = tokenService.getApiHeaders();
//       print('\n🔑 Dynamic API Headers:');
//       headers.forEach((key, value) {
//         if (key == 'Authorization') {
//           print('$key: Bearer ${value.substring(7, 30)}...');
//         } else {
//           print('$key: $value');
//         }
//       });
      
//       // Test API call with dynamic headers
//       print('\n🌐 Testing API call...');
//       final apiService = serviceLocator.apiService;
      
//       try {
//         final response = await apiService.get('/api/rest/Device');
//         print('✅ API call successful - Status: ${response.statusCode}');
//       } catch (e) {
//         print('❌ API call failed: $e');
//       }
      
//       print('\n🎉 Token extraction demonstration complete!');
      
//     } catch (e) {
//       print('❌ Error during demonstration: $e');
//     }
//   }
  
//   /// Validate that the token extraction matches expected values
//   static Future<bool> validateTokenExtraction() async {
//     try {
//       final serviceLocator = ServiceLocator();
//       await serviceLocator.initialize();
      
//       final tokenService = serviceLocator.tokenManagementService;
      
//       // Expected values from your token
//       const expectedTenant = '025aa4a1-8617-4e24-b890-2e69a09180ee';
//       const expectedRoles = ['auditor', 'user', 'operator', 'tenant-admin', 'super-admin'];
//       const expectedSelectedRole = 'super-admin'; // Last role
      
//       // Validate extraction
//       final actualTenant = tokenService.currentTenant;
//       final actualRoles = tokenService.allowedRoles;
//       final actualSelectedRole = tokenService.currentRole;
      
//       print('🔍 Validation Results:');
//       print('Tenant - Expected: $expectedTenant, Actual: $actualTenant, Valid: ${actualTenant == expectedTenant}');
//       print('Selected Role - Expected: $expectedSelectedRole, Actual: $actualSelectedRole, Valid: ${actualSelectedRole == expectedSelectedRole}');
//       print('Roles Count - Expected: ${expectedRoles.length}, Actual: ${actualRoles.length}, Valid: ${actualRoles.length == expectedRoles.length}');
      
//       // Check headers
//       final headers = tokenService.getApiHeaders();
//       final hasRequiredHeaders = headers.containsKey('x-hasura-tenant') &&
//                                  headers.containsKey('x-hasura-allowed-roles') &&
//                                  headers.containsKey('x-hasura-role') &&
//                                  headers.containsKey('Authorization');
      
//       print('Required Headers Present: $hasRequiredHeaders');
      
//       return actualTenant == expectedTenant &&
//              actualSelectedRole == expectedSelectedRole &&
//              actualRoles.length == expectedRoles.length &&
//              hasRequiredHeaders;
             
//     } catch (e) {
//       print('❌ Validation failed: $e');
//       return false;
//     }
//   }
// }

// /// Widget to test token extraction in a Flutter app
// class TokenExtractionTestWidget extends StatefulWidget {
//   const TokenExtractionTestWidget({super.key});

//   @override
//   State<TokenExtractionTestWidget> createState() => _TokenExtractionTestWidgetState();
// }

// class _TokenExtractionTestWidgetState extends State<TokenExtractionTestWidget> {
//   bool _isLoading = false;
//   String _results = '';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Token Extraction Test'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             ElevatedButton(
//               onPressed: _isLoading ? null : _runTest,
//               child: _isLoading 
//                   ? const CircularProgressIndicator()
//                   : const Text('Run Token Extraction Test'),
//             ),
//             const SizedBox(height: 16),
//             if (_results.isNotEmpty)
//               Expanded(
//                 child: SingleChildScrollView(
//                   child: Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[100],
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Text(
//                       _results,
//                       style: const TextStyle(
//                         fontFamily: 'monospace',
//                         fontSize: 12,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _runTest() async {
//     setState(() {
//       _isLoading = true;
//       _results = '';
//     });

//     try {
//       // Capture output using debugPrint instead of print manipulation
//       _results = 'Running token extraction test...\n';
      
//       // Run the test
//       await TokenExtractionExample.demonstrateTokenExtraction();
      
//       setState(() {
//         _results += '\nTest completed successfully!';
//       });
      
//     } catch (e) {
//       setState(() {
//         _results = 'Error: $e';
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
// }
