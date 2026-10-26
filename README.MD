# 🎬 Video Scene Splitter Pro

Estrae scene da un video con GUI Matrix, rilevamento automatico e auto-download di FFmpeg.

## ✨ Feature

- ✅ **4 modalità di rilevamento**:
  - Scene Veloce (soglia alta)
  - Scene Standard (bilanciata)
  - Scene Precisa (con denoise)
  - Intervalli Fissi (clip di N minuti)
- ✅ **Auto-download FFmpeg** (con fallback manuale)
- ✅ **GUI Matrix** con log in tempo reale
- ✅ **Pulsante ANNULLA** per fermare l'esportazione
- ✅ **Conferma** prima di esportare (mostra numero di scene)
- ✅ **Include Audio** (AAC) opzionale
- ✅ **Formato output**: MKV, MP4, MOV
- ✅ **Log su file** (`scene_splitter_*.log`)

## 📋 Requisiti

- **Windows 10 / 11**
- **PowerShell 7+** (scarica da https://aka.ms/powershell)
- **FFmpeg** (scaricato automaticamente al primo avvio)

## 🚀 Quick start

```powershell
git clone https://github.com/fabrytoolbox/Video-Scene-Splitter.git
cd Video-Scene-Splitter
Unblock-File .\Video-Scene-Splitter.ps1
.\Video-Scene-Splitter.ps1

Oppure doppio click su avvia.bat.

🎯 Casi d'uso
Estrarre scene da film, video, presentazioni

Creare clip per social media (TikTok, Instagram, YouTube)

Analizzare video dividendoli in scene logiche

Backup di scene importanti da video lunghi

⚙️ Come funziona
Seleziona il video (o la cartella output)

Scegli la modalità (Scene Standard consigliata)

Clicca START DISASSEMBLY

Lo script rileva le scene e chiede conferma

Esporta le clip (puoi annullare in qualsiasi momento)

🐛 Problemi comuni
"FFmpeg non trovato"
Il tool chiede se scaricarlo. Se il download fallisce (server lento), scarica manualmente da https://www.gyan.dev/ffmpeg/builds/ e metti ffmpeg.exe e ffprobe.exe nella cartella dello script.

"Nessuna scena rilevata"
Prova con una sensibilità più bassa (es. 0.20) o usa "Intervalli Fissi" (es. ogni 5 minuti).

"Il download è lento"
Normale: FFmpeg pesa ~80 MB. Se fallisce, copia ffmpeg.exe da un'altra cartella (es. da un altro tool di Fabry Toolbox).

📜 Licenza
MIT (vedi LICENSE).

🙏 Crediti
FFmpeg per l'elaborazione video

Fabry Toolbox
