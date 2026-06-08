; ============================================================================
;  TubeVault — Inno Setup script
;  Builds a single-file installer: TubeVault-Setup-x64.exe
;
;  Prerequisites:
;    1. flutter build windows --release
;    2. yt-dlp.exe and ffmpeg.exe present in ..\assets\bin\
;       (run scripts\fetch_binaries.ps1 to download them)
;    3. Inno Setup 6 installed (iscc on PATH)
;
;  Build:  iscc installer\tubevault.iss
; ============================================================================

#define AppName       "TubeVault"
#define AppVersion    "2.0.0"
#define AppPublisher  "Jayasakthi"
#define AppPublisherURL "https://www.jayasakthi.in"
#define AppExeName    "tubevault.exe"
; Path to the Flutter release output, relative to this .iss file.
#define ReleaseDir    "..\build\windows\x64\runner\Release"
#define BinDir        "..\assets\bin"
#define IconFile      "..\windows\runner\resources\app_icon.ico"

[Setup]
; A unique AppId keeps upgrades/uninstall consistent. Generate your own GUID.
AppId={{8B5F2C7A-9D3E-4A1B-B6C8-1E2F3A4B5C6D}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppPublisherURL}
AppSupportURL={#AppPublisherURL}
AppUpdatesURL={#AppPublisherURL}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
OutputDir=Output
OutputBaseFilename=TubeVault-Setup-x64
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
SetupIconFile={#IconFile}
WizardImageFile=wizard-large.bmp
WizardSmallImageFile=wizard-small.bmp
UninstallDisplayIcon={app}\{#AppExeName}
PrivilegesRequired=admin

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; The entire Flutter release output (exe + DLLs + data/).
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion
; Bundled engine binaries — resolved at runtime from {app}\bin.
Source: "{#BinDir}\yt-dlp.exe"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "{#BinDir}\ffmpeg.exe"; DestDir: "{app}\bin"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppName}";        Filename: "{app}\{#AppExeName}"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}";  Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
