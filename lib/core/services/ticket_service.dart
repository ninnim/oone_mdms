import 'package:dio/dio.dart';
import '../models/ticket.dart';

class TicketService {
  final Dio _dio;

  TicketService({Dio? dio}) : _dio = dio ?? Dio();

  // Get all tickets with filtering and pagination
  Future<List<Ticket>> getTickets({
    int? page,
    int? limit,
    TicketStatus? status,
    TicketPriority? priority,
    TicketCategory? category,
    String? assignedTo,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (status != null) queryParams['status'] = status.displayName;
      if (priority != null) queryParams['priority'] = priority.displayName;
      if (category != null) queryParams['category'] = category.displayName;
      if (assignedTo != null) queryParams['assignedTo'] = assignedTo;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      // For demo purposes, return mock data
      return _getMockTickets();
    } catch (e) {
      print('Error fetching tickets: $e');
      return _getMockTickets();
    }
  }

  // Get ticket by ID
  Future<Ticket?> getTicketById(String id) async {
    try {
      final tickets = await getTickets();
      return tickets.firstWhere((ticket) => ticket.id == id);
    } catch (e) {
      print('Error fetching ticket by ID: $e');
      return null;
    }
  }

  // Create new ticket
  Future<Ticket?> createTicket(Ticket ticket) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 500));

      // For demo purposes, return the ticket with an ID
      final newTicket = ticket.copyWith(
        id: 'ticket_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return newTicket;
    } catch (e) {
      print('Error creating ticket: $e');
      return null;
    }
  }

  // Update ticket
  Future<Ticket?> updateTicket(String id, Ticket ticket) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 500));

      return ticket.copyWith(id: id, updatedAt: DateTime.now());
    } catch (e) {
      print('Error updating ticket: $e');
      return null;
    }
  }

  // Delete ticket
  Future<bool> deleteTicket(String id) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 500));

      return true;
    } catch (e) {
      print('Error deleting ticket: $e');
      return false;
    }
  }

  // Add comment to ticket
  Future<bool> addComment(String ticketId, TicketComment comment) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 300));

      return true;
    } catch (e) {
      print('Error adding comment: $e');
      return false;
    }
  }

  // Get ticket statistics
  Future<Map<String, int>> getTicketStatistics() async {
    try {
      final tickets = await getTickets();

      final stats = <String, int>{
        'total': tickets.length,
        'open': tickets.where((t) => t.status == TicketStatus.open).length,
        'inProgress': tickets
            .where((t) => t.status == TicketStatus.inProgress)
            .length,
        'resolved': tickets
            .where((t) => t.status == TicketStatus.resolved)
            .length,
        'closed': tickets.where((t) => t.status == TicketStatus.closed).length,
        'overdue': tickets.where((t) => t.isOverdue).length,
      };

      return stats;
    } catch (e) {
      print('Error fetching ticket statistics: $e');
      return {
        'total': 0,
        'open': 0,
        'inProgress': 0,
        'resolved': 0,
        'closed': 0,
        'overdue': 0,
      };
    }
  }

  // Mock data for demonstration
  List<Ticket> _getMockTickets() {
    final now = DateTime.now();

    return [
      Ticket(
        id: 'TK001',
        title: 'Device Communication Failure',
        description:
            'Smart meter ABCD123 is not responding to communication requests. Last seen online 2 days ago.',
        status: TicketStatus.open,
        priority: TicketPriority.high,
        category: TicketCategory.technical,
        assignedTo: 'John Smith',
        createdBy: 'Admin User',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 4)),
        dueDate: now.add(const Duration(days: 1)),
        deviceId: 'ABCD123',
        deviceName: 'Smart Meter ABCD123',
        tags: ['communication', 'smart-meter', 'urgent'],
        comments: [
          TicketComment(
            id: 'C001',
            ticketId: 'TK001',
            author: 'John Smith',
            content: 'Investigating the issue. Checked network connectivity.',
            createdAt: now.subtract(const Duration(hours: 4)),
          ),
        ],
      ),
      Ticket(
        id: 'TK002',
        title: 'Installation Request - New Device',
        description:
            'New smart meter installation required at location XYZ. Customer has provided access details.',
        status: TicketStatus.inProgress,
        priority: TicketPriority.medium,
        category: TicketCategory.installation,
        assignedTo: 'Mike Johnson',
        createdBy: 'Sarah Wilson',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        dueDate: now.add(const Duration(days: 3)),
        tags: ['installation', 'new-device'],
        comments: [
          TicketComment(
            id: 'C002',
            ticketId: 'TK002',
            author: 'Mike Johnson',
            content: 'Scheduled site visit for tomorrow morning.',
            createdAt: now.subtract(const Duration(hours: 2)),
          ),
        ],
      ),
      Ticket(
        id: 'TK003',
        title: 'Meter Reading Discrepancy',
        description:
            'Customer reports meter readings do not match actual consumption. Need to calibrate the device.',
        status: TicketStatus.resolved,
        priority: TicketPriority.medium,
        category: TicketCategory.maintenance,
        assignedTo: 'Emily Davis',
        createdBy: 'Customer Service',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 1)),
        resolvedAt: now.subtract(const Duration(days: 1)),
        dueDate: now.subtract(const Duration(days: 2)),
        deviceId: 'EFG456',
        deviceName: 'Smart Meter EFG456',
        tags: ['calibration', 'readings', 'resolved'],
        comments: [
          TicketComment(
            id: 'C003',
            ticketId: 'TK003',
            author: 'Emily Davis',
            content:
                'Device calibrated successfully. Readings are now accurate.',
            createdAt: now.subtract(const Duration(days: 1)),
          ),
        ],
      ),
      Ticket(
        id: 'TK004',
        title: 'Configuration Update Required',
        description:
            'Update device configuration to support new tariff structure. Affects multiple devices in the area.',
        status: TicketStatus.open,
        priority: TicketPriority.low,
        category: TicketCategory.configuration,
        assignedTo: 'Alex Brown',
        createdBy: 'System Admin',
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 6)),
        dueDate: now.add(const Duration(days: 7)),
        tags: ['configuration', 'tariff', 'bulk-update'],
      ),
      Ticket(
        id: 'TK005',
        title: 'Critical System Alert',
        description:
            'Multiple devices in Zone A are reporting communication errors. Possible network infrastructure issue.',
        status: TicketStatus.inProgress,
        priority: TicketPriority.critical,
        category: TicketCategory.technical,
        assignedTo: 'Network Team',
        createdBy: 'Monitoring System',
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
        dueDate: now.add(const Duration(hours: 4)),
        tags: ['critical', 'network', 'zone-a', 'multiple-devices'],
        comments: [
          TicketComment(
            id: 'C004',
            ticketId: 'TK005',
            author: 'Network Team',
            content: 'Escalated to ISP. Infrastructure issue confirmed.',
            createdAt: now.subtract(const Duration(minutes: 30)),
          ),
        ],
      ),
      Ticket(
        id: 'TK006',
        title: 'Device Replacement',
        description:
            'Old meter HIJ789 needs replacement due to hardware failure. Customer has been notified.',
        status: TicketStatus.open,
        priority: TicketPriority.high,
        category: TicketCategory.maintenance,
        assignedTo: 'Field Team',
        createdBy: 'Maintenance Dept',
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
        updatedAt: now.subtract(const Duration(hours: 8)),
        dueDate: now.add(const Duration(days: 2)),
        deviceId: 'HIJ789',
        deviceName: 'Old Meter HIJ789',
        tags: ['replacement', 'hardware-failure', 'customer-impact'],
      ),
    ];
  }
}
