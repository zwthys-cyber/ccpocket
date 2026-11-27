import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const List<String> _zhFontFallback = [
    'Microsoft YaHei', // Windows
    'PingFang SC', // macOS / iOS
    'Noto Sans CJK SC', // Linux / Android
  ];

  static ThemeData get lightTheme {
    return lightThemeForLocale(null);
  }

  static ThemeData lightThemeForLocale(Locale? locale) {
    const colorScheme = ColorScheme.light(
      surface: Color(0xFFECE8DF),
      surfaceDim: Color(0xFFE1DDD4),
      surfaceBright: Color(0xFFF3EFE8),
      onSurface: Color(0xFF363532),
      onSurfaceVariant: Color(0xFF575550),
      surfaceContainerLowest: Color(0xFFF3EFE8),
      surfaceContainerLow: Color(0xFFEAE6DE),
      surfaceContainer: Color(0xFFE5E1D8),
      surfaceContainerHigh: Color(0xFFF0ECE4),
      surfaceContainerHighest: Color(0xFFDAD6CE),
      primary: Color(0xFF4A5C70),
      onPrimary: Color(0xFFF3EFE8),
      primaryContainer: Color(0xFFDDE2E7),
      onPrimaryContainer: Color(0xFF34465B),
      secondary: Color(0xFF625951),
      onSecondary: Color(0xFFF3EFE8),
      secondaryContainer: Color(0xFFE5DBD1),
      onSecondaryContainer: Color(0xFF4A3E35),
      tertiary: Color(0xFF785522),
      onTertiary: Color(0xFFF3EFE8),
      tertiaryContainer: Color(0xFFEFE2CB),
      onTertiaryContainer: Color(0xFF523917),
      error: Color(0xFF903E49),
      onError: Color(0xFFF8EEEB),
      errorContainer: Color(0xFFF0DDDB),
      onErrorContainer: Color(0xFF863A46),
      outline: Color(0xFF65615B),
      outlineVariant: Color(0xFFCDC9C0),
      inverseSurface: Color(0xFF323235),
      onInverseSurface: Color(0xFFECE8DF),
      inversePrimary: Color(0xFFA0B0C3),
      surfaceTint: Color(0xFF4A5C70),
    );

    return _buildTheme(
      colorScheme,
      Brightness.light,
      AppColors.light(),
      locale: locale,
    );
  }

  static ThemeData get darkTheme {
    return darkThemeForLocale(null);
  }

  static ThemeData darkThemeForLocale(Locale? locale) {
    const colorScheme = ColorScheme.dark(
      surface: Color(0xFF242427),
      surfaceDim: Color(0xFF242427),
      surfaceBright: Color(0xFF3B3B40),
      onSurface: Color(0xFFD6D2CC),
      onSurfaceVariant: Color(0xFFAFAAAB),
      surfaceContainerLowest: Color(0xFF202023),
      surfaceContainerLow: Color(0xFF29292C),
      surfaceContainer: Color(0xFF2D2D30),
      surfaceContainerHigh: Color(0xFF323235),
      surfaceContainerHighest: Color(0xFF3B3B40),
      primary: Color(0xFFA0B0C3),
      onPrimary: Color(0xFF252E39),
      primaryContainer: Color(0xFF374352),
      onPrimaryContainer: Color(0xFFCED8E3),
      secondary: Color(0xFFC1AA9A),
      onSecondary: Color(0xFF342B25),
      secondaryContainer: Color(0xFF483B34),
      onSecondaryContainer: Color(0xFFDCC8BA),
      tertiary: Color(0xFFCFB283),
      onTertiary: Color(0xFF342617),
      tertiaryContainer: Color(0xFF4D3C26),
      onTertiaryContainer: Color(0xFFE0C89E),
      error: Color(0xFFDDA0A5),
      onError: Color(0xFF452634),
      errorContainer: Color(0xFF402B31),
      onErrorContainer: Color(0xFFDDA0A5),
      outline: Color(0xFFA39E9F),
      outlineVariant: Color(0xFF49474C),
      inverseSurface: Color(0xFFE5E1D8),
      onInverseSurface: Color(0xFF363532),
      inversePrimary: Color(0xFF4A5C70),
      surfaceTint: Color(0xFFA0B0C3),
    );

    return _buildTheme(
      colorScheme,
      Brightness.dark,
      AppColors.dark(),
      locale: locale,
    );
  }

  static ThemeData _buildTheme(
    ColorScheme colorScheme,
    Brightness brightness,
    AppColors appColors, {
    Locale? locale,
  }) {
    final textTheme = _buildTextTheme(colorScheme, locale: locale);
    final controlRadius = BorderRadius.circular(10);
    final panelRadius = BorderRadius.circular(14);
    final panelBorder = BorderSide(color: colorScheme.outlineVariant);
    final controlShape = RoundedRectangleBorder(borderRadius: controlRadius);
    final panelShape = RoundedRectangleBorder(
      borderRadius: panelRadius,
      side: panelBorder,
    );
    final fieldBorder = OutlineInputBorder(
      borderRadius: controlRadius,
      borderSide: panelBorder,
    );
    final fieldFocusBorder = fieldBorder.copyWith(
      borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
    );
    final fieldErrorBorder = fieldBorder.copyWith(
      borderSide: BorderSide(color: colorScheme.error, width: 1.5),
    );
    final menuStyle = MenuStyle(
      backgroundColor: WidgetStatePropertyAll(colorScheme.surfaceContainerHigh),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      shape: WidgetStatePropertyAll(panelShape),
      elevation: const WidgetStatePropertyAll(3),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      extensions: [appColors],

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        shape: panelShape,
        color: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 1,
        highlightElevation: 2,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: panelShape,
      ),

      // FilledButton
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: controlShape,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          side: panelBorder,
          shape: controlShape,
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: controlShape,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.surfaceContainerHigh,
          foregroundColor: colorScheme.primary,
          elevation: 1,
          shape: controlShape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(controlShape),
        ),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
        side: BorderSide(color: colorScheme.outline, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldFocusBorder,
        errorBorder: fieldErrorBorder,
        focusedErrorBorder: fieldErrorBorder,
        hintStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
        labelStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: textTheme.labelMedium,
        side: panelBorder,
        shape: controlShape,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // SegmentedButton
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(controlShape),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primary;
            }
            return null;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onPrimary;
            }
            return null;
          }),
        ),
      ),

      // DropdownMenu
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: menuStyle,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surfaceContainerHigh,
          border: fieldBorder,
          enabledBorder: fieldBorder,
          focusedBorder: fieldFocusBorder,
        ),
      ),
      menuTheme: MenuThemeData(style: menuStyle),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: panelShape,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: panelShape,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),

      // BottomSheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        modalBackgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: colorScheme.outline,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),

      // Icon
      iconTheme: IconThemeData(color: colorScheme.onSurface, size: 24),

      // ListTile
      listTileTheme: ListTileThemeData(
        shape: controlShape,
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        selectedColor: colorScheme.onPrimaryContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer,
        indicatorShape: controlShape,
        elevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        indicatorColor: colorScheme.primaryContainer,
        indicatorShape: controlShape,
      ),
      bottomAppBarTheme: BottomAppBarThemeData(
        color: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      bannerTheme: MaterialBannerThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        dividerColor: colorScheme.outlineVariant,
        contentTextStyle: textTheme.bodyMedium,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        dividerColor: colorScheme.outlineVariant,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.primary,
        selectionColor: colorScheme.primary.withValues(alpha: 0.23),
        selectionHandleColor: colorScheme.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.14),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return null;
          return states.contains(WidgetState.selected)
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest;
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return null;
          return states.contains(WidgetState.selected)
              ? colorScheme.onPrimary
              : colorScheme.outline;
        }),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: colorScheme.error,
        textColor: colorScheme.onError,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: colorScheme.inversePrimary,
        shape: controlShape,
        behavior: SnackBarBehavior.floating,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: controlRadius,
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme colorScheme, {Locale? locale}) {
    final baseTextTheme = GoogleFonts.ibmPlexSansTextTheme();

    // Headlines: Space Grotesk — geometric, distinctive, avoids generic Poppins
    // Body/Labels: IBM Plex Sans — professional & readable, avoids generic Inter
    final textTheme = baseTextTheme.copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: colorScheme.onSurface,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        color: colorScheme.onSurface,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        color: colorScheme.onSurface,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleLarge: GoogleFonts.ibmPlexSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleMedium: GoogleFonts.ibmPlexSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
      ),
      titleSmall: GoogleFonts.ibmPlexSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
      ),
      bodyLarge: GoogleFonts.ibmPlexSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.35,
        letterSpacing: 0.25,
        color: colorScheme.onSurface,
      ),
      bodyMedium: GoogleFonts.ibmPlexSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.35,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
      ),
      bodySmall: GoogleFonts.ibmPlexSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.3,
        letterSpacing: 0.25,
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: GoogleFonts.ibmPlexSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
      ),
      labelMedium: GoogleFonts.ibmPlexSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: colorScheme.onSurface,
      ),
      labelSmall: GoogleFonts.ibmPlexSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: colorScheme.onSurfaceVariant,
      ),
    );

    if (locale?.languageCode.toLowerCase() == 'zh') {
      return textTheme.apply(fontFamilyFallback: _zhFontFallback);
    }
    return textTheme;
  }
}

// ---------------------------------------------------------------------------
// AppColors: Semantic color tokens (ThemeExtension)
// ---------------------------------------------------------------------------

class AppColors extends ThemeExtension<AppColors> {
  static const mediaSurface = Color(0xFF202024);
  static const mediaForeground = Color(0xFFE3DED6);

  // User bubble
  final Color userBubble;
  final Color userBubbleText;

  // Assistant bubble
  final Color assistantBubble;

  // Tool use
  final Color toolBubble;
  final Color toolBubbleBorder;
  final Color toolIcon;

  // Error
  final Color errorBubble;
  final Color errorBubbleBorder;
  final Color errorText;

  // Warning (info-level, non-critical alerts)
  final Color warningBubble;
  final Color warningBubbleBorder;
  final Color warningText;

  // Permission
  final Color permissionBubble;
  final Color permissionBubbleBorder;
  final Color permissionIcon;

  // Ask
  final Color askBubble;
  final Color askBubbleBorder;
  final Color askIcon;

  // Chips
  final Color systemChip;
  final Color successChip;
  final Color errorChip;

  // Approval bar
  final Color approvalBar;
  final Color approvalBarBorder;

  // Status
  final Color statusStarting;
  final Color statusRunning;
  final Color statusApproval;
  final Color statusCompacting;
  final Color statusIdle;
  final Color statusOnline;
  final Color statusPlan;
  final Color statusPlanGlow;

  // Subtle text
  final Color subtleText;

  // Code block
  final Color codeBackground;
  final Color codeBorder;

  // Tool result
  final Color toolResultBackground;
  final Color toolResultText;
  final Color toolResultTextExpanded;

  // Diff viewer
  final Color diffAdditionBackground;
  final Color diffAdditionText;
  final Color diffDeletionBackground;
  final Color diffDeletionText;

  const AppColors({
    required this.userBubble,
    required this.userBubbleText,
    required this.assistantBubble,
    required this.toolBubble,
    required this.toolBubbleBorder,
    required this.toolIcon,
    required this.errorBubble,
    required this.errorBubbleBorder,
    required this.errorText,
    required this.warningBubble,
    required this.warningBubbleBorder,
    required this.warningText,
    required this.permissionBubble,
    required this.permissionBubbleBorder,
    required this.permissionIcon,
    required this.askBubble,
    required this.askBubbleBorder,
    required this.askIcon,
    required this.systemChip,
    required this.successChip,
    required this.errorChip,
    required this.approvalBar,
    required this.approvalBarBorder,
    required this.statusStarting,
    required this.statusRunning,
    required this.statusApproval,
    required this.statusCompacting,
    required this.statusIdle,
    required this.statusOnline,
    required this.statusPlan,
    required this.statusPlanGlow,
    required this.subtleText,
    required this.codeBackground,
    required this.codeBorder,
    required this.toolResultBackground,
    required this.toolResultText,
    required this.toolResultTextExpanded,
    required this.diffAdditionBackground,
    required this.diffAdditionText,
    required this.diffDeletionBackground,
    required this.diffDeletionText,
  });

  factory AppColors.light() => const AppColors(
    userBubble: Color(0xFFDDE2E7),
    userBubbleText: Color(0xFF34465B),
    assistantBubble: Color(0xFFF0ECE4),
    toolBubble: Color(0xFFE6E7E8),
    toolBubbleBorder: Color(0xFFC9CDD2),
    toolIcon: Color(0xFF4A5C70),
    errorBubble: Color(0xFFF0DDDB),
    errorBubbleBorder: Color(0xFFB97878),
    errorText: Color(0xFF863A46),
    warningBubble: Color(0xFFF0E6D2),
    warningBubbleBorder: Color(0xFFB99A67),
    warningText: Color(0xFF6F4E23),
    permissionBubble: Color(0xFFF0E6D2),
    permissionBubbleBorder: Color(0xFFB99A67),
    permissionIcon: Color(0xFF785522),
    askBubble: Color(0xFFE6E7E8),
    askBubbleBorder: Color(0xFFA2ADB9),
    askIcon: Color(0xFF4A5C70),
    systemChip: Color(0xFFE5E1D8),
    successChip: Color(0xFFDDE5DA),
    errorChip: Color(0xFFEED9D8),
    approvalBar: Color(0xFFF0E6D2),
    approvalBarBorder: Color(0xFFB99A67),
    statusStarting: Color(0xFF575550),
    statusRunning: Color(0xFF4A5C70),
    statusApproval: Color(0xFF785522),
    statusCompacting: Color(0xFF64566F),
    statusIdle: Color(0xFF575550),
    statusOnline: Color(0xFF3C6551),
    statusPlan: Color(0xFF44634F),
    statusPlanGlow: Color(0xFF8DA98E),
    subtleText: Color(0xFF575550),
    codeBackground: Color(0xFFE5E1D8),
    codeBorder: Color(0xFFCDC9C0),
    toolResultBackground: Color(0xFFE5E1D8),
    toolResultText: Color(0xFF575550),
    toolResultTextExpanded: Color(0xFF3D3C39),
    diffAdditionBackground: Color(0xFFDCE5D9),
    diffAdditionText: Color(0xFF35553D),
    diffDeletionBackground: Color(0xFFEED9D8),
    diffDeletionText: Color(0xFF813942),
  );

  factory AppColors.dark() => const AppColors(
    userBubble: Color(0xFF374352),
    userBubbleText: Color(0xFFCED8E3),
    assistantBubble: Color(0xFF323235),
    toolBubble: Color(0xFF30363D),
    toolBubbleBorder: Color(0xFF48515C),
    toolIcon: Color(0xFFA0B0C3),
    errorBubble: Color(0xFF402B31),
    errorBubbleBorder: Color(0xFF6A484F),
    errorText: Color(0xFFDDA0A5),
    warningBubble: Color(0xFF393128),
    warningBubbleBorder: Color(0xFF725C41),
    warningText: Color(0xFFCFB283),
    permissionBubble: Color(0xFF392F27),
    permissionBubbleBorder: Color(0xFF725C41),
    permissionIcon: Color(0xFFCFB283),
    askBubble: Color(0xFF30363D),
    askBubbleBorder: Color(0xFF515F6D),
    askIcon: Color(0xFFA0B0C3),
    systemChip: Color(0xFF39383A),
    successChip: Color(0xFF303D32),
    errorChip: Color(0xFF402B31),
    approvalBar: Color(0xFF392F27),
    approvalBarBorder: Color(0xFF725C41),
    statusStarting: Color(0xFFAFAAAB),
    statusRunning: Color(0xFFA0B0C3),
    statusApproval: Color(0xFFCFB283),
    statusCompacting: Color(0xFFB7A5C3),
    statusIdle: Color(0xFFAFAAAB),
    statusOnline: Color(0xFF92B59E),
    statusPlan: Color(0xFF92B097),
    statusPlanGlow: Color(0xFFA5BDA9),
    subtleText: Color(0xFFAFAAAB),
    codeBackground: Color(0xFF2D2D30),
    codeBorder: Color(0xFF49474C),
    toolResultBackground: Color(0xFF2D2D30),
    toolResultText: Color(0xFFAFAAAB),
    toolResultTextExpanded: Color(0xFFCDC9C4),
    diffAdditionBackground: Color(0xFF313E35),
    diffAdditionText: Color(0xFFA6C1A6),
    diffDeletionBackground: Color(0xFF492E35),
    diffDeletionText: Color(0xFFDDA0A5),
  );

  @override
  AppColors copyWith({
    Color? userBubble,
    Color? userBubbleText,
    Color? assistantBubble,
    Color? toolBubble,
    Color? toolBubbleBorder,
    Color? toolIcon,
    Color? errorBubble,
    Color? errorBubbleBorder,
    Color? errorText,
    Color? warningBubble,
    Color? warningBubbleBorder,
    Color? warningText,
    Color? permissionBubble,
    Color? permissionBubbleBorder,
    Color? permissionIcon,
    Color? askBubble,
    Color? askBubbleBorder,
    Color? askIcon,
    Color? systemChip,
    Color? successChip,
    Color? errorChip,
    Color? approvalBar,
    Color? approvalBarBorder,
    Color? statusStarting,
    Color? statusRunning,
    Color? statusApproval,
    Color? statusCompacting,
    Color? statusIdle,
    Color? statusOnline,
    Color? statusPlan,
    Color? statusPlanGlow,
    Color? subtleText,
    Color? codeBackground,
    Color? codeBorder,
    Color? toolResultBackground,
    Color? toolResultText,
    Color? toolResultTextExpanded,
    Color? diffAdditionBackground,
    Color? diffAdditionText,
    Color? diffDeletionBackground,
    Color? diffDeletionText,
  }) {
    return AppColors(
      userBubble: userBubble ?? this.userBubble,
      userBubbleText: userBubbleText ?? this.userBubbleText,
      assistantBubble: assistantBubble ?? this.assistantBubble,
      toolBubble: toolBubble ?? this.toolBubble,
      toolBubbleBorder: toolBubbleBorder ?? this.toolBubbleBorder,
      toolIcon: toolIcon ?? this.toolIcon,
      errorBubble: errorBubble ?? this.errorBubble,
      errorBubbleBorder: errorBubbleBorder ?? this.errorBubbleBorder,
      errorText: errorText ?? this.errorText,
      warningBubble: warningBubble ?? this.warningBubble,
      warningBubbleBorder: warningBubbleBorder ?? this.warningBubbleBorder,
      warningText: warningText ?? this.warningText,
      permissionBubble: permissionBubble ?? this.permissionBubble,
      permissionBubbleBorder:
          permissionBubbleBorder ?? this.permissionBubbleBorder,
      permissionIcon: permissionIcon ?? this.permissionIcon,
      askBubble: askBubble ?? this.askBubble,
      askBubbleBorder: askBubbleBorder ?? this.askBubbleBorder,
      askIcon: askIcon ?? this.askIcon,
      systemChip: systemChip ?? this.systemChip,
      successChip: successChip ?? this.successChip,
      errorChip: errorChip ?? this.errorChip,
      approvalBar: approvalBar ?? this.approvalBar,
      approvalBarBorder: approvalBarBorder ?? this.approvalBarBorder,
      statusStarting: statusStarting ?? this.statusStarting,
      statusRunning: statusRunning ?? this.statusRunning,
      statusApproval: statusApproval ?? this.statusApproval,
      statusCompacting: statusCompacting ?? this.statusCompacting,
      statusIdle: statusIdle ?? this.statusIdle,
      statusOnline: statusOnline ?? this.statusOnline,
      statusPlan: statusPlan ?? this.statusPlan,
      statusPlanGlow: statusPlanGlow ?? this.statusPlanGlow,
      subtleText: subtleText ?? this.subtleText,
      codeBackground: codeBackground ?? this.codeBackground,
      codeBorder: codeBorder ?? this.codeBorder,
      toolResultBackground: toolResultBackground ?? this.toolResultBackground,
      toolResultText: toolResultText ?? this.toolResultText,
      toolResultTextExpanded:
          toolResultTextExpanded ?? this.toolResultTextExpanded,
      diffAdditionBackground:
          diffAdditionBackground ?? this.diffAdditionBackground,
      diffAdditionText: diffAdditionText ?? this.diffAdditionText,
      diffDeletionBackground:
          diffDeletionBackground ?? this.diffDeletionBackground,
      diffDeletionText: diffDeletionText ?? this.diffDeletionText,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      userBubble: Color.lerp(userBubble, other.userBubble, t)!,
      userBubbleText: Color.lerp(userBubbleText, other.userBubbleText, t)!,
      assistantBubble: Color.lerp(assistantBubble, other.assistantBubble, t)!,
      toolBubble: Color.lerp(toolBubble, other.toolBubble, t)!,
      toolBubbleBorder: Color.lerp(
        toolBubbleBorder,
        other.toolBubbleBorder,
        t,
      )!,
      toolIcon: Color.lerp(toolIcon, other.toolIcon, t)!,
      errorBubble: Color.lerp(errorBubble, other.errorBubble, t)!,
      errorBubbleBorder: Color.lerp(
        errorBubbleBorder,
        other.errorBubbleBorder,
        t,
      )!,
      errorText: Color.lerp(errorText, other.errorText, t)!,
      warningBubble: Color.lerp(warningBubble, other.warningBubble, t)!,
      warningBubbleBorder: Color.lerp(
        warningBubbleBorder,
        other.warningBubbleBorder,
        t,
      )!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      permissionBubble: Color.lerp(
        permissionBubble,
        other.permissionBubble,
        t,
      )!,
      permissionBubbleBorder: Color.lerp(
        permissionBubbleBorder,
        other.permissionBubbleBorder,
        t,
      )!,
      permissionIcon: Color.lerp(permissionIcon, other.permissionIcon, t)!,
      askBubble: Color.lerp(askBubble, other.askBubble, t)!,
      askBubbleBorder: Color.lerp(askBubbleBorder, other.askBubbleBorder, t)!,
      askIcon: Color.lerp(askIcon, other.askIcon, t)!,
      systemChip: Color.lerp(systemChip, other.systemChip, t)!,
      successChip: Color.lerp(successChip, other.successChip, t)!,
      errorChip: Color.lerp(errorChip, other.errorChip, t)!,
      approvalBar: Color.lerp(approvalBar, other.approvalBar, t)!,
      approvalBarBorder: Color.lerp(
        approvalBarBorder,
        other.approvalBarBorder,
        t,
      )!,
      statusStarting: Color.lerp(statusStarting, other.statusStarting, t)!,
      statusRunning: Color.lerp(statusRunning, other.statusRunning, t)!,
      statusApproval: Color.lerp(statusApproval, other.statusApproval, t)!,
      statusCompacting: Color.lerp(
        statusCompacting,
        other.statusCompacting,
        t,
      )!,
      statusIdle: Color.lerp(statusIdle, other.statusIdle, t)!,
      statusOnline: Color.lerp(statusOnline, other.statusOnline, t)!,
      statusPlan: Color.lerp(statusPlan, other.statusPlan, t)!,
      statusPlanGlow: Color.lerp(statusPlanGlow, other.statusPlanGlow, t)!,
      subtleText: Color.lerp(subtleText, other.subtleText, t)!,
      codeBackground: Color.lerp(codeBackground, other.codeBackground, t)!,
      codeBorder: Color.lerp(codeBorder, other.codeBorder, t)!,
      toolResultBackground: Color.lerp(
        toolResultBackground,
        other.toolResultBackground,
        t,
      )!,
      toolResultText: Color.lerp(toolResultText, other.toolResultText, t)!,
      toolResultTextExpanded: Color.lerp(
        toolResultTextExpanded,
        other.toolResultTextExpanded,
        t,
      )!,
      diffAdditionBackground: Color.lerp(
        diffAdditionBackground,
        other.diffAdditionBackground,
        t,
      )!,
      diffAdditionText: Color.lerp(
        diffAdditionText,
        other.diffAdditionText,
        t,
      )!,
      diffDeletionBackground: Color.lerp(
        diffDeletionBackground,
        other.diffDeletionBackground,
        t,
      )!,
      diffDeletionText: Color.lerp(
        diffDeletionText,
        other.diffDeletionText,
        t,
      )!,
    );
  }
}
