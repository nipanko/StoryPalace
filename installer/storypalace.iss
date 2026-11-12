; StoryPalace Windows installer (Inno Setup 6).
; Build: ISCC installer\storypalace.iss  ->  build\installer\StoryPalace-Setup-<version>.exe

#define AppName "StoryPalace"
#define AppVersion "1.2.0"
#define Publisher "Storybook Interactive Private Limited"

[Setup]
AppId={{6F3B1E2A-8C4D-4E5F-9A1B-2C3D4E5F6A7B}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#Publisher}
AppCopyright=© 2026 {#Publisher}
VersionInfoCompany={#Publisher}
VersionInfoProductName={#AppName}
VersionInfoVersion={#AppVersion}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
; installs for the current user without an admin prompt; the wizard lets them pick all users
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
OutputDir=..\build\installer
OutputBaseFilename=StoryPalace-Setup-{#AppVersion}
SetupIconFile=..\build_assets\icon.ico
UninstallDisplayIcon={app}\StoryPalace.exe
WizardStyle=modern
Compression=lzma2/ultra64
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\build\windows\StoryPalace.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\StoryPalace.exe"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\StoryPalace.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\StoryPalace.exe"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
