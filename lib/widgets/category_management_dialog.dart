import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/frosted_glass_card.dart';
import '../components/glass_button.dart';
import '../core/models/prayer_category.dart';
import '../core/providers/category_providers.dart';
import '../core/widgets/app_snackbar.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../utils/blur_dialog_utils.dart';

class CategoryManagementDialog extends ConsumerStatefulWidget {
  const CategoryManagementDialog({super.key});

  @override
  ConsumerState<CategoryManagementDialog> createState() => _CategoryManagementDialogState();
}

class _CategoryManagementDialogState extends ConsumerState<CategoryManagementDialog> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: FrostedGlassCard(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Manage Categories',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 20, minSize: 18, maxSize: 24),
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  borderRadius: AppRadius.mediumRadius,
                  border: Border.all(
                    color: AppTheme.primaryColor,
                    width: 1,
                  ),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                ),
                tabs: const [
                  Tab(text: 'All Categories'),
                  Tab(text: 'Add New'),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCategoryList(categoriesAsync),
                    _buildAddCategoryForm(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(AsyncValue<List<PrayerCategory>> categoriesAsync) {
    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return Center(
            child: Text(
              'No categories found',
              style: TextStyle(
                color: AppColors.tertiaryText,
                fontSize: ResponsiveUtils.fontSize(context, 14),
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _buildCategoryListItem(category);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          'Error loading categories: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildCategoryListItem(PrayerCategory category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: AppRadius.mediumRadius,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.2),
              borderRadius: AppRadius.smallRadius,
              border: Border.all(
                color: category.color.withValues(alpha: 0.5),
              ),
            ),
            child: Icon(
              category.icon,
              color: category.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 15, minSize: 13, maxSize: 17),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (category.isDefault)
                  Text(
                    'Default Category',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 11, minSize: 9, maxSize: 13),
                      color: AppColors.tertiaryText,
                    ),
                  ),
              ],
            ),
          ),
          if (!category.isDefault) ...[
            IconButton(
              icon: Icon(
                Icons.edit,
                color: AppColors.primaryText,
                size: ResponsiveUtils.iconSize(context, 18),
              ),
              onPressed: () => _showEditCategoryDialog(category),
            ),
            IconButton(
              icon: Icon(
                Icons.delete,
                color: Colors.red.withValues(alpha: 0.8),
                size: ResponsiveUtils.iconSize(context, 18),
              ),
              onPressed: () => _deleteCategory(category),
            ),
          ],
          IconButton(
            icon: Icon(
              category.isActive ? Icons.visibility : Icons.visibility_off,
              color: category.isActive ? Colors.green : Colors.grey,
              size: ResponsiveUtils.iconSize(context, 18),
            ),
            onPressed: () => _toggleCategoryActive(category),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCategoryForm() {
    String categoryName = '';
    IconData selectedIcon = Icons.category;
    Color selectedColor = Colors.blue;

    return StatefulBuilder(
      builder: (context, setState) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Name',
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              onChanged: (value) => categoryName = value,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter category name',
                hintStyle: TextStyle(color: AppColors.tertiaryText),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.mediumRadius,
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Select Icon',
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 120,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: CategoryPresets.availableIcons.length,
                itemBuilder: (context, index) {
                  final icon = CategoryPresets.availableIcons[index];
                  final isSelected = selectedIcon.codePoint == icon.codePoint;

                  return GestureDetector(
                    onTap: () => setState(() => selectedIcon = icon),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? selectedColor.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: AppRadius.smallRadius,
                        border: Border.all(
                          color: isSelected
                              ? selectedColor
                              : Colors.white.withValues(alpha: 0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? selectedColor : Colors.white.withValues(alpha: 0.6),
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Select Color',
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 60,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: CategoryPresets.availableColors.length,
                itemBuilder: (context, index) {
                  final color = CategoryPresets.availableColors[index];
                  final isSelected = selectedColor.toARGB32() == color.toARGB32();

                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = color),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    text: 'Cancel',
                    height: 48,
                    onPressed: () {
                      if (mounted) _tabController.animateTo(0);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: GlassButton(
                    text: 'Create',
                    height: 48,
                    onPressed: () async {
                      if (categoryName.isNotEmpty) {
                        await _createCategory(
                          categoryName,
                          selectedIcon.codePoint,
                          selectedColor.toARGB32(),
                        );
                        if (mounted) _tabController.animateTo(0);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(PrayerCategory category) {
    String categoryName = category.name;
    IconData selectedIcon = category.icon;
    Color selectedColor = category.color;

    showBlurredDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: FrostedGlassCard(
          child: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Category',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 20, minSize: 18, maxSize: 24),
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Category Name',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: TextEditingController(text: categoryName),
                    onChanged: (value) => categoryName = value,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.mediumRadius,
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Select Icon',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 120,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: CategoryPresets.availableIcons.length,
                      itemBuilder: (context, index) {
                        final icon = CategoryPresets.availableIcons[index];
                        final isSelected = selectedIcon.codePoint == icon.codePoint;

                        return GestureDetector(
                          onTap: () => setState(() => selectedIcon = icon),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? selectedColor.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.1),
                              borderRadius: AppRadius.smallRadius,
                              border: Border.all(
                                color: isSelected
                                    ? selectedColor
                                    : Colors.white.withValues(alpha: 0.2),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Icon(
                              icon,
                              color: isSelected ? selectedColor : Colors.white.withValues(alpha: 0.6),
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Select Color',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 60,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: CategoryPresets.availableColors.length,
                      itemBuilder: (context, index) {
                        final color = CategoryPresets.availableColors[index];
                        final isSelected = selectedColor.toARGB32() == color.toARGB32();

                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = color),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: isSelected ? 3 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Row(
                    children: [
                      Expanded(
                        child: GlassButton(
                          text: 'Cancel',
                          height: 48,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: GlassButton(
                          text: 'Save',
                          height: 48,
                          onPressed: () async {
                            if (categoryName.isNotEmpty) {
                              await _updateCategory(
                                category.copyWith(
                                  name: categoryName,
                                  iconCodePoint: selectedIcon.codePoint,
                                  colorValue: selectedColor.toARGB32(),
                                ),
                              );
                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createCategory(String name, int iconCodePoint, int colorValue) async {
    final actions = ref.read(categoryActionsProvider);

    try {
      await actions.createCategory(name, iconCodePoint, colorValue);

      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: 'Category "$name" created successfully',
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        message: 'Error creating category: $e',
      );
    }
  }

  Future<void> _updateCategory(PrayerCategory category) async {
    final actions = ref.read(categoryActionsProvider);

    try {
      await actions.updateCategory(category);

      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: 'Category "${category.name}" updated successfully',
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        message: 'Error updating category: $e',
      );
    }
  }

  Future<void> _deleteCategory(PrayerCategory category) async {
    final confirmed = await showBlurredDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: FrostedGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: ResponsiveUtils.iconSize(context, 48),
                color: Colors.orange,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Delete Category',
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 20, minSize: 18, maxSize: 24),
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Are you sure you want to delete "${category.name}"?',
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      text: 'Cancel',
                      height: 48,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: AppRadius.largeCardRadius,
                        border: Border.all(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(true),
                          borderRadius: AppRadius.largeCardRadius,
                          child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            child: Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w700,
                                fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      final actions = ref.read(categoryActionsProvider);

      try {
        await actions.deleteCategory(category.id);

        if (!mounted) return;
        AppSnackBar.show(
          context,
          message: 'Category "${category.name}" deleted',
          icon: Icons.delete_forever,
          iconColor: Colors.redAccent,
        );
      } catch (e) {
        if (!mounted) return;
        AppSnackBar.showError(
          context,
          message: 'Error deleting category: $e',
        );
      }
    }
  }

  Future<void> _toggleCategoryActive(PrayerCategory category) async {
    final actions = ref.read(categoryActionsProvider);

    try {
      await actions.toggleCategoryActive(category.id);

      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: 'Category "${category.name}" ${category.isActive ? "deactivated" : "activated"}',
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        message: 'Error toggling category: $e',
      );
    }
  }
}
