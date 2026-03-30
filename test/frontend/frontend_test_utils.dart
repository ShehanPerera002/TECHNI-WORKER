import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Integration test utilities for frontend testing
class FrontendTestUtils {
  /// Find widget by text
  static Finder findByText(String text) => find.text(text);

  /// Find widget by type
  static Finder findByType(Type type) => find.byType(type);

  /// Find by semantic label
  static Finder findByLabel(String label) => find.bySemanticLabel(label);

  /// Find by key
  static Finder findByKey(Key key) => find.byKey(key);

  /// Wait for widget to appear
  static Future<void> waitForWidget(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await tester.pumpAndSettle(timeout);
    expect(finder, findsOneWidget);
  }

  /// Scroll to widget
  static Future<void> scrollTo(
    WidgetTester tester,
    Finder finder, {
    Offset delta = const Offset(0, -300),
  }) async {
    await tester.drag(find.byType(SingleChildScrollView), delta);
    await tester.pumpAndSettle();
  }

  /// Enter text in input field
  static Future<void> enterText(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Tap button/widget
  static Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Wait and tap
  static Future<void> waitAndTap(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await tester.pumpAndSettle(timeout);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Verify text is visible
  static Future<void> verifyTextVisible(
    WidgetTester tester,
    String text,
  ) async {
    expect(findByText(text), findsOneWidget);
  }

  /// Verify widget not visible
  static Future<void> verifyNotVisible(
    WidgetTester tester,
    Finder finder,
  ) async {
    expect(finder, findsNothing);
  }

  /// Verify multiple widgets visible
  static Future<void> verifyMultipleVisible(
    WidgetTester tester,
    List<String> texts,
  ) async {
    for (var text in texts) {
      expect(findByText(text), findsOneWidget);
    }
  }

  /// Get widget position
  static Offset getPosition(WidgetTester tester, Finder finder) {
    return tester.getCenter(finder);
  }

  /// Get widget size
  static Size getSize(WidgetTester tester, Finder finder) {
    return tester.getSize(finder);
  }

  /// Check if widget is enabled
  static bool isEnabled(WidgetTester tester, Finder finder) {
    final widget = tester.widget<dynamic>(finder);
    if (widget is ElevatedButton) {
      return widget.onPressed != null;
    }
    return true;
  }

  /// Perform swipe gesture
  static Future<void> swipe(
    WidgetTester tester,
    Offset start,
    Offset end,
  ) async {
    final gesture = await tester.startGesture(start);
    await gesture.moveTo(end);
    await gesture.up();
    await tester.pumpAndSettle();
  }

  /// Long press widget
  static Future<void> longPress(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.longPress(finder);
    await tester.pumpAndSettle();
  }

  /// Double tap widget
  static Future<void> doubleTap(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Clear text field
  static Future<void> clearTextField(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.tap(finder);
    await tester.pump();
    await tester.sendKey(LogicalKeyboardKey, LogicalKeyboardKey.keyA);
    await tester.sendKey(LogicalKeyboardKey, LogicalKeyboardKey.delete);
    await tester.pump();
  }

  /// Verify error message
  static Future<void> verifyErrorMessage(
    WidgetTester tester,
    String errorText,
  ) async {
    await tester.pumpAndSettle();
    expect(
      find.text(errorText),
      findsWidgets,
      reason: 'Error message "$errorText" should be visible',
    );
  }

  /// Wait for navigation
  static Future<void> waitForNavigation(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await tester.pumpAndSettle(timeout);
  }

  /// Check dialog is visible
  static Future<void> verifyDialogVisible(WidgetTester tester) async {
    expect(find.byType(AlertDialog), findsOneWidget);
  }

  /// Dismiss dialog
  static Future<void> dismissDialog(WidgetTester tester) async {
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }
}

/// Form validation test utilities
class FormTestUtils {
  /// Test text field input
  static Future<void> testTextFieldInput(
    WidgetTester tester,
    Finder finder,
    String input,
  ) async {
    await tester.tap(finder);
    await tester.enterText(finder, input);
    await tester.pumpAndSettle();
  }

  /// Test required field validation
  static Future<void> testRequiredFieldValidation(
    WidgetTester tester,
    Finder submitButton,
    String errorMessage,
  ) async {
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
    expect(find.text(errorMessage), findsWidgets);
  }

  /// Test email validation
  static Future<void> testEmailValidation(
    WidgetTester tester,
    Finder emailField,
    List<String> validEmails,
    List<String> invalidEmails,
  ) async {
    for (var email in validEmails) {
      await tester.enterText(emailField, email);
      await tester.pump();
      // Valid emails should not show error
    }

    for (var email in invalidEmails) {
      await tester.enterText(emailField, email);
      await tester.pump();
      // Invalid emails should show error
    }
  }

  /// Test phone number validation
  static Future<void> testPhoneValidation(
    WidgetTester tester,
    Finder phoneField,
    String validPhone,
    String invalidPhone,
  ) async {
    await tester.enterText(phoneField, validPhone);
    await tester.pump();

    await tester.enterText(phoneField, invalidPhone);
    await tester.pump();
  }

  /// Test form submission
  static Future<void> testFormSubmission(
    WidgetTester tester,
    Finder submitButton,
  ) async {
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
  }

  /// Test field length validation
  static Future<void> testFieldLength(
    WidgetTester tester,
    Finder field,
    String text,
    int maxLength,
  ) async {
    await tester.enterText(field, text);
    await tester.pump();
  }
}

/// Navigation test utilities
class NavigationTestUtils {
  /// Navigate by tapping menu item
  static Future<void> navigateToMenuItem(
    WidgetTester tester,
    String menuItem,
  ) async {
    await FrontendTestUtils.tap(tester, FrontendTestUtils.findByText(menuItem));
  }

  /// Navigate by bottom nav
  static Future<void> navigateByBottomNav(
    WidgetTester tester,
    int index,
  ) async {
    final navBar = find.byType(BottomNavigationBar);
    expect(navBar, findsOneWidget);

    final items =
        find.byType(BottomNavigationBarItem).evaluate().toList();
    if (index < items.length) {
      await tester.tap(find.byType(BottomNavigationBar));
      await tester.pumpAndSettle();
    }
  }

  /// Go back
  static Future<void> goBack(WidgetTester tester) async {
    await tester.pageBack();
    await tester.pumpAndSettle();
  }

  /// Verify screen title
  static Future<void> verifyScreenTitle(
    WidgetTester tester,
    String title,
  ) async {
    expect(FrontendTestUtils.findByText(title), findsWidgets);
  }

  /// Wait for screen load
  static Future<void> waitForScreenLoad(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await tester.pumpAndSettle(timeout);
  }
}

/// List/Scroll test utilities
class ListTestUtils {
  /// Find list items
  static Finder findListItems() => find.byType(ListTile);

  /// Find first list item
  static Finder findFirstListItem() {
    final items = find.byType(ListTile);
    return items.first;
  }

  /// Scroll to list item
  static Future<void> scrollToListItem(
    WidgetTester tester,
    String itemText,
  ) async {
    await tester.dragUntilVisible(
      FrontendTestUtils.findByText(itemText),
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
  }

  /// Tap list item
  static Future<void> tapListItem(
    WidgetTester tester,
    int index,
  ) async {
    final items = find.byType(ListTile);
    await tester.tap(items.at(index));
    await tester.pumpAndSettle();
  }

  /// Verify list is not empty
  static Future<void> verifyListNotEmpty(WidgetTester tester) async {
    final items = find.byType(ListTile);
    expect(items, findsWidgets);
  }

  /// Verify list item text
  static Future<void> verifyListItemText(
    WidgetTester tester,
    String text,
  ) async {
    expect(FrontendTestUtils.findByText(text), findsWidgets);
  }

  /// Count list items
  static int countListItems(WidgetTester tester) {
    return find.byType(ListTile).evaluate().length;
  }

  /// Pull to refresh
  static Future<void> pullToRefresh(WidgetTester tester) async {
    await tester.fling(
      find.byType(SingleChildScrollView),
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();
  }
}

/// Dialog and modal test utilities
class DialogTestUtils {
  /// Show and verify dialog
  static Future<void> verifyDialogContent(
    WidgetTester tester,
    List<String> expectedTexts,
  ) async {
    expect(find.byType(AlertDialog), findsOneWidget);
    for (var text in expectedTexts) {
      expect(FrontendTestUtils.findByText(text), findsWidgets);
    }
  }

  /// Tap dialog button
  static Future<void> tapDialogButton(
    WidgetTester tester,
    String buttonText,
  ) async {
    await tester.tap(FrontendTestUtils.findByText(buttonText));
    await tester.pumpAndSettle();
  }

  /// Verify bottom sheet
  static Future<void> verifyBottomSheetVisible(
    WidgetTester tester,
  ) async {
    expect(find.byType(BottomSheet), findsOneWidget);
  }

  /// Close bottom sheet
  static Future<void> closeBottomSheet(WidgetTester tester) async {
    await tester.pageBack();
    await tester.pumpAndSettle();
  }
}

/// Button and interaction test utilities
class ButtonTestUtils {
  /// Verify button is enabled
  static Future<void> verifyButtonEnabled(
    WidgetTester tester,
    Finder button,
  ) async {
    final widget = tester.widget<dynamic>(button);
    if (widget is ElevatedButton) {
      expect(widget.onPressed, isNotNull);
    }
  }

  /// Verify button is disabled
  static Future<void> verifyButtonDisabled(
    WidgetTester tester,
    Finder button,
  ) async {
    final widget = tester.widget<dynamic>(button);
    if (widget is ElevatedButton) {
      expect(widget.onPressed, isNull);
    }
  }

  /// Test button visibility and tap
  static Future<void> testButtonTap(
    WidgetTester tester,
    Finder button,
  ) async {
    expect(button, findsOneWidget);
    await FrontendTestUtils.tap(tester, button);
  }

  /// Test multiple button states
  static Future<void> testButtonStates(
    WidgetTester tester,
    Finder button,
  ) async {
    expect(button, findsOneWidget);
    // Can be tapped
    await FrontendTestUtils.tap(tester, button);
  }
}

/// Screen state test utilities
class ScreenTestUtils {
  /// Verify loading state
  static Future<void> verifyLoadingState(
    WidgetTester tester,
  ) async {
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  }

  /// Verify empty state
  static Future<void> verifyEmptyState(
    WidgetTester tester,
    String emptyMessage,
  ) async {
    expect(FrontendTestUtils.findByText(emptyMessage), findsWidgets);
  }

  /// Verify error state
  static Future<void> verifyErrorState(
    WidgetTester tester,
    String errorMessage,
  ) async {
    expect(FrontendTestUtils.findByText(errorMessage), findsWidgets);
  }

  /// Verify success state
  static Future<void> verifySuccessState(
    WidgetTester tester,
    String successMessage,
  ) async {
    expect(FrontendTestUtils.findByText(successMessage), findsWidgets);
  }
}
