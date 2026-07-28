import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';

class SubscriptionDialog extends StatefulWidget {
  final bool isBlocking;
  final String userEmail;
  final String userName;

  const SubscriptionDialog({
    super.key, 
    this.isBlocking = false,
    required this.userEmail,
    required this.userName,
  });

  @override
  State<SubscriptionDialog> createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends State<SubscriptionDialog> {
  final TextEditingController _codeController = TextEditingController();

  void _activarPorWhatsApp(PlanType plan) {
    SubscriptionService.openWhatsApp(widget.userName, widget.userEmail, plan);
  }

  void _verificarCodigo() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code == 'ACTIVALOCAL') {
      await SubscriptionService.setPlan(PlanType.local);
      if (mounted) Navigator.pop(context, true);
    } else if (code == 'ACTIVANUBE') {
      await SubscriptionService.setPlan(PlanType.nube);
      if (mounted) Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código inválido. Contacte a soporte.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isBlocking,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_clock, size: 60, color: AppTheme.primary),
                const SizedBox(height: 16),
                Text(
                  widget.isBlocking ? 'Período de Prueba Expirado' : 'Planes Vende Móvil',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.isBlocking 
                    ? 'Tu período de prueba de 14 días ha finalizado. Por favor, adquiere un plan para seguir utilizando la aplicación y no perder tus datos.'
                    : 'Selecciona un plan para activar tu cuenta. Todos los planes incluyen actualizaciones gratuitas.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),
                
                // Plan Local
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text('PLAN LOCAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('S/ 49.00 Anual (USD 14)', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                      const Text('Datos guardados solo en tu teléfono.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.chat),
                        label: const Text('Adquirir por WhatsApp'),
                        onPressed: () => _activarPorWhatsApp(PlanType.local),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Plan Nube
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.05),
                    border: Border.all(color: AppTheme.primary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text('PLAN NUBE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
                      const Text('S/ 15.00 Mensual (USD 5)', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                      const Text('Sincronización en la nube, acceso multi-dispositivo y copias de seguridad automáticas.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.chat),
                        label: const Text('Adquirir por WhatsApp'),
                        onPressed: () => _activarPorWhatsApp(PlanType.nube),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                const Text('¿Ya tienes un código de activación?', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          hintText: 'Código',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _verificarCodigo,
                      child: const Text('Activar'),
                    ),
                  ],
                ),
                
                if (!widget.isBlocking) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
