import 'package:flutter/material.dart';

class CreateEventModal extends StatefulWidget {
  final DateTime selectedDate;
  final int? suggestedHour;
  final Function(DateTime date, String time, String localName) onEventCreated;

  const CreateEventModal({
    super.key,
    required this.selectedDate,
    this.suggestedHour,
    required this.onEventCreated,
  });

  @override
  State<CreateEventModal> createState() => _CreateEventModalState();
}

class _CreateEventModalState extends State<CreateEventModal> {
  late TextEditingController _localNameController;
  late int _selectedHour;
  late int _selectedMinute;
  int _durationMinutes = 60;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _localNameController = TextEditingController();
    _selectedHour = widget.suggestedHour ?? DateTime.now().hour;
    _selectedMinute = 0;
  }

  @override
  void dispose() {
    _localNameController.dispose();
    super.dispose();
  }

  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  void _createEvent() {
    if (_localNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa el nombre del local'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final time = _formatTime(_selectedHour, _selectedMinute);
    widget.onEventCreated(widget.selectedDate, time, _localNameController.text);
    Navigator.pop(context);
  }

  void _showHourPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 35, 35, 35),
        title: const Text(
          'Selecciona la hora',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hora
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 200,
                    child: ListWheelScrollView(
                      itemExtent: 40,
                      onSelectedItemChanged: (index) {
                        setState(() => _selectedHour = index);
                      },
                      children: List.generate(24, (i) {
                        return Center(
                          child: Text(
                            i.toString().padLeft(2, '0'),
                            style: TextStyle(
                              color: _selectedHour == i
                                  ? const Color.fromARGB(255, 200, 156, 125)
                                  : Colors.grey,
                              fontSize: 20,
                              fontWeight: _selectedHour == i
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const Text(
                  ':',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                Expanded(
                  child: SizedBox(
                    height: 200,
                    child: ListWheelScrollView(
                      itemExtent: 40,
                      onSelectedItemChanged: (index) {
                        setState(() => _selectedMinute = index * 5);
                      },
                      children: List.generate(12, (i) {
                        final minute = i * 5;
                        return Center(
                          child: Text(
                            minute.toString().padLeft(2, '0'),
                            style: TextStyle(
                              color: _selectedMinute == minute
                                  ? const Color.fromARGB(255, 200, 156, 125)
                                  : Colors.grey,
                              fontSize: 20,
                              fontWeight: _selectedMinute == minute
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 70,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            const Text(
              'Nueva Reserva',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Fecha
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 35, 35, 35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Color.fromARGB(255, 200, 156, 125),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Hora
            GestureDetector(
              onTap: _showHourPicker,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 35, 35, 35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      color: Color.fromARGB(255, 200, 156, 125),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _formatTime(_selectedHour, _selectedMinute),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.edit,
                      color: Colors.grey,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Duración
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Duración (minutos)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _durationMinutes.toDouble(),
                        min: 15,
                        max: 180,
                        divisions: 11,
                        activeColor:
                            const Color.fromARGB(255, 200, 156, 125),
                        inactiveColor: Colors.grey[700],
                        label: '$_durationMinutes min',
                        onChanged: (value) {
                          setState(() => _durationMinutes = value.toInt());
                        },
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(
                        '$_durationMinutes m',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Nombre del local
            TextField(
              controller: _localNameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nombre del local',
                labelStyle: const TextStyle(color: Colors.grey),
                hintText: 'Ej: Sala de Juntas A',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color.fromARGB(255, 200, 156, 125),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botones
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createEvent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color.fromARGB(255, 200, 156, 125),
                      disabledBackgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Crear',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
