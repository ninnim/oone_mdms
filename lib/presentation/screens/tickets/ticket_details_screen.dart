import 'package:flutter/material.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/app_input_field.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/ticket.dart';
import '../../../core/services/ticket_service.dart';

class TicketDetailsScreen extends StatefulWidget {
  final Ticket ticket;

  const TicketDetailsScreen({super.key, required this.ticket});

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TicketService _ticketService;
  late TabController _tabController;
  late Ticket _ticket;

  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  bool _isAddingComment = false;

  @override
  void initState() {
    super.initState();
    _ticketService = TicketService();
    _tabController = TabController(length: 3, vsync: this);
    _ticket = widget.ticket;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _updateTicketStatus(TicketStatus newStatus) async {
    setState(() => _isLoading = true);

    try {
      final updatedTicket = _ticket.copyWith(
        status: newStatus,
        resolvedAt: newStatus == TicketStatus.resolved ? DateTime.now() : null,
      );

      final result = await _ticketService.updateTicket(
        _ticket.id,
        updatedTicket,
      );
      if (result != null) {
        setState(() {
          _ticket = result;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ticket status updated to ${newStatus.displayName}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating ticket: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isAddingComment = true);

    try {
      final comment = TicketComment(
        id: 'comment_${DateTime.now().millisecondsSinceEpoch}',
        ticketId: _ticket.id,
        author: 'Current User', // TODO: Get from auth service
        content: _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      final success = await _ticketService.addComment(_ticket.id, comment);
      if (success) {
        setState(() {
          _ticket = _ticket.copyWith(comments: [..._ticket.comments, comment]);
          _commentController.clear();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Comment added successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding comment: $e')));
      }
    } finally {
      setState(() => _isAddingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket ${_ticket.id}'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          if (_ticket.status != TicketStatus.closed)
            PopupMenuButton<TicketStatus>(
              icon: const Icon(Icons.more_vert),
              onSelected: _updateTicketStatus,
              itemBuilder: (context) => [
                if (_ticket.status != TicketStatus.inProgress)
                  PopupMenuItem(
                    value: TicketStatus.inProgress,
                    child: Row(
                      children: [
                        Icon(
                          Icons.play_arrow,
                          color: TicketStatus.inProgress.color,
                        ),
                        const SizedBox(width: 8),
                        const Text('Mark In Progress'),
                      ],
                    ),
                  ),
                if (_ticket.status != TicketStatus.resolved)
                  PopupMenuItem(
                    value: TicketStatus.resolved,
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: TicketStatus.resolved.color,
                        ),
                        const SizedBox(width: 8),
                        const Text('Mark Resolved'),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: TicketStatus.closed,
                  child: Row(
                    children: [
                      Icon(Icons.close, color: TicketStatus.closed.color),
                      const SizedBox(width: 8),
                      const Text('Close Ticket'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildCommentsTab(),
                      _buildHistoryTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _ticket.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacing8),
                    Text(
                      _ticket.description,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.spacing16),
              StatusChip(
                text: _ticket.status.displayName,
                type: _getStatusChipType(_ticket.status),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing16),
          _buildTicketMetadata(),
        ],
      ),
    );
  }

  Widget _buildTicketMetadata() {
    return Row(
      children: [
        _buildMetadataItem(
          icon: Icons.priority_high,
          label: 'Priority',
          value: _ticket.priority.displayName,
          color: _ticket.priority.color,
        ),
        const SizedBox(width: AppSizes.spacing24),
        _buildMetadataItem(
          icon: _ticket.category.icon,
          label: 'Category',
          value: _ticket.category.displayName,
        ),
        const SizedBox(width: AppSizes.spacing24),
        _buildMetadataItem(
          icon: Icons.person,
          label: 'Assigned To',
          value: _ticket.assignedTo,
        ),
        const SizedBox(width: AppSizes.spacing24),
        _buildMetadataItem(
          icon: Icons.access_time,
          label: 'Created',
          value: _ticket.formattedCreatedDate,
        ),
        if (_ticket.dueDate != null) ...[
          const SizedBox(width: AppSizes.spacing24),
          _buildMetadataItem(
            icon: Icons.schedule,
            label: 'Due Date',
            value: _ticket.formattedDueDate,
            color: _ticket.isOverdue ? AppColors.error : null,
          ),
        ],
      ],
    );
  }

  Widget _buildMetadataItem({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? AppColors.textSecondary),
        const SizedBox(width: AppSizes.spacing4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                const Text('Overview'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.comment),
                const SizedBox(width: 8),
                Text('Comments (${_ticket.comments.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history),
                const SizedBox(width: 8),
                const Text('History'),
              ],
            ),
          ),
        ],
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spacing24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDescriptionCard(),
                const SizedBox(height: AppSizes.spacing16),
                if (_ticket.deviceId != null) _buildDeviceInfoCard(),
                const SizedBox(height: AppSizes.spacing16),
                _buildTagsCard(),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.spacing24),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildTicketInfoCard(),
                const SizedBox(height: AppSizes.spacing16),
                _buildAttachmentsCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.spacing12),
            Text(
              _ticket.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Related Device',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.spacing12),
            ListTile(
              leading: const Icon(Icons.device_hub, color: AppColors.primary),
              title: Text(_ticket.deviceName ?? 'Unknown Device'),
              subtitle: Text('ID: ${_ticket.deviceId}'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to device details
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigate to device details')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsCard() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tags',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.spacing12),
            if (_ticket.tags.isEmpty)
              const Text(
                'No tags assigned',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              )
            else
              Wrap(
                spacing: AppSizes.spacing8,
                runSpacing: AppSizes.spacing8,
                children: _ticket.tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        labelStyle: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketInfoCard() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ticket Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.spacing16),
            _buildInfoRow('Created By', _ticket.createdBy),
            _buildInfoRow('Created At', _ticket.formattedCreatedDate),
            _buildInfoRow('Last Updated', _ticket.formattedCreatedDate),
            if (_ticket.resolvedAt != null)
              _buildInfoRow('Resolved At', _ticket.formattedCreatedDate),
            if (_ticket.timeToResolve != null)
              _buildInfoRow(
                'Resolution Time',
                '${_ticket.timeToResolve!.inHours}h',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsCard() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Attachments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Add attachment functionality coming soon',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing12),
            if (_ticket.attachments.isEmpty)
              const Text(
                'No attachments',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              )
            else
              ...(_ticket.attachments.map(
                (attachment) => ListTile(
                  leading: Icon(
                    _getFileIcon(attachment.fileType),
                    color: AppColors.primary,
                  ),
                  title: Text(attachment.fileName),
                  subtitle: Text(attachment.formattedFileSize),
                  trailing: const Icon(Icons.download),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Download ${attachment.fileName}'),
                      ),
                    );
                  },
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSizes.spacing24),
            itemCount: _ticket.comments.length,
            itemBuilder: (context, index) {
              final comment = _ticket.comments[index];
              return _buildCommentCard(comment);
            },
          ),
        ),
        _buildAddCommentSection(),
      ],
    );
  }

  Widget _buildCommentCard(TicketComment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacing16),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      comment.author[0].toUpperCase(),
                      style: TextStyle(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.spacing8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment.author,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          comment.createdAt.toString().substring(0, 16),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (comment.isInternal)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'INTERNAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSizes.spacing12),
              Text(
                comment.content,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddCommentSection() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Comment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.spacing12),
          AppInputField(
            controller: _commentController,
            hintText: 'Type your comment here...',
            maxLines: 3,
          ),
          const SizedBox(height: AppSizes.spacing12),
          Row(
            children: [
              const Spacer(),
              AppButton(
                text: 'Add Comment',
                onPressed: _isAddingComment ? null : _addComment,
                type: AppButtonType.primary,
                isLoading: _isAddingComment,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    // TODO: Implement ticket history/activity log
    return const Center(child: Text('Ticket history coming soon...'));
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

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.attach_file;
    }
  }
}
