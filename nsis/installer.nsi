;;;; lilypond.nsi -- LilyPond installer script for Microsoft Windows
;;;; (c) 2005--2007
;;;; Jan Nieuwenhuizen <janneke@gnu.org>
;;;; Han-Wen Nienhuys <janneke@gnu.org>
;;;; licence: GNU GPL

;; For quick [wine] test runs
;; !define TEST "1"


;;; substitutions

!define ENVIRON "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"

!define UNINSTALL \
	"Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRETTY_NAME}"
!define USER_SHELL_FOLDERS \
	"Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"

!define UninstLog "files.txt"
Var UninstLog

; Uninstall log file missing.
LangString UninstLogMissing ${LANG_ENGLISH} "${UninstLog} not found.$\r$\nCannot uninstall."

!include "substitute.nsh"
${StrLoc}
${UnStrLoc}

;;SetCompressor lzma  ; very slow
;;SetCompressor zlib
SetCompressor bzip2  ;;

Name "${PRETTY_NAME}"

Caption "${PRETTY_NAME} ${INSTALLER_VERSION} for Microsoft Windows"
BrandingText "${PRETTY_NAME} installer v1.0"


InstallDir $PROGRAMFILES\${PRETTY_NAME}
InstallDirRegKey HKLM "Software\${PRETTY_NAME}" "Install_Dir"

CRCCheck on
XPStyle on
InstallColors /windows

BGGradient 000000 E8FFE8 FFFFFF

;; Use Finish iso Close for the [close button text]
;; Although nothing happens after Close, experienced Windows users feel
;; much more with "Finish" than with Close.
MiscButtonText Back Next Cancel Finish

LicenseText "Conditions for redistributing ${PRETTY_NAME}" "Next"
LicenseData "${ROOT}\license\${NAME}"
LicenseForceSelection off

Page license

;; FIXME: the installer will crash on File /r commands if Page
;; directory is not used.
Page directory

Page components

;; Put a note to look at the Help page of the website on the
;; window when the install is completed
CompletedText "Install completed.  Please see $INSTDIR\usr\bin\${CANARY_EXE}."
Page instfiles

UninstPage uninstConfirm
UninstPage instfiles

Section "${PRETTY_NAME} (required)"
	;; always generate install log
	Logset on

silent:
	IfFileExists $INSTDIR\usr\bin\${CANARY_EXE}.exe no_overwrite_error fresh_install
no_overwrite_error:
	MessageBox MB_OK "Previous version of ${PRETTY_NAME} found$\r$\nUninstall the old version first."
	Abort "Previous version of ${PRETTY_NAME} found$\r$\nUninstall the old version first."

fresh_install:
	SetOverwrite on
	AllowSkipFiles on
	SetOutPath $INSTDIR

	File /r "${ROOT}\usr"
	File /r "${ROOT}\license"
	File /r "${ROOT}\files.txt"

	WriteUninstaller "uninstall.exe"
	CreateDirectory "$INSTDIR\usr\bin"

	Call registry_installer
	Call registry_path
SectionEnd

Function registry_path
	ReadRegStr $R0 HKLM "${ENVIRON}" "PATH"
	WriteRegExpandStr HKLM "${ENVIRON}" "PATH" "$R0;$INSTDIR\usr\bin"
FunctionEnd

;; copy & paste from the NSIS code examples
Function un.install_installed_files
 IfFileExists "$INSTDIR\${UninstLog}" +3
  MessageBox MB_OK|MB_ICONSTOP "$(UninstLogMissing)"
   Abort

 Push $R0
 Push $R1
 Push $R2
 SetFileAttributes "$INSTDIR\${UninstLog}" NORMAL
 FileOpen $UninstLog "$INSTDIR\${UninstLog}" r
 StrCpy $R1 -1

 GetLineCount:
  ClearErrors
  FileRead $UninstLog $R0
  IntOp $R1 $R1 + 1
  StrCpy $R0 "$INSTDIR\$R0" -2
  Push $R0
  IfErrors 0 GetLineCount

 Pop $R0

 LoopRead:
  StrCmp $R1 0 LoopDone
  Pop $R0

  IfFileExists "$R0\*.*" 0 +3
   RMDir $R0  #is dir
  Goto +3
  IfFileExists "$R0" 0 +2
   Delete "$R0" #is file

  IntOp $R1 $R1 - 1
  Goto LoopRead
 LoopDone:
 FileClose $UninstLog

 Pop $R2
 Pop $R1
 Pop $R0

FunctionEnd
;; end copy & paste


Section "Uninstall"
	ifSilent 0 silent
	Logset on

silent:
	DeleteRegKey HKLM SOFTWARE\${PRETTY_NAME}
	DeleteRegKey HKLM "${UNINSTALL}"

	DeleteRegKey HKCR "${PRETTY_NAME}" ""


	ReadRegStr $R0 HKLM "${ENVIRON}" "PATH"
	${UnStrLoc} $0 $R0 "$INSTDIR\usr\bin;" >

path_loop:
	StrCmp $0 "" path_done
	StrLen $1 "$INSTDIR\usr\bin;"
	IntOp $2 $0 + $1
	StrCpy $3 $R0 $0 0
	StrCpy $4 $R0 10000 $2
	WriteRegExpandStr HKLM "${ENVIRON}" "PATH" "$3$4"
	ReadRegStr $R0 HKLM "${ENVIRON}" "PATH"
	${UnStrLoc} $0 $R0 "$INSTDIR\usr\bin;" >
	StrCmp $0 "" path_done path_loop

path_done:
	call un.install_installed_files

	;; Remove shortcuts, if any
	SetShellVarContext all
	Delete "$SMPROGRAMS\${PRETTY_NAME}\*.*"
	Delete "$DESKTOP\${PRETTY_NAME}.lnk"
	RMDir "$SMPROGRAMS\${PRETTY_NAME}"

	SetShellVarContext current
	Delete "$SMPROGRAMS\${PRETTY_NAME}\*.*"
	Delete "$DESKTOP\${PRETTY_NAME}.lnk"
	RMDir "$SMPROGRAMS\${PRETTY_NAME}"

	;; Remove directories used
	RMDir "$SMPROGRAMS\${PRETTY_NAME}"
	RMDir "$INSTDIR\usr\bin"
	RMDir "$INSTDIR\usr\"
	Delete "$INSTDIR\uninstall.exe"
	Delete "$INSTDIR\files.txt"

	RMDir "$INSTDIR"
SectionEnd

Function registry_installer
	WriteRegStr HKLM "SOFTWARE\${PRETTY_NAME}" "Install_Dir" "$INSTDIR"
	WriteRegStr HKLM "${UNINSTALL}" "DisplayName" "${PRETTY_NAME}"
	WriteRegStr HKLM "${UNINSTALL}" "UninstallString" '"$INSTDIR\uninstall.exe"'
	WriteRegDWORD HKLM "${UNINSTALL}" "NoModify" 1
	WriteRegDWORD HKLM "${UNINSTALL}" "NoRepair" 1
FunctionEnd
