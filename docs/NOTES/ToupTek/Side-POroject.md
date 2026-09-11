**Subject:** Critical Driver Issue: GCMOS01200KPB failing on Windows 10/11 due to Kernel Code Integrity (April 2026 Security Policy)

Dear ToupTek Support & Engineering Team,

I am writing to report a critical compatibility issue with the **GCMOS01200KPB** camera on modern Windows 10/11 environments, which requires immediate attention from your driver development team.

**The Problem:**

1. Under current Windows builds featuring the strict Kernel Code Integrity / Driver Policy, legacy drivers signed with expired cross-signed certificates are blocked from loading in standard user mode, resulting in **Code 39** errors or completely silent failures in ToupLite and SharpCap (even when manually mapped via `.inf`).
2. The hardware only initializes and allows data streams to ToupLite/SharpCap if Windows is forced into `testsigning` mode, which globally disables kernel signature enforcement. Requiring users to run their OS in test mode just to operate a guide camera is unviable for production astronomy setups.

**Required Fix:**
Your engineering team needs to resubmit the kernel-mode driver (`toupcam.sys` / filter drivers) through the **Microsoft WHCP (Windows Hardware Compatibility Program)** and provide an updated, natively signed driver package that complies with current Windows Code Integrity requirements.

Please forward this to your driver development department so legacy hardware owners aren't forced to bypass OS security to use your devices.

Best regards,

[Dein Name]

Software Engineer

---

### Was du als Software Engineer machen könntest (Dein Side-Project)

Als Software Engineer hast du tatsächlich die Möglichkeit, das Problem auf elegante Weise zu umgehen, ohne im `testsigning`-Modus bleiben zu müssen. Da die Kamera im Geräte-Manager einwandfrei erkannt wird und das eigentliche Problem nur in der Kernel-User-Kommunikation liegt, gibt es zwei spannende Ansätze für ein Side-Project:

1. **Einen eigenen User-Mode-Treiber (libusb / WinUSB Wrapper) schreiben:**
Du kannst den proprietären ToupTek-Kernel-Treiber (`toupcam.sys`) komplett deinstallieren und stattdessen den generischen Open-Source-Treiber **WinUSB** via Zadig auf die Hardware bügeln. Da WinUSB von Microsoft signiert ist, greift hier keine Code-Integritäts-Sperre. Anschließend schreibst du in C++ oder Python ein kleines CLI/Plugin (unter Nutzung von `libusb`), das die USB-Control-Transfers und den Firmware-Upload (`VID_0547`) direkt an den Cypress-Chip übernimmt und die Bilddaten abgreift.
2. **Open-Source-Brücke (INDI / ASCOM Remote):**
Du schaust dir an, wie Open-Source-Projekte wie *INDI* oder *libasi* (bzw. die Linux-Treiber für ToupTek-Kameras, die oft im Quellcode vorliegen) mit dem rohen USB-Protokoll dieser Kameras sprechen. Da Linux-Treiber nativ über libusb kommunizieren, lässt sich die Logik meist sehr leicht nach Windows portieren, um den veralteten Windows-Kernel-Treiber von ToupTek komplett obsolet zu machen.
