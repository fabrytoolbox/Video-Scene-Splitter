# Changelog

## [2.1.0] - 2025-01-26

### Fixed
- Rimosso l'uso di cmd.exe e file .bat per lanciare FFmpeg (path con spazi)
- Estrazione ora usa Start-Process asincrono

### Added
- Pulsante ANNULLA per fermare l'estrazione
- Conferma prima di esportare (mostra numero di scene)
- Log su file (scene_splitter_*.log)
- Auto-FFmpeg con retry e fallback manuale

## [2.0.0] - 2025-01-25

### Added
- GUI Matrix con 4 modalita di rilevamento
- Auto-FFmpeg
- Include audio AAC opzionale
- Formato output: MKV, MP4, MOV
