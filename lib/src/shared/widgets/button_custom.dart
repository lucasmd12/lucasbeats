import 'package:flutter/material.dart';

// Componente de botão personalizado com estilo "gangue das ruas"
class ButtonCustom extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final Widget? icon;
  final ButtonStyle? style;
  final bool disabled;

  const ButtonCustom({
    Key? key,
    required this.title,
    required this.onPressed,
    this.icon,
    this.style,
    this.disabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Estilo base com tema "gangue das ruas"
    final ButtonStyle baseStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1E1E1E),
      foregroundColor: Colors.white, // Cor do texto e ícone
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: disabled ? const Color(0xFF666666) : const Color(0xFFFF1A1A)),
      ),
      shadowColor: disabled ? Colors.transparent : const Color(0xFFFF0000),
      elevation: disabled ? 0 : 4,
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            offset: Offset(1.0, 1.0),
            blurRadius: 2.0,
            color: Color(0xFFFF0000),
          ),
        ],
      ),
    ).copyWith(
      // Aplica opacidade quando desabilitado
      overlayColor: MaterialStateProperty.resolveWith<Color?>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.disabled)) {
            return const Color(0xFF333333).withOpacity(0.7);
          }
          if (states.contains(MaterialState.pressed)) {
            return const Color(0xFFFF1A1A).withOpacity(0.3);
          }
          return null; // Defer to the widget's default.
        },
      ),
      backgroundColor: MaterialStateProperty.resolveWith<Color?>(
         (Set<MaterialState> states) {
            if (states.contains(MaterialState.disabled)) {
              return const Color(0xFF333333).withOpacity(0.7);
            }
            return const Color(0xFF1E1E1E); // Cor normal
         }
      )
    );

    // Merge com estilo customizado, se houver
    final ButtonStyle effectiveStyle = style != null ? baseStyle.merge(style) : baseStyle;

    return ElevatedButton(
      style: effectiveStyle,
      onPressed: disabled ? null : onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 8),
          ],
          Text(title),
        ],
      ),
    );
  }
}

