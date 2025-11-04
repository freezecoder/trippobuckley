import 'package:flutter/material.dart';

class Components {
  TextField returnTextField(TextEditingController controller,
      BuildContext context, bool obsecured, String hintText) {
    return TextField(
      controller: controller,
      cursorColor: Colors.red,
      keyboardType: TextInputType.emailAddress,
      obscureText: obsecured,
      style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 14),
      decoration: InputDecoration(
          hintText: hintText,
          hintStyle: Theme.of(context)
              .textTheme
              .bodySmall!
              .copyWith(fontSize: 14, color: Colors.white),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1))),
    );
  }

  /// Password field with show/hide toggle
  Widget returnPasswordField({
    required TextEditingController controller,
    required BuildContext context,
    required String hintText,
    required bool isPasswordVisible,
    required VoidCallback onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      cursorColor: Colors.red,
      obscureText: !isPasswordVisible,
      style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: Theme.of(context)
            .textTheme
            .bodySmall!
            .copyWith(fontSize: 14, color: Colors.white),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.white70,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }

  Container mainButton(
      Size size, String title, BuildContext context, Color color) {
    return Container(
      alignment: Alignment.center,
      width: size.width * 0.8,
      height: 40,
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
