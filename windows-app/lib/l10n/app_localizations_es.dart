// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppL10nEs extends AppL10n {
  AppL10nEs([String locale = 'es']) : super(locale);

  @override
  String get appTagline => 'Descargador premium de YouTube';

  @override
  String get navDashboard => 'Panel';

  @override
  String get navDownload => 'Descargar';

  @override
  String get navQueue => 'Cola';

  @override
  String get navHistory => 'Historial';

  @override
  String get navPlaylists => 'Listas';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get navProfile => 'Perfil';

  @override
  String get signInTitle => 'Bienvenido a TubeVault';

  @override
  String get signInSubtitle =>
      'Inicia sesión con Google para desbloquear descargas, historial y tu cola.';

  @override
  String get signInButton => 'Iniciar sesión con Google';

  @override
  String get signInWaiting => 'Esperando al navegador…';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get fetch => 'Obtener';

  @override
  String get paste => 'Pegar';

  @override
  String get pasteDetected => 'Pegar enlace detectado';

  @override
  String get start => 'Iniciar descarga';

  @override
  String get pause => 'Pausar';

  @override
  String get resume => 'Reanudar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get retry => 'Reintentar';

  @override
  String get remove => 'Quitar';

  @override
  String get clearFinished => 'Borrar finalizados';

  @override
  String get clearAll => 'Borrar todo';

  @override
  String get modeVideo => 'Vídeo';

  @override
  String get modeAudio => 'Audio';

  @override
  String get modeThumbnail => 'Miniatura';

  @override
  String get modeSubtitles => 'Subtítulos';

  @override
  String get quality => 'Calidad';

  @override
  String get container => 'Contenedor';

  @override
  String get audioQuality => 'Calidad de audio';

  @override
  String get audioBitrate => 'Tasa de bits de audio';

  @override
  String get downloadOptions => 'Opciones de descarga';

  @override
  String get appearance => 'Apariencia';

  @override
  String get theme => 'Tema';

  @override
  String get language => 'Idioma';

  @override
  String get downloadDefaults => 'Valores por defecto';

  @override
  String get storage => 'Almacenamiento';

  @override
  String get behaviour => 'Comportamiento';

  @override
  String get downloadEngine => 'Motor de descarga';

  @override
  String get about => 'Acerca de';

  @override
  String get searchDownloads => 'Buscar descargas…';

  @override
  String get queueEmptyTitle => 'Tu cola está vacía';

  @override
  String get historyEmptyTitle => 'Aún no hay descargas';
}
