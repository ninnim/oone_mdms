import 'package:flutter/material.dart';
import 'package:mdms_clone/core/constants/app_sizes.dart';
import '../../themes/app_theme.dart';
import '../../../core/models/site.dart';
import '../common/blunest_data_table.dart';

class SubSiteTableColumns {
  static List<BluNestTableColumn<Site>> getBluNestColumns({
    required BuildContext context,
    required Function(Site) onEdit,
    required Function(Site) onDelete,
    required List<Site> subSites,
    String? sortColumn,
    bool sortAscending = true,
  }) {
    return [
      BluNestTableColumn<Site>(
        key: 'no',
        title: 'No.',
        flex: 1,
        sortable: false,
        builder: (site) {
          final index = subSites.indexOf(site) + 1;
          return Container(
            alignment: Alignment.centerLeft,
            height: AppSizes.rowHeight,
            child: Text(
              index.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: context.textSecondaryColor,
              ),
            ),
          );
        },
      ),
      BluNestTableColumn<Site>(
        key: 'name',
        title: 'Name',
        flex: 2,
        sortable: true,
        builder: (site) => Container(
          alignment: Alignment.centerLeft,
          child: Text(
            site.name,
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: context.textPrimaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      BluNestTableColumn<Site>(
        key: 'description',
        title: 'Description',
        flex: 3,
        sortable: true,
        builder: (site) => Container(
          alignment: Alignment.centerLeft,
          child: Text(
            site.description.isEmpty ? '-' : site.description,
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: context.textPrimaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      BluNestTableColumn<Site>(
        key: 'actions',
        title: 'Actions',
        flex: 1,
        sortable: false,
        isActions: true,
        builder: (site) => Container(
          alignment: Alignment.centerRight,
          child: PopupMenuButton<String>(
            tooltip: 'More actions',
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onEdit(site);
                  break;
                case 'delete':
                  if (site.id != null) {
                    onDelete(site);
                  } else {}
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16, color: context.primaryColor),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                enabled: site.id != null, // Only enable if site has valid ID
                child: Row(
                  children: [
                    Icon(
                      Icons.delete,
                      size: 16,
                      color: site.id != null
                          ? context.errorColor
                          : context.borderColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Delete',
                      style: TextStyle(
                        color: site.id != null
                            ? context.errorColor
                            : context.borderColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.more_vert, size: 16),
          ),
        ),
      ),
    ];
  }

  // Keep the legacy DataTable methods for backward compatibility if needed elsewhere
  static List<DataColumn> getColumns({
    required BuildContext context,
    required Function(Site) onEdit,
    required Function(Site) onDelete,
    String? sortColumn,
    bool sortAscending = true,
    Function(String, bool)? onSort,
  }) {
    return [
      DataColumn(
        label: Expanded(
          child: Text(
            'No.',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        onSort: null, // No sorting for row numbers
      ),
      DataColumn(
        label: Expanded(
          child: Text(
            'Name',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        onSort: onSort != null
            ? (columnIndex, ascending) => onSort('name', ascending)
            : null,
      ),
      DataColumn(
        label: Expanded(
          child: Text(
            'Description',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        onSort: onSort != null
            ? (columnIndex, ascending) => onSort('description', ascending)
            : null,
      ),
      DataColumn(
        label: Expanded(
          child: Text(
            'Actions',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        onSort: null, // No sorting for actions
      ),
    ];
  }

  static DataRow buildRow({
    required BuildContext context,
    required Site site,
    required int rowNumber,
    required bool isSelected,
    required Function(bool?) onSelected,
    required Function(Site) onEdit,
    required Function(Site) onDelete,
  }) {
    return DataRow(
      selected: isSelected,
      onSelectChanged: onSelected,
      cells: [
        DataCell(
          Text(
            rowNumber.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: context.textSecondaryColor,
            ),
          ),
        ),
        DataCell(
          Text(
            site.name,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(
          Text(
            site.description.isEmpty ? '-' : site.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: site.description.isEmpty
                  ? context.textSecondaryColor
                  : context.textPrimaryColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DataCell(
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: context.textSecondaryColor,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onEdit(site);
                  break;
                case 'delete':
                  onDelete(site);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: context.errorColor),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: context.errorColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
