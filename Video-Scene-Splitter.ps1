# Video-Scene-Splitter.ps1 - v2.1
# Estrae scene da video con GUI Matrix, auto-FFmpeg, log e pulsante annulla

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ========================= AUTO-FFMPEG =========================
$script:workDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$ffmpegPath = Join-Path $script:workDir "ffmpeg.exe"
$ffprobePath = Join-Path $script:workDir "ffprobe.exe"

function Initialize-FFmpeg {
    if ((Test-Path $ffmpegPath) -and (Test-Path $ffprobePath)) { return $true }
    
    $resp = [Windows.Forms.MessageBox]::Show("FFmpeg non trovato. Vuoi scaricarlo automaticamente (~80 MB)?", "FFmpeg Missing", [Windows.Forms.MessageBoxButtons]::YesNo)
    if ($resp -eq "No") { 
        [Windows.Forms.MessageBox]::Show("Download saltato. Scarica manualmente da https://www.gyan.dev/ffmpeg/builds/ e metti ffmpeg.exe e ffprobe.exe nella cartella dello script.", "Info")
        return $false 
    }
    
    $zipPath = Join-Path $env:TEMP "ffmpeg_dl.zip"
    $extractPath = Join-Path $env:TEMP "ffmpeg_temp"
    $url = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
    
    $maxRetries = 3
    $retryCount = 0
    $success = $false
    
    while ($retryCount -lt $maxRetries -and -not $success) {
        try {
            $retryCount++
            Write-Host "Tentativo $retryCount/$maxRetries di download FFmpeg..." -ForegroundColor Cyan
            
            # Timeout di 5 minuti
            $ProgressPreference = 'SilentlyContinue'  # velocizza Invoke-WebRequest
            $timeout = 300  # secondi
            
            $client = New-Object System.Net.WebClient
            $client.Headers.Add("User-Agent", "PowerShell")
            
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $client.DownloadFile($url, $zipPath)
            $sw.Stop()
            
            if ((Test-Path $zipPath) -and (Get-Item $zipPath).Length -gt 1MB) {
                $sizeMB = [math]::Round((Get-Item $zipPath).Length / 1MB, 1)
                Write-Host "Scaricati $sizeMB MB in $([math]::Round($sw.Elapsed.TotalSeconds, 1))s" -ForegroundColor Green
                $success = $true
            } else {
                throw "File scaricato troppo piccolo o corrotto"
            }
        } catch {
            Write-Host "Errore tentativo $retryCount : $($_.Exception.Message)" -ForegroundColor Red
            if ($retryCount -lt $maxRetries) {
                Write-Host "Riprovo tra 5 secondi..." -ForegroundColor Yellow
                Start-Sleep -Seconds 5
            }
        }
    }
    
    if (-not $success) {
        [Windows.Forms.MessageBox]::Show("Download fallito dopo $maxRetries tentativi.`n`nScarica manualmente da https://www.gyan.dev/ffmpeg/builds/ e metti ffmpeg.exe e ffprobe.exe nella cartella dello script.", "Errore download")
        return $false
    }
    
    try {
        Write-Host "Estrazione in corso..." -ForegroundColor Cyan
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
        Get-ChildItem -Path $extractPath -Include "ffmpeg.exe", "ffprobe.exe" -Recurse | ForEach-Object {
            Move-Item $_.FullName $script:workDir -Force
        }
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
        Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "[OK] FFmpeg installato." -ForegroundColor Green
        return $true
    } catch {
        [Windows.Forms.MessageBox]::Show("Errore estrazione: $($_.Exception.Message)")
        return $false
    }
}

if (-not (Initialize-FFmpeg)) { exit }

# ========================= LOGGING =========================
$script:logFile = $null
function Start-Log {
    param([string]$Folder)
    if (-not (Test-Path $Folder)) { New-Item -ItemType Directory -Path $Folder -Force | Out-Null }
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $script:logFile = Join-Path $Folder "scene_splitter_$timestamp.log"
    @("============================================================", " SCENE SPLITTER - LOG", "============================================================", "Data: $(Get-Date)", "") | Set-Content -Path $script:logFile -Encoding UTF8
}
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    if (-not $script:logFile) { return }
    Add-Content -Path $script:logFile -Value "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message" -Encoding UTF8
}

# ========================= UI SETUP =========================
$form = New-Object System.Windows.Forms.Form
$form.Text = "Video Scene Splitter Pro - Fabry Toolbox"
$form.Size = New-Object Drawing.Size(740, 780)
$form.StartPosition = "CenterScreen"
$form.BackColor = [Drawing.Color]::FromArgb(15, 15, 15)
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "VIDEO SCENE SPLITTER PRO"
$lblTitle.ForeColor = [Drawing.Color]::LimeGreen
$lblTitle.Font = New-Object Drawing.Font("Consolas", 18, [Drawing.FontStyle]::Bold)
$lblTitle.TextAlign = "MiddleCenter"
$lblTitle.Size = New-Object Drawing.Size(700, 40)
$lblTitle.Location = New-Object Drawing.Point(10, 20)
$form.Controls.Add($lblTitle)

function Create-Label ($text, $x, $y) {
    $l = New-Object Windows.Forms.Label
    $l.Text = $text; $l.Location = New-Object Drawing.Point($x, $y)
    $l.ForeColor = [Drawing.Color]::White; $l.AutoSize = $true
    return $l
}

# File e Folder
$btnVideo = New-Object System.Windows.Forms.Button
$btnVideo.Text = "SELECT VIDEO"; $btnVideo.Location = New-Object Drawing.Point(30, 80)
$btnVideo.Size = New-Object Drawing.Size(120, 30); $btnVideo.FlatStyle = "Flat"
$btnVideo.ForeColor = [Drawing.Color]::LimeGreen; $btnVideo.FlatAppearance.BorderColor = "LimeGreen"
$form.Controls.Add($btnVideo)

$lblVideo = Create-Label "Nessun file selezionato" 160 88
$form.Controls.Add($lblVideo)

$btnOut = New-Object System.Windows.Forms.Button
$btnOut.Text = "SELECT OUTPUT"; $btnOut.Location = New-Object Drawing.Point(30, 120)
$btnOut.Size = New-Object Drawing.Size(120, 30); $btnOut.FlatStyle = "Flat"
$btnOut.ForeColor = [Drawing.Color]::LimeGreen; $btnOut.FlatAppearance.BorderColor = "LimeGreen"
$form.Controls.Add($btnOut)

$lblOut = Create-Label "Nessuna cartella selezionata" 160 128
$form.Controls.Add($lblOut)

# Settings
$gbSet = New-Object Windows.Forms.GroupBox
$gbSet.Text = "Settings"; $gbSet.ForeColor = [Drawing.Color]::LimeGreen
$gbSet.Location = New-Object Drawing.Point(30, 170); $gbSet.Size = New-Object Drawing.Size(660, 180)
$form.Controls.Add($gbSet)

$comboMode = New-Object System.Windows.Forms.ComboBox
$comboMode.Items.AddRange(@("Scene Veloce", "Scene Standard", "Scene Precisa", "Intervalli Fissi"))
$comboMode.SelectedIndex = 1; $comboMode.Location = New-Object Drawing.Point(20, 35); $comboMode.Size = New-Object Drawing.Size(180, 30); $comboMode.DropDownStyle = "DropDownList"
$gbSet.Controls.Add($comboMode)

$lblParam = Create-Label "Sensibilità:" 220 38
$gbSet.Controls.Add($lblParam)

$txtSens = New-Object System.Windows.Forms.TextBox
$txtSens.Text = "0.40"; $txtSens.Location = New-Object Drawing.Point(300, 35); $txtSens.Size = New-Object Drawing.Size(50, 30)
$gbSet.Controls.Add($txtSens)

$comboInterval = New-Object System.Windows.Forms.ComboBox
$comboInterval.Items.AddRange(@("3", "5", "10", "15", "30", "60"))
$comboInterval.SelectedIndex = 1; $comboInterval.Location = New-Object Drawing.Point(300, 35); $comboInterval.Size = New-Object Drawing.Size(50, 30); $comboInterval.Visible = $false
$gbSet.Controls.Add($comboInterval)

$comboMode.Add_SelectedIndexChanged({
    if ($comboMode.SelectedItem -eq "Intervalli Fissi") {
        $lblParam.Text = "Minuti clip:"; $txtSens.Visible = $false; $comboInterval.Visible = $true
    } else {
        $lblParam.Text = "Sensibilità:"; $txtSens.Visible = $true; $comboInterval.Visible = $false
    }
})

$gbSet.Controls.Add((Create-Label "Formato:" 380 38))
$comboExt = New-Object Windows.Forms.ComboBox
$comboExt.Items.AddRange(@("mkv", "mp4", "mov"))
$comboExt.SelectedIndex = 0; $comboExt.Location = New-Object Drawing.Point(440, 35); $comboExt.Size = New-Object Drawing.Size(70, 30); $comboExt.DropDownStyle = "DropDownList"
$gbSet.Controls.Add($comboExt)

$gbSet.Controls.Add((Create-Label "Hardware:" 20 100))
$comboHw = New-Object Windows.Forms.ComboBox
$comboHw.Items.AddRange(@("Auto", "NVIDIA CUDA", "Intel QuickSync", "CPU pura"))
$comboHw.SelectedIndex = 0; $comboHw.Location = New-Object Drawing.Point(100, 97); $comboHw.Size = New-Object Drawing.Size(180, 30); $comboHw.DropDownStyle = "DropDownList"
$gbSet.Controls.Add($comboHw)

$chkAudio = New-Object Windows.Forms.CheckBox
$chkAudio.Text = "Include Audio (AAC)"; $chkAudio.Checked = $true; $chkAudio.ForeColor = [Drawing.Color]::White; $chkAudio.Location = New-Object Drawing.Point(320, 97); $chkAudio.AutoSize = $true
$gbSet.Controls.Add($chkAudio)

# Log e Progress
$progress = New-Object Windows.Forms.ProgressBar
$progress.Location = New-Object Drawing.Point(30, 370); $progress.Size = New-Object Drawing.Size(660, 20)
$form.Controls.Add($progress)

$txtLog = New-Object Windows.Forms.TextBox
$txtLog.Multiline = $true; $txtLog.ScrollBars = "Vertical"; $txtLog.ReadOnly = $true; $txtLog.BackColor = [Drawing.Color]::Black; $txtLog.ForeColor = [Drawing.Color]::LimeGreen; $txtLog.Font = New-Object Drawing.Font("Consolas", 9)
$txtLog.Location = New-Object Drawing.Point(30, 410); $txtLog.Size = New-Object Drawing.Size(660, 210)
$form.Controls.Add($txtLog)

# Pulsanti
$btnStart = New-Object Windows.Forms.Button
$btnStart.Text = "START DISASSEMBLY"; $btnStart.Location = New-Object Drawing.Point(30, 650); $btnStart.Size = New-Object Drawing.Size(300, 45); $btnStart.BackColor = [Drawing.Color]::FromArgb(0, 40, 0); $btnStart.ForeColor = [Drawing.Color]::LimeGreen; $btnStart.Font = New-Object Drawing.Font("Consolas", 12, [Drawing.FontStyle]::Bold); $btnStart.FlatStyle = "Flat"
$form.Controls.Add($btnStart)

$btnCancel = New-Object Windows.Forms.Button
$btnCancel.Text = "ANNULLA"; $btnCancel.Location = New-Object Drawing.Point(340, 650); $btnCancel.Size = New-Object Drawing.Size(350, 45); $btnCancel.BackColor = [Drawing.Color]::FromArgb(60, 0, 0); $btnCancel.ForeColor = [Drawing.Color]::Red; $btnCancel.Font = New-Object Drawing.Font("Consolas", 12, [Drawing.FontStyle]::Bold); $btnCancel.FlatStyle = "Flat"; $btnCancel.Visible = $false
$form.Controls.Add($btnCancel)

# ========================= CORE LOGIC =========================

function Get-Duration ($file) {
    $out = & $ffprobePath -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $file
    return [double]::Parse($out, [System.Globalization.CultureInfo]::InvariantCulture)
}

function Detect-Scenes ($mode, $threshold) {
    if ($mode -eq "Intervalli Fissi") {
        $totalDur = Get-Duration $script:videoFile
        $intervalSec = ([int]$comboInterval.SelectedItem) * 60
        $stamps = @(0.0)
        for ($t = $intervalSec; $t -lt $totalDur; $t += $intervalSec) { $stamps += $t }
        $stamps += $totalDur
        return $stamps
    }

    $thStr = [string]$threshold.ToString().Replace(",", ".")
    $logPath = Join-Path $env:TEMP "pf_detect_$(Get-Random).log"
    $filter = if ($mode -eq "Scene Precisa") { "hqdn3d,mpdecimate,select='gt(scene,$thStr)',showinfo" } else { "select='gt(scene,$thStr)',showinfo" }

    $detectArgs = @("-i", $script:videoFile, "-vf", $filter, "-f", "null", "NUL")
    $null = & $ffmpegPath @detectArgs 2>&1 | Out-File $logPath -Encoding UTF8

    $timestamps = @(0.0)
    if (Test-Path $logPath) {
        (Get-Content $logPath) | ForEach-Object { if ($_ -match "pts_time:([0-9\.]+)") {
            $t = [double]::Parse($matches[1], [System.Globalization.CultureInfo]::InvariantCulture)
            if ($t -gt ($timestamps[-1] + 1.5)) { $timestamps += $t }
        }}
        $timestamps += Get-Duration $script:videoFile
        Remove-Item $logPath -Force -ErrorAction SilentlyContinue
    }
    return $timestamps
}

$script:currentProcess = $null
$script:isExtracting = $false

function Extract-Clip ($VideoPath, $OutputPath, $Start, $Duration) {
    if (-not $script:isExtracting) { return $false }
    
    $startStr = $Start.ToString("0.000", [System.Globalization.CultureInfo]::InvariantCulture)
    $durStr = $Duration.ToString("0.000", [System.Globalization.CultureInfo]::InvariantCulture)
    $ext = $comboExt.SelectedItem
    $hwArgs = switch ($comboHw.SelectedItem) { "NVIDIA CUDA" { @("-hwaccel", "cuda") } "Intel QuickSync" { @("-hwaccel", "qsv") } default { @() } }
    $audioArgs = if ($chkAudio.Checked) { @("-c:a", "aac", "-b:a", "192k") } else { @("-an") }
    $mp4Args = if ($ext -eq "mp4") { @("-movflags", "+faststart") } else { @() }

    $ffArgs = @()
    $ffArgs += $hwArgs
    $ffArgs += @("-y", "-ss", $startStr, "-t", $durStr, "-i", $VideoPath, "-map", "0:v:0", "-map", "0:a?", "-c:v", "libx264", "-crf", "18", "-preset", "superfast", "-sn")
    $ffArgs += $audioArgs
    $ffArgs += $mp4Args
    $ffArgs += $OutputPath

    # Usa Start-Process asincrono per non bloccare la GUI
    $script:currentProcess = Start-Process -FilePath $ffmpegPath -ArgumentList $ffArgs -PassThru -NoNewWindow -Wait
    return $script:currentProcess.ExitCode -eq 0
}

# ========================= EVENTS =========================

$btnVideo.Add_Click({
    $dlg = New-Object Windows.Forms.OpenFileDialog
    if ($dlg.ShowDialog() -eq "OK") {
        $script:videoFile = $dlg.FileName
        $lblVideo.Text = Split-Path $script:videoFile -Leaf
        if ($script:outDir -eq "") { 
            $script:outDir = Split-Path $script:videoFile -Parent
            $lblOut.Text = $script:outDir
        }
    }
})

$btnOut.Add_Click({
    $dlg = New-Object Windows.Forms.FolderBrowserDialog
    if ($dlg.ShowDialog() -eq "OK") {
        $script:outDir = $dlg.SelectedPath
        $lblOut.Text = $script:outDir
    }
})

$btnCancel.Add_Click({
    $script:isExtracting = $false
    if ($script:currentProcess -and -not $script:currentProcess.HasExited) {
        $script:currentProcess.Kill()
    }
    $txtLog.AppendText("[!] Estrazione annullata dall'utente.`r`n")
    Write-Log "Estrazione annullata" "WARN"
    $btnCancel.Visible = $false
    $btnStart.Enabled = $true
})

$btnStart.Add_Click({
    if (-not $script:videoFile -or -not $script:outDir) { [Windows.Forms.MessageBox]::Show("Seleziona video e cartella output!"); return }
    
    $txtLog.Clear(); $progress.Value = 0; $btnStart.Enabled = $false; $btnCancel.Visible = $true; $form.Refresh()
    
    Start-Log -Folder $script:outDir
    Write-Log "Video: $($script:videoFile)" "INFO"
    
    try {
        $script:isExtracting = $true
        $txtLog.AppendText("[i] Rilevamento scene in corso...`r`n"); $form.Refresh()
        
        $times = Detect-Scenes $comboMode.SelectedItem $txtSens.Text
        $totalClips = $times.Count - 1
        
        if ($totalClips -le 0) {
            $txtLog.AppendText("[X] Nessuna scena rilevata.`r`n")
            return
        }
        
        # Conferma prima di partire
        $resp = [Windows.Forms.MessageBox]::Show("Rilevate $totalClips scene.`n`nVuoi esportarle tutte?", "Conferma", "YesNo", "Question")
        if ($resp -ne "Yes") {
            $txtLog.AppendText("[!] Esportazione annullata.`r`n")
            return
        }
        
        $txtLog.AppendText("[!] Esportazione di $totalClips clip in corso...`r`n")
        Write-Log "Rilevate $totalClips scene. Avvio esportazione." "INFO"
        
        for ($i=0; $i -lt $totalClips; $i++) {
            if (-not $script:isExtracting) { break }
            
            $outFile = Join-Path $script:outDir ("scene_{0:D3}.{1}" -f ($i+1), $comboExt.SelectedItem)
            $txtLog.AppendText(" -> Clip $($i+1)/$totalClips... "); $form.Refresh()
            
            if (Extract-Clip $script:videoFile $outFile $times[$i] ($times[$i+1]-$times[$i])) { 
                $txtLog.AppendText("OK`r`n")
                Write-Log "Clip $($i+1) salvata: $outFile" "OK"
            } else { 
                $txtLog.AppendText("FAILED`r`n")
                Write-Log "Clip $($i+1) fallita." "ERROR"
            }
            $progress.Value = [math]::Round((($i+1)/$totalClips)*100)
        }
        
        if ($script:isExtracting) {
            $txtLog.AppendText("[!] FINITO.`r`n")
            [Windows.Forms.MessageBox]::Show("Esportazione completata!`n`nLog: $($script:logFile)", "Fatto")
        }
    } catch {
        $txtLog.AppendText("[X] Errore: $($_.Exception.Message)`r`n")
        Write-Log "Errore critico: $($_.Exception.Message)" "ERROR"
    } finally {
        $script:isExtracting = $false
        $btnStart.Enabled = $true
        $btnCancel.Visible = $false
    }
})

$form.ShowDialog() | Out-Null