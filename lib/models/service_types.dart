import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ServiceTypeOption {
  final String label;
  final IconData? icon;
  final String? svgAsset;
  final double scale;

  const ServiceTypeOption({
    required this.label,
    this.icon,
    this.svgAsset,
    this.scale = 1.0,
  }) : assert(
         icon != null || svgAsset != null,
         'ServiceTypeOption needs an icon or svgAsset.',
       );

  Widget buildIcon(
    BuildContext context, {
    double? size,
    Color? color,
  }) {
    final resolvedColor =
        color ?? IconTheme.of(context).color ?? Colors.black;
    final baseSize = size ?? 18;
    final resolvedSize = baseSize * scale;

    if (svgAsset != null) {
      return SvgPicture.asset(
        svgAsset!,
        width: resolvedSize,
        height: resolvedSize,
        colorFilter: ColorFilter.mode(resolvedColor, BlendMode.srcIn),
      );
    }

    return Icon(icon, size: resolvedSize, color: resolvedColor);
  }
}

ServiceTypeOption findServiceTypeOption(String label) {
  for (final option in kServiceTypeOptions) {
    if (option.label == label) {
      return option;
    }
  }
  return kServiceTypeOptions.first;
}

const List<ServiceTypeOption> kServiceTypeOptions = [
  ServiceTypeOption(label: 'Corte común', icon: Icons.content_cut),
  ServiceTypeOption(label: 'Corte + lavado', icon: Icons.water_drop_rounded),
  ServiceTypeOption(label: 'Corte infantil', icon: Icons.child_care),
  ServiceTypeOption(label: 'Corte tercera edad', icon: Icons.elderly),
  ServiceTypeOption(
    label: 'Solo maquinilla',
    svgAsset: 'assets/maquinilla.svg',
    scale: 1.2,
  ),
  ServiceTypeOption(
    label: 'Barba',
    svgAsset: 'assets/beard.svg',
  ),
  ServiceTypeOption(label: 'Corte + barba', icon: Icons.face),
  ServiceTypeOption(
    label: 'Corte con navaja',
    svgAsset: 'assets/navaja.svg',
    scale: 0.85,
  ),
  ServiceTypeOption(label: 'Tintado de pelo', icon: Icons.color_lens),
  ServiceTypeOption(label: 'Otro', icon: Icons.add_circle_outline),
];
