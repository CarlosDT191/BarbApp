import 'package:flutter/material.dart';

class ServiceTypeOption {
  final String label;
  final IconData icon;

  const ServiceTypeOption({required this.label, required this.icon});
}

const List<ServiceTypeOption> kServiceTypeOptions = [
  ServiceTypeOption(label: 'Corte común', icon: Icons.content_cut),
  ServiceTypeOption(label: 'Corte + lavado', icon: Icons.water_drop_rounded),
  ServiceTypeOption(label: 'Corte infantil', icon: Icons.child_care),
  ServiceTypeOption(label: 'Corte tercera edad', icon: Icons.elderly),
  ServiceTypeOption(label: 'Solo maquinilla', icon: Icons.electric_rickshaw),
  ServiceTypeOption(label: 'Barba', icon: Icons.face),
  ServiceTypeOption(label: 'Corte + barba', icon: Icons.people_rounded),
  ServiceTypeOption(label: 'Corte con navaja', icon: Icons.architecture),
  ServiceTypeOption(label: 'Tintado de pelo', icon: Icons.color_lens),
  ServiceTypeOption(label: 'Otro', icon: Icons.add_circle_outline),
];
