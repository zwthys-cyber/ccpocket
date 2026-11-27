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
      surface: Color(0xFFFBFAF7),
      onSurface: Color(0xFF232925),
      onSurfaceVariant: Color(0xFF525C55),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFF7F6F2),
      surfaceContainer: Color(0xFFF2F1EC),
      surfaceContainerHigh: Color(0xFFFFFFFF),
      surfaceContainerHighest: Color(0xFFE9EBE5),
      primary: Color(0xFF246451),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFE6F1EB),
      onPrimaryContainer: Color(0xFF194B3B),
      secondary: Color(0xFF415F6D),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFE8EFF1),
      onSecondaryContainer: Color(0xFF263F4A),
      tertiary: Color(0xFF815114),
      tertiaryContainer: Color(0xFFFAECD2),
      onTertiaryContainer: Color(0xFF59360B),
      error: Color(0xFFB42335),
      onError: Color(0xFFFFFFFF),
      outline: Color(0xFF667269),
      outlineVariant: Color(0xFFDBDFD7),
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
      surface: Color(0xFF171C1A),
      onSurface: Color(0xFFF0F2EE),
      onSurfaceVariant: Color(0xFFB9C3BB),
      surfaceContainerLowest: Color(0xFF121614),
      surfaceContainerLow: Color(0xFF1E2521),
      surfaceContainer: Color(0xFF222A25),
      surfaceContainerHigh: Color(0xFF252D28),
      surfaceContainerHighest: Color(0xFF333D36),
      primary: Color(0xFFA6D6C2),
      onPrimary: Color(0xFF163D30),
      primaryContainer: Color(0xFF294438),
      onPrimaryContainer: Color(0xFFD7EEE3),
      secondary: Color(0xFFA8C6D1),
      onSecondary: Color(0xFF193640),
      secondaryContainer: Color(0xFF263B44),
      onSecondaryContainer: Color(0xFFCFE8EF),
      tertiary: Color(0xFFF1BD70),
      tertiaryContainer: Color(0xFF48341B),
      onTertiaryContainer: Color(0xFFF8DCB5),
      error: Color(0xFFFF9DA8),
      onError: Color(0xFF490D1B),
      outline: Color(0xFF909E93),
      outlineVariant: Color(0xFF3A453D),
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
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        color: colorScheme.surfaceContainerHigh,
        clipBehavior: Clip.antiAlias,
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        highlightElevation: 4,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // FilledButton
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
        labelStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: textTheme.labelMedium,
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // SegmentedButton
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
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
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surfaceContainerHigh,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),

      // BottomSheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: brightness == Brightness.dark
            ? colorScheme.surfaceContainerLowest
            : null,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        letterSpacing: 0.25,
        color: colorScheme.onSurface,
      ),
      bodyMedium: GoogleFonts.ibmPlexSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
      ),
      bodySmall: GoogleFonts.ibmPlexSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
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
    userBubble: Color(0xFFE6F1EB),
    userBubbleText: Color(0xFF194B3B),
    assistantBubble: Color(0xFFF2F1EC),
    toolBubble: Color(0xFFF1F4F4),
    toolBubbleBorder: Color(0xFFDBE2E3),
    toolIcon: Color(0xFF415F6D),
    errorBubble: Color(0xFFFEF2F2), // Red 50
    errorBubbleBorder: Color(0xFFEF4444), // Red 500
    errorText: Color(0xFFB91C1C), // Red 700
    warningBubble: Color(0xFFFFFBEB), // Amber 50
    warningBubbleBorder: Color(0xFFFBBF24), // Amber 400
    warningText: Color(0xFF92400E), // Amber 800
    permissionBubble: Color(0xFFFFF7E8),
    permissionBubbleBorder: Color(0xFFC48531),
    permissionIcon: Color(0xFF815114),
    askBubble: Color(0xFFFFF7E8),
    askBubbleBorder: Color(0xFFC48531),
    askIcon: Color(0xFF815114),
    systemChip: Color(0xFFE8EFF1),
    successChip: Color(0xFFE7F6EF),
    errorChip: Color(0xFFFEE2E2), // Red 100
    approvalBar: Color(0xFFFFF7E8),
    approvalBarBorder: Color(0xFFC48531),
    statusStarting: Color(0xFF525C55),
    statusRunning: Color(0xFF246451),
    statusApproval: Color(0xFF815114),
    statusCompacting: Color(0xFF7C3AED), // Violet 600
    statusIdle: Color(0xFF525C55),
    statusOnline: Color(0xFF18734E),
    statusPlan: Color(0xFF1F8F4E), // structured plan green
    statusPlanGlow: Color(0xFF7BD89A), // lighter green for glow
    subtleText: Color(0xFF525C55),
    codeBackground: Color(0xFFF2F1EC),
    codeBorder: Color(0xFFDBDFD7),
    toolResultBackground: Color(0xFFF2F1EC),
    toolResultText: Color(0xFF525C55),
    toolResultTextExpanded: Color(0xFF333F36),
    diffAdditionBackground: Color(0xFFDCFCE7), // Green 100
    diffAdditionText: Color(0xFF166534), // Green 800
    diffDeletionBackground: Color(0xFFFEE2E2), // Red 100
    diffDeletionText: Color(0xFF991B1B), // Red 800
  );

  factory AppColors.dark() => const AppColors(
    userBubble: Color(0xFF294438),
    userBubbleText: Color(0xFFD7EEE3),
    assistantBubble: Color(0xFF252D28),
    toolBubble: Color(0xFF202D31),
    toolBubbleBorder: Color(0xFF384A51),
    toolIcon: Color(0xFFA8C6D1),
    errorBubble: Color(0xFF2A1215),
    errorBubbleBorder: Color(0xFF5C2020),
    errorText: Color(0xFFFCA5A5), // Red 300
    warningBubble: Color(0xFF2A2008),
    warningBubbleBorder: Color(0xFF78350F),
    warningText: Color(0xFFFCD34D), // Amber 300
    permissionBubble: Color(0xFF2B2117),
    permissionBubbleBorder: Color(0xFF75502A),
    permissionIcon: Color(0xFFF1BD70),
    askBubble: Color(0xFF2B2117),
    askBubbleBorder: Color(0xFF75502A),
    askIcon: Color(0xFFF1BD70),
    systemChip: Color(0xFF263B44),
    successChip: Color(0xFF14362B),
    errorChip: Color(0xFF2A1215),
    approvalBar: Color(0xFF2B2117),
    approvalBarBorder: Color(0xFF75502A),
    statusStarting: Color(0xFFB9C3BB),
    statusRunning: Color(0xFFA6D6C2),
    statusApproval: Color(0xFFF1BD70),
    statusCompacting: Color(0xFFA78BFA), // Violet 400
    statusIdle: Color(0xFFB9C3BB),
    statusOnline: Color(0xFF81DFB5),
    statusPlan: Color(0xFF57C779), // natural plan green
    statusPlanGlow: Color(0xFF9AE6B4), // lifted green glow
    subtleText: Color(0xFFB9C3BB),
    codeBackground: Color(0xFF222A25),
    codeBorder: Color(0xFF3A453D),
    toolResultBackground: Color(0xFF222A25),
    toolResultText: Color(0xFFB9C3BB),
    toolResultTextExpanded: Color(0xFFD8DED8),
    diffAdditionBackground: Color(0xFF14532D), // Green 900
    diffAdditionText: Color(0xFF86EFAC), // Green 300
    diffDeletionBackground: Color(0xFF7F1D1D), // Red 900
    diffDeletionText: Color(0xFFFCA5A5), // Red 300
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
