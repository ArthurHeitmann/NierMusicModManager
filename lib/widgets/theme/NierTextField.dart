
import 'package:flutter/material.dart';

import '../misc/onHoverBuilder.dart';
import 'customTheme.dart';

class NierTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final double? width;
  final String Function(String)? onChanged;

  const NierTextField({ super.key, this.controller, this.hintText, this.width, this.onChanged });

  @override
  State<NierTextField> createState() => _NierTextFieldState();
}

class _NierTextFieldState extends State<NierTextField> {
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return OnHoverBuilder(
      builder: (context, isHovered) {
        return ConstrainedBox(
          constraints: BoxConstraints.tight(Size(widget.width ?? 300, 48)),
          child: Stack(
            children: [
              Positioned.fill(
                child: Transform.translate(
                  offset: const Offset(4, 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    color: focusNode.hasFocus || isHovered
                      ? NierTheme.brownDark
                      : Colors.transparent,
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  color: NierTheme.grey,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12, top: 1),
                    child: TextField(
                      focusNode: focusNode,
                      controller: widget.controller,
                      onChanged: widget.onChanged,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: widget.hintText,
                      ),
                      style: const TextStyle(
                        color: NierTheme.dark,
                        fontSize: 24,
                      )
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}
