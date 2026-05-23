import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TermsDialog extends StatelessWidget {
  final bool isPrivacy;
  const TermsDialog({super.key, this.isPrivacy = false});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
            child: Row(children: [
              Expanded(child: Text(
                isPrivacy ? 'Política de Privacidad' : 'Términos y Condiciones',
                style: const TextStyle(color: AppTheme.textPrimary,
                    fontSize: 18, fontWeight: FontWeight.bold),
              )),
              IconButton(icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context)),
            ]),
          ),
          const Divider(color: AppTheme.divider),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Text(
              isPrivacy ? _privacyText : _termsText,
              style: const TextStyle(color: AppTheme.textSecondary,
                  fontSize: 13, height: 1.6),
            ),
          )),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(width: double.infinity, height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Entendido', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              )),
          ),
        ],
      ),
    );
  }
}

const String _termsText = '''
TÉRMINOS Y CONDICIONES DE USO — MusPlay
Última actualización: 2025

Al usar MusPlay, aceptas los siguientes términos. Si no estás de acuerdo, no uses la aplicación.

1. DESCRIPCIÓN DEL SERVICIO
MusPlay es un reproductor de música que permite al usuario gestionar y reproducir archivos de audio almacenados en su propio dispositivo y en su cuenta personal de Google Drive. La aplicación NO almacena música en servidores propios ni distribuye contenido entre usuarios.

2. RESPONSABILIDAD DEL CONTENIDO
El usuario es el único y exclusivo responsable del contenido que sube, almacena y reproduce a través de MusPlay. Al subir un archivo de audio, el usuario declara y garantiza que:
  a) Es propietario del archivo o cuenta con los derechos necesarios para su uso personal.
  b) No utilizará la aplicación para reproducir, compartir ni distribuir contenido que infrinja derechos de autor de terceros.
  c) Comprende que MusPlay es un reproductor personal y NO un servicio de distribución de música.

3. USO ACEPTABLE
Queda expresamente prohibido usar MusPlay para:
  • Distribuir o compartir música protegida por derechos de autor sin autorización.
  • Eludir medidas de protección de contenido digital (DRM).
  • Cualquier actividad ilegal conforme a las leyes aplicables.

4. GOOGLE DRIVE
MusPlay utiliza la API de Google Drive para almacenar archivos en la cuenta personal del usuario. El usuario acepta los Términos de Servicio de Google al usar esta funcionalidad. MusPlay solo tiene acceso a los archivos que él mismo crea dentro de la carpeta "MusPlayFiles" y no puede acceder a ningún otro archivo del Drive del usuario.

5. ANUNCIOS
La versión gratuita incluye anuncios proporcionados por Google AdMob. Al usar la versión gratuita, el usuario acepta la visualización de publicidad. Los usuarios con plan Premium o Pro no verán anuncios.

6. PLANES Y PAGOS
Los planes de suscripción (Premium y Pro) se cobran a través de Google Play Billing. Los precios están en MXN e incluyen impuestos aplicables. Las suscripciones se renuevan automáticamente salvo que se cancelen antes del período de renovación.

7. LIMITACIÓN DE RESPONSABILIDAD
MusPlay no se hace responsable por:
  • Pérdida de datos almacenados en Google Drive.
  • Interrupciones del servicio de Google Drive o Google Play.
  • Uso indebido de la aplicación por parte del usuario.

8. MODIFICACIONES
Nos reservamos el derecho de modificar estos términos en cualquier momento. El uso continuado de la app implica la aceptación de los nuevos términos.

9. CONTACTO
Para dudas o reportes: soporte@musplay.app
''';

const String _privacyText = '''
POLÍTICA DE PRIVACIDAD — MusPlay
Última actualización: 2025

Tu privacidad es importante para nosotros. Esta política explica qué datos recopilamos y cómo los usamos.

1. DATOS QUE RECOPILAMOS

a) Datos de cuenta (si inicias sesión):
  • Nombre y dirección de correo electrónico (proporcionados por Firebase Auth / Google Sign-In).
  • Foto de perfil de Google (opcional).
  • Plan de suscripción activo.

b) Datos de uso:
  • Información básica de uso para mejorar la app (a través de Firebase).
  • Identificador de dispositivo para mostrar anuncios relevantes (usuarios gratuitos).

c) Archivos de música:
  • MusPlay NO almacena tus archivos de música en servidores propios.
  • Los archivos se guardan exclusivamente en tu cuenta personal de Google Drive, en la carpeta "MusPlayFiles".
  • MusPlay solo puede acceder a los archivos que él mismo creó. No puede leer ningún otro archivo de tu Drive.

2. CÓMO USAMOS TUS DATOS
  • Para autenticarte y gestionar tu cuenta.
  • Para sincronizar tu plan de suscripción.
  • Para mostrarte anuncios relevantes (solo usuarios del plan gratuito, mediante Google AdMob).
  • Para mejorar el funcionamiento de la app.

3. COMPARTICIÓN DE DATOS
NO vendemos, alquilamos ni compartimos tus datos personales con terceros, excepto:
  • Google (Firebase, AdMob, Drive) como proveedor de servicios técnicos.
  • Cuando sea requerido por ley.

4. ANUNCIOS (PLAN GRATUITO)
Usamos Google AdMob para mostrar anuncios. AdMob puede usar el identificador de publicidad de tu dispositivo para personalizar anuncios. Puedes limitar esto en la configuración de tu dispositivo en Ajustes → Google → Anuncios.

5. SEGURIDAD
Usamos Firebase Authentication para proteger tu cuenta. Tus archivos de música están protegidos por la seguridad de tu propia cuenta de Google Drive.

6. TUS DERECHOS
Tienes derecho a:
  • Acceder a tus datos personales.
  • Solicitar la eliminación de tu cuenta y datos asociados.
  • Desconectar Google Drive en cualquier momento desde la app.

Para ejercer estos derechos, contáctanos en: privacidad@musplay.app

7. RETENCIÓN DE DATOS
Si eliminas tu cuenta, borramos tus datos de nuestros servidores en un plazo de 30 días. Tus archivos en Google Drive permanecen en tu Drive a menos que los elimines tú.

8. MENORES
MusPlay no está dirigida a menores de 13 años. No recopilamos datos de menores de forma consciente.

9. CAMBIOS A ESTA POLÍTICA
Te notificaremos de cambios significativos mediante un aviso en la app.

10. CONTACTO
Para preguntas sobre privacidad: privacidad@musplay.app
''';
