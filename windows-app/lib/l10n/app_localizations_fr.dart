// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppL10nFr extends AppL10n {
  AppL10nFr([String locale = 'fr']) : super(locale);

  @override
  String get appTagline => 'Téléchargeur YouTube premium';

  @override
  String get navDashboard => 'Tableau de bord';

  @override
  String get navDownload => 'Télécharger';

  @override
  String get navQueue => 'File d\'attente';

  @override
  String get navHistory => 'Historique';

  @override
  String get navPlaylists => 'Playlists';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get navProfile => 'Profil';

  @override
  String get signInTitle => 'Bienvenue dans TubeVault';

  @override
  String get signInSubtitle =>
      'Connectez-vous avec Google pour débloquer les téléchargements, l\'historique et votre file d\'attente.';

  @override
  String get signInButton => 'Se connecter avec Google';

  @override
  String get signInWaiting => 'En attente du navigateur…';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get fetch => 'Récupérer';

  @override
  String get paste => 'Coller';

  @override
  String get pasteDetected => 'Coller le lien détecté';

  @override
  String get start => 'Démarrer le téléchargement';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Reprendre';

  @override
  String get cancel => 'Annuler';

  @override
  String get retry => 'Réessayer';

  @override
  String get remove => 'Retirer';

  @override
  String get clearFinished => 'Effacer les terminés';

  @override
  String get clearAll => 'Tout effacer';

  @override
  String get modeVideo => 'Vidéo';

  @override
  String get modeAudio => 'Audio';

  @override
  String get modeThumbnail => 'Miniature';

  @override
  String get modeSubtitles => 'Sous-titres';

  @override
  String get quality => 'Qualité';

  @override
  String get container => 'Conteneur';

  @override
  String get audioQuality => 'Qualité audio';

  @override
  String get audioBitrate => 'Débit audio';

  @override
  String get downloadOptions => 'Options de téléchargement';

  @override
  String get appearance => 'Apparence';

  @override
  String get theme => 'Thème';

  @override
  String get language => 'Langue';

  @override
  String get downloadDefaults => 'Valeurs par défaut';

  @override
  String get storage => 'Stockage';

  @override
  String get behaviour => 'Comportement';

  @override
  String get downloadEngine => 'Moteur de téléchargement';

  @override
  String get about => 'À propos';

  @override
  String get searchDownloads => 'Rechercher des téléchargements…';

  @override
  String get queueEmptyTitle => 'Votre file d\'attente est vide';

  @override
  String get historyEmptyTitle => 'Aucun téléchargement pour l\'instant';
}
