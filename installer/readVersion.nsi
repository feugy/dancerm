!define File "readVersion.exe"
 
OutFile "readVersion.exe"
SilentInstall silent

requestExecutionLevel user
 
; read version from package.json
section

  nsJSON::Set /file "..\package.json"
  nsJSON::Get "version" /end
  Pop $R1

  ; Write it to a !define for use in main script
  FileOpen $R0 "$EXEDIR\Version.txt" w
  FileWrite $R0 '!define Version "$R1"'
  FileClose $R0
sectionEnd