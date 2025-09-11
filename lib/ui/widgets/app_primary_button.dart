import 'package:flutter/material.dart';
import '../style/app_style.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.loading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.style,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool loading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final appStyle = AppStyle.of(context);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style:
            style ??
            ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(appStyle.radius),
              ),
              elevation: appStyle.elevation,
            ),
        child:
            loading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : child,
      ),
    );
  }
}
