// Example of how to use AppSearchableDropdown in different contexts

// Example 1: Simple string dropdown
AppSearchableDropdown<String>(
  label: 'Status',
  hintText: 'Select status',
  value: selectedStatus,
  height: AppSizes.inputHeight,
  items: [
    const DropdownMenuItem<String>(value: null, child: Text('All')),
    const DropdownMenuItem<String>(value: 'active', child: Text('Active')),
    const DropdownMenuItem<String>(value: 'inactive', child: Text('Inactive')),
  ],
  onChanged: (value) {
    setState(() {
      selectedStatus = value;
    });
  },
)

// Example 2: With search and pagination for large datasets
AppSearchableDropdown<int>(
  label: 'User',
  hintText: 'Select user',
  value: selectedUserId,
  height: AppSizes.inputHeight,
  items: users.map((user) => DropdownMenuItem<int>(
    value: user.id,
    child: Text(user.name),
  )).toList(),
  isLoading: isLoadingUsers,
  hasMore: hasMoreUsers,
  searchQuery: userSearchQuery,
  onChanged: (value) {
    setState(() {
      selectedUserId = value;
    });
  },
  onTap: () {
    if (!usersLoaded) {
      loadUsers();
    }
  },
  onSearchChanged: (query) {
    loadUsers(searchQuery: query);
  },
  onLoadMore: () {
    loadUsers(loadMore: true);
  },
)

// Example 3: Model objects dropdown
AppSearchableDropdown<Department>(
  label: 'Department',
  hintText: 'Select department',
  value: selectedDepartment,
  height: AppSizes.inputHeight,
  items: departments.map((dept) => DropdownMenuItem<Department>(
    value: dept,
    child: Text(dept.name),
  )).toList(),
  onChanged: (value) {
    setState(() {
      selectedDepartment = value;
    });
  },
)
