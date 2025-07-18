import 'package:flutter/material.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/common/kanban_view.dart';
import '../../widgets/common/advanced_filters.dart';
import '../../widgets/common/results_pagination.dart';
import '../../widgets/common/app_lottie_state_widget.dart';
import '../../widgets/modals/create_ticket_modal.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/ticket.dart';
import '../../../core/services/ticket_service.dart';
import 'ticket_details_screen.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  late final TicketService _ticketService;
  List<Ticket> _tickets = [];
  List<Ticket> _filteredTickets = [];
  Map<String, int> _statistics = {};
  bool _isLoading = true;
  String _selectedView = 'table'; // table, kanban
  String _searchQuery = '';
  TicketStatus? _statusFilter;
  TicketPriority? _priorityFilter;
  TicketCategory? _categoryFilter;
  String? _assigneeFilter;

  // Pagination
  int _currentPage = 1;
  int _itemsPerPage = 25;
  int get _totalPages => ((_filteredTickets.length / _itemsPerPage).ceil())
      .clamp(1, double.infinity)
      .toInt();

  @override
  void initState() {
    super.initState();
    _ticketService = TicketService();
    _loadTickets();
    _loadStatistics();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);

    try {
      final tickets = await _ticketService.getTickets();
      setState(() {
        _tickets = tickets;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading tickets: $e')));
      }
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await _ticketService.getTicketStatistics();
      setState(() => _statistics = stats);
    } catch (e) {
      // Error loading statistics: $e
    }
  }

  void _applyFilters() {
    _filteredTickets = _tickets.where((ticket) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!ticket.title.toLowerCase().contains(query) &&
            !ticket.description.toLowerCase().contains(query) &&
            !ticket.assignedTo.toLowerCase().contains(query) &&
            !(ticket.deviceName?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      if (_statusFilter != null && ticket.status != _statusFilter) return false;
      if (_priorityFilter != null && ticket.priority != _priorityFilter) {
        return false;
      }
      if (_categoryFilter != null && ticket.category != _categoryFilter) {
        return false;
      }
      if (_assigneeFilter != null && ticket.assignedTo != _assigneeFilter) {
        return false;
      }

      return true;
    }).toList();

    // Reset to first page when filters change
    _currentPage = 1;
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _statusFilter = null;
      _priorityFilter = null;
      _categoryFilter = null;
      _assigneeFilter = null;
      _currentPage = 1;
    });
    _applyFilters();
  }

  void _showCreateTicketModal() {
    showDialog(
      context: context,
      builder: (context) => const CreateTicketModal(),
    ).then((_) {
      // Refresh tickets after creating
      _loadTickets();
      _loadStatistics();
    });
  }

  void _showTicketDetails(Ticket ticket) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => TicketDetailsScreen(ticket: ticket),
          ),
        )
        .then((_) {
          // Refresh tickets after viewing details (in case status was updated)
          _loadTickets();
          _loadStatistics();
        });
  }

  List<Ticket> get _paginatedTickets {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(
      0,
      _filteredTickets.length,
    );
    return _filteredTickets.sublist(startIndex, endIndex);
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (_isLoading && _tickets.isEmpty) {
      return const AppLottieStateWidget.loading(
        title: 'Loading Tickets',
        message: 'Please wait while we fetch your support tickets...',
      );
    }

    // Show no data state if no tickets after loading
    if (!_isLoading && _tickets.isEmpty) {
      return AppLottieStateWidget.noData(
        title: 'No Tickets Found',
        message:
            'No support tickets have been created yet. Click "Create Ticket" to get started.',
        buttonText: 'Create Ticket',
        onButtonPressed: _showCreateTicketModal,
      );
    }

    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: AppSizes.spacing16),
        _buildStatisticsCards(),
        const SizedBox(height: AppSizes.spacing24),
        _buildFiltersAndActions(),
        const SizedBox(height: AppSizes.spacing16),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    // Show filtered empty state if filtered tickets are empty but original tickets exist
    if (!_isLoading && _filteredTickets.isEmpty && _tickets.isNotEmpty) {
      return AppLottieStateWidget.noData(
        title: 'No Matching Tickets',
        message:
            'No tickets match your current filters. Try adjusting your search criteria.',
        buttonText: 'Clear Filters',
        onButtonPressed: _clearFilters,
      );
    }

    return _selectedView == 'table' ? _buildTableView() : _buildKanbanView();
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tickets Management',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing4),
                Text(
                  'Manage support tickets, issues, and requests',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AppButton(
            text: 'Create Ticket',
            onPressed: _showCreateTicketModal,
            type: AppButtonType.primary,
            icon: const Icon(Icons.add, color: AppColors.textInverse),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing24),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              _statistics['total'] ?? 0,
              AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSizes.spacing16),
          Expanded(
            child: _buildStatCard(
              'Open',
              _statistics['open'] ?? 0,
              TicketStatus.open.color,
            ),
          ),
          const SizedBox(width: AppSizes.spacing16),
          Expanded(
            child: _buildStatCard(
              'In Progress',
              _statistics['inProgress'] ?? 0,
              TicketStatus.inProgress.color,
            ),
          ),
          const SizedBox(width: AppSizes.spacing16),
          Expanded(
            child: _buildStatCard(
              'Resolved',
              _statistics['resolved'] ?? 0,
              TicketStatus.resolved.color,
            ),
          ),
          const SizedBox(width: AppSizes.spacing16),
          Expanded(
            child: _buildStatCard(
              'Overdue',
              _statistics['overdue'] ?? 0,
              AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int value, Color color) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: AppSizes.spacing4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersAndActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing24),
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 2,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search tickets...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),
          const SizedBox(width: AppSizes.spacing16),

          // Advanced Filters
          AdvancedFilters(
            filterConfigs: [
              FilterConfig(
                key: 'status',
                label: 'Status',
                type: FilterType.dropdown,
                options: [
                  'Open',
                  'In Progress',
                  'Resolved',
                  'Closed',
                  'Cancelled',
                ],
              ),
              FilterConfig(
                key: 'priority',
                label: 'Priority',
                type: FilterType.dropdown,
                options: ['Low', 'Medium', 'High', 'Critical'],
              ),
              FilterConfig(
                key: 'category',
                label: 'Category',
                type: FilterType.dropdown,
                options: [
                  'Technical',
                  'Maintenance',
                  'Installation',
                  'Configuration',
                  'Support',
                  'General',
                ],
              ),
              FilterConfig(
                key: 'assignee',
                label: 'Assignee',
                type: FilterType.dropdown,
                options: [
                  'John Smith',
                  'Mike Johnson',
                  'Emily Davis',
                  'Alex Brown',
                  'Network Team',
                  'Field Team',
                ],
              ),
            ],
            initialValues: const {},
            onFiltersChanged: (filters) {
              setState(() {
                _statusFilter = filters['status'] != null
                    ? TicketStatusExtension.fromString(filters['status']!)
                    : null;
                _priorityFilter = filters['priority'] != null
                    ? TicketPriorityExtension.fromString(filters['priority']!)
                    : null;
                _categoryFilter = filters['category'] != null
                    ? TicketCategoryExtension.fromString(filters['category']!)
                    : null;
                _assigneeFilter = filters['assignee'];
                _applyFilters();
              });
            },
          ),

          const SizedBox(width: AppSizes.spacing16),

          // View Toggle
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewToggle(Icons.table_rows, 'table'),
                _buildViewToggle(Icons.view_kanban, 'kanban'),
              ],
            ),
          ),

          const SizedBox(width: AppSizes.spacing16),

          // Clear Filters
          if (_searchQuery.isNotEmpty ||
              _statusFilter != null ||
              _priorityFilter != null ||
              _categoryFilter != null ||
              _assigneeFilter != null)
            AppButton(
              text: 'Clear',
              onPressed: _clearFilters,
              type: AppButtonType.secondary,
              size: AppButtonSize.small,
            ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(IconData icon, String view) {
    final isSelected = _selectedView == view;
    return GestureDetector(
      onTap: () => setState(() => _selectedView = view),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.spacing8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTableView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing24),
      child: AppCard(
        child: Column(
          children: [
            Expanded(
              child: BluNestDataTable<Ticket>(
                data: _paginatedTickets,
                columns: _buildTableColumns(),
                onRowTap: _showTicketDetails,
                isLoading: _isLoading,
              ),
            ),
            if (_totalPages > 1) _buildPagination(),
          ],
        ),
      ),
    );
  }

  List<BluNestTableColumn<Ticket>> _buildTableColumns() {
    return [
      BluNestTableColumn<Ticket>(
        key: 'id',
        title: 'ID',
        builder: (ticket) => Text(
          ticket.id,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
      ),
      BluNestTableColumn<Ticket>(
        key: 'title',
        title: 'Title',
        builder: (ticket) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ticket.title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (ticket.deviceName != null) ...[
              const SizedBox(height: 2),
              Text(
                ticket.deviceName!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
      BluNestTableColumn<Ticket>(
        key: 'status',
        title: 'Status',
        builder: (ticket) => StatusChip(
          text: ticket.status.displayName,
          type: _getStatusChipType(ticket.status),
        ),
      ),
      BluNestTableColumn<Ticket>(
        key: 'priority',
        title: 'Priority',
        builder: (ticket) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: ticket.priority.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: ticket.priority.color.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            ticket.priority.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ticket.priority.color,
            ),
          ),
        ),
      ),
      BluNestTableColumn<Ticket>(
        key: 'category',
        title: 'Category',
        builder: (ticket) => Row(
          children: [
            Icon(
              ticket.category.icon,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              ticket.category.displayName,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      BluNestTableColumn<Ticket>(
        key: 'assignedTo',
        title: 'Assigned To',
        builder: (ticket) => Text(
          ticket.assignedTo,
          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
        ),
      ),
      BluNestTableColumn<Ticket>(
        key: 'created',
        title: 'Created',
        builder: (ticket) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ticket.formattedCreatedDate,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
            if (ticket.isOverdue) ...[
              const SizedBox(height: 2),
              Text(
                ticket.overdueDays,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    ];
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  StatusChipType _getStatusChipType(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return StatusChipType.info;
      case TicketStatus.inProgress:
        return StatusChipType.warning;
      case TicketStatus.resolved:
        return StatusChipType.success;
      case TicketStatus.closed:
        return StatusChipType.secondary;
      case TicketStatus.cancelled:
        return StatusChipType.error;
    }
  }

  StatusChipType _getPriorityStatusChipType(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return StatusChipType.info;
      case TicketPriority.medium:
        return StatusChipType.warning;
      case TicketPriority.high:
        return StatusChipType.error;
      case TicketPriority.critical:
        return StatusChipType.error;
    }
  }

  TicketStatus _getStatusFromColumnId(String columnId) {
    switch (columnId) {
      case 'open':
        return TicketStatus.open;
      case 'inProgress':
        return TicketStatus.inProgress;
      case 'resolved':
        return TicketStatus.resolved;
      case 'closed':
        return TicketStatus.closed;
      default:
        return TicketStatus.open;
    }
  }

  Widget _buildKanbanView() {
    return KanbanView<Ticket>(
      columns: [
        KanbanColumn<Ticket>(
          id: 'open',
          title: 'Open',
          color: TicketStatus.open.color,
        ),
        KanbanColumn<Ticket>(
          id: 'inProgress',
          title: 'In Progress',
          color: TicketStatus.inProgress.color,
        ),
        KanbanColumn<Ticket>(
          id: 'resolved',
          title: 'Resolved',
          color: TicketStatus.resolved.color,
        ),
        KanbanColumn<Ticket>(
          id: 'closed',
          title: 'Closed',
          color: TicketStatus.closed.color,
        ),
      ],
      items: _filteredTickets,
      getItemColumn: (ticket) => ticket.status.toString().split('.').last,
      cardBuilder: (ticket) => Card(
        margin: const EdgeInsets.only(bottom: AppSizes.spacing8),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spacing12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusChip(
                    text: ticket.priority.toString().split('.').last,
                    type: _getPriorityStatusChipType(ticket.priority),
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spacing8),
              Text(
                ticket.description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSizes.spacing8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ticket.assignedTo,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    _formatDate(ticket.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      onItemTapped: _showTicketDetails,
      onItemMoved: (ticket, fromColumn, toColumn) {
        // Update ticket status when moved between columns
        final newStatus = _getStatusFromColumnId(toColumn);
        // TODO: Implement status update API call
        setState(() {
          final index = _tickets.indexWhere((t) => t.id == ticket.id);
          if (index >= 0) {
            _tickets[index] = ticket.copyWith(status: newStatus);
            _applyFilters();
          }
        });
      },
      isLoading: _isLoading,
      enablePagination: true,
      itemsPerPage: 20,
    );
  }

  Widget _buildPagination() {
    final startItem = (_currentPage - 1) * _itemsPerPage + 1;
    final endItem = (_currentPage * _itemsPerPage) > _filteredTickets.length
        ? _filteredTickets.length
        : _currentPage * _itemsPerPage;

    return ResultsPagination(
      currentPage: _currentPage,
      totalPages: _totalPages,
      totalItems: _filteredTickets.length,
      itemsPerPage: _itemsPerPage,
      startItem: startItem,
      endItem: endItem,
      onPageChanged: (page) {
        setState(() {
          _currentPage = page;
        });
      },
      onItemsPerPageChanged: (newItemsPerPage) {
        setState(() {
          _itemsPerPage = newItemsPerPage;
          _currentPage = 1;
        });
      },
      itemLabel: 'tickets',
      showItemsPerPageSelector: true,
    );
  }
}
