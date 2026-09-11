[missing] chrome
    Renders a hovered http(s) link as a picture of the page, instead of previewing it as text — `:Hover links web shot` turns it on, and it is off by default because a render *executes* the page rather than downloading it. Any Chromium-based browser answers: chrome, chromium, brave or msedge, searched in that order. Not on PATH is the normal case rather than the exception — measured on Windows, the Chrome installer does not extend PATH at all, so this reports missing on a machine where Chrome is plainly installed. hover.nvim looks in the usual install locations by itself and will find it there; `links.shot.command` names one outright. Same problem `soffice` above describes.
    scoop install googlechrome


Chrome ist aber installiert !
