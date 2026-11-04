import 'package:flutter/material.dart';

import '../tokens/palette.dart';
import 'initials.dart';

/// A person's picture, or their initials on a tinted disc when there is none or it cannot load.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.email,
    this.imageUrl,
    this.size = 40,
    this.semanticLabel,
  });

  final String name;
  final String? email;
  final String? imageUrl;
  final double size;

  /// Spoken name, for example "Picture of Ada Lovelace". Leave null to hide it from screen readers
  /// when the name is written beside it.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final letters = Center(
      child: Text(
        initialsOf(name, email),
        style: TextStyle(color: p.fg, fontWeight: FontWeight.w700, fontSize: size * 0.36),
      ),
    );
    final url = imageUrl;
    final avatar = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: ColoredBox(
          color: p.surface2,
          child: url == null || url.isEmpty
              ? letters
              : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => letters),
        ),
      ),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: avatar)
        : Semantics(label: semanticLabel, image: true, child: ExcludeSemantics(child: avatar));
  }
}
