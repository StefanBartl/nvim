<#
.SYNOPSIS
  Log every change of the Windows clipboard together with the process that wrote it.

.DESCRIPTION
  Diagnoses "my copy did not take / an old value came back" problems: a clipboard
  sync tool (AnyDesk, Phone Link, RDP/Horizon, clipboard managers) re-writing the
  clipboard, or a copy that never reached it. Registers a clipboard format listener
  on a hidden window (no polling) and, for each WM_CLIPBOARDUPDATE, logs:
    - time and clipboard sequence number
    - the owner process (GetClipboardOwner; may be empty for ownerless writes)
    - the process that has the foreground window (what you were working in)
    - the first characters of the text, if any
  Lines go to the console and are appended to the log file.

  Run it in a spare terminal and leave it open; when the bug shows up, look at the
  lines just before the bad paste: the entry that wrote the stale value names the
  culprit. A copy you made that has NO entry never reached the clipboard.

.PARAMETER LogPath
  Where to append the log. Default: $env:LOCALAPPDATA\clipboard-monitor.log

.PARAMETER MaxChars
  How many characters of the text to log. Default 80; 0 logs no text at all.

.PARAMETER Seconds
  Stop after this many seconds (0 = run until Ctrl+C). Used for smoke tests.

.EXAMPLE
  pwsh -NoProfile -File scripts/clipboard-monitor.ps1
#>
param(
  [string]$LogPath = (Join-Path $env:LOCALAPPDATA 'clipboard-monitor.log'),
  [int]$MaxChars = 80,
  [int]$Seconds = 0
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms

if (-not ('ClipMon.Listener' -as [type])) {
  # .NET (pwsh 7) forwards `Message` to System.Windows.Forms.Primitives; Windows PowerShell 5.1 has no such assembly.
  # Naming the type loads whichever assembly really holds it.
  $refs = @('System.Windows.Forms', [System.Windows.Forms.Message].Assembly.Location) | Select-Object -Unique
  Add-Type -ReferencedAssemblies $refs -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace ClipMon {
  public class Listener : NativeWindow, IDisposable {
    const int WM_CLIPBOARDUPDATE = 0x031D;
    [DllImport("user32.dll", SetLastError = true)] static extern bool AddClipboardFormatListener(IntPtr hwnd);
    [DllImport("user32.dll", SetLastError = true)] static extern bool RemoveClipboardFormatListener(IntPtr hwnd);
    [DllImport("user32.dll")] static extern IntPtr GetClipboardOwner();
    [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] static extern uint GetClipboardSequenceNumber();
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint pid);

    public event Action<uint, uint, uint> Changed;

    public Listener() {
      CreateHandle(new CreateParams());
      if (!AddClipboardFormatListener(Handle)) {
        throw new InvalidOperationException("AddClipboardFormatListener failed, error " + Marshal.GetLastWin32Error());
      }
    }

    static uint PidOf(IntPtr hwnd) {
      if (hwnd == IntPtr.Zero) return 0;
      uint pid;
      GetWindowThreadProcessId(hwnd, out pid);
      return pid;
    }

    protected override void WndProc(ref Message m) {
      if (m.Msg == WM_CLIPBOARDUPDATE && Changed != null) {
        Changed(GetClipboardSequenceNumber(), PidOf(GetClipboardOwner()), PidOf(GetForegroundWindow()));
      }
      base.WndProc(ref m);
    }

    public void Dispose() {
      RemoveClipboardFormatListener(Handle);
      DestroyHandle();
    }
  }
}
'@
}

function Get-ProcLabel([uint32]$procId) {
  if ($procId -eq 0) { return '-' }
  try { return '{0}({1})' -f (Get-Process -Id $procId).ProcessName, $procId } catch { return "?($procId)" }
}

function Get-ClipText {
  # The writer may still hold the clipboard right after the notification; retry briefly.
  for ($i = 0; $i -lt 5; $i++) {
    try {
      if ([System.Windows.Forms.Clipboard]::ContainsText()) { return [System.Windows.Forms.Clipboard]::GetText() }
      return $null
    } catch { Start-Sleep -Milliseconds 30 }
  }
  return '<clipboard busy>'
}

function Write-Entry([string]$line) {
  Write-Host $line
  Add-Content -LiteralPath $LogPath -Value $line -Encoding utf8
}

$listener = [ClipMon.Listener]::new()
$listener.add_Changed({
    param($seq, $ownerPid, $fgPid)
    $text = Get-ClipText
    $shown = if ($null -eq $text) { '<no text>' }
    elseif ($MaxChars -le 0) { "<$($text.Length) chars>" }
    else {
      $flat = ($text -replace "`r?`n", ' / ')
      if ($flat.Length -gt $MaxChars) { $flat.Substring(0, $MaxChars) + '...' } else { $flat }
    }
    Write-Entry ('{0} seq={1} owner={2} fg={3} text={4}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'),
      $seq, (Get-ProcLabel $ownerPid), (Get-ProcLabel $fgPid), $shown)
  })

Write-Entry ('# clipboard-monitor started {0}, log: {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $LogPath)
try {
  if ($Seconds -gt 0) {
    $deadline = (Get-Date).AddSeconds($Seconds)
    while ((Get-Date) -lt $deadline) {
      [System.Windows.Forms.Application]::DoEvents()
      Start-Sleep -Milliseconds 20
    }
  } else {
    [System.Windows.Forms.Application]::Run()
  }
} finally {
  $listener.Dispose()
}
