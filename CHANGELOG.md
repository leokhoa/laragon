---
---

# Change log

## Pre-release 1.1.0 (upcoming)

- [Web] New support of Angular 2
- [Mobile] New support of Ionic 2
- [Web & Mobile] New navigation and address bar in the Preview panel
- [Web & Mobile] Better overall user experience
- [Studio] Open project folder in Terminal
- [Studio] New web and mobile template catalog for project creation
- [Studio] New preferences: auto-shutdown server on solution close and auto-reload modified files
- [Studio] Better support of Retina displays
- [Code Editor] Comments toggling with `CMD-/` and `CTRL-/`
- [Code Editor] Better support of `.ts` `.less`, `.scss`, `.sass` and `.md` files
- [Git] Remote settings edition
- [Git & Deploy] Better overall user experience
- [Add-ons] Improved updatability of Studio components and dependencies mechanism
- [Extensions API] New option for `targets` argument in Extension manifest to handle files based on their extension
- Fix: Wakanda Studio deployment UX issue [#15](https://github.com/Wakanda/wakanda-issues/issues/15)
- Fix: TAB key shows completion list instead of indenting code
- Fix: Prototyper css files not updated automatically
- Fix: Prototyper unreachable Google fonts API

## 1.0.3 (Feb. 25)

- Fix: Live reload on Run Page in Windows Studio
- Fix: Model Designer combobox style [#35](https://github.com/Wakanda/wakanda-issues/issues/35)
- Fix: Autocompletion suggestions on multiple DataClasses
- Fix: Code Editor indentation visual hint for spaces
- Fix: Override via API of inherited attributes
- Fix: Console link to nodejs installation page

## 1.0.2 (Feb. 19)

- Fix: Loading large projects freezes the studio
- Fix: Directory panel can't be resized on small screens
- Fix: `bower update` fails inside `web` & `mobile` folders
- Fix: RPC modules renaming keeps both old and new paths exposed as RPC
- Fix: Git visual bug [#16](https://github.com/Wakanda/wakanda-issues/issues/16)
- Fix: `Untabify Selection` not working for JS Files
- Fix: Git and Troubleshooting interfaces slow load when offline
- Fix: renaming a folder in the explorer makes it disappear from the list
- Fix: black lines appear inside resized web zones
- Fix: Integrate latest Angular-Wakanda fixes ([1.0.3](https://github.com/Wakanda/angular-wakanda/releases/tag/v1.0.3))
- Fix: Concurrent Ionic Run or Build sometimes causes file corruption
- Fix: Prototyper's image widget does not render image in runtime
- Fix: Prototyper's RichText widget resize loop
- Fix: Prototyper's Combobox widget debugger statement from [27](https://github.com/Wakanda/wakanda-issues/issues/27)

---

## 1.0.1 (Dec. 17)

- Fix: Prototyper bug [#19](https://github.com/Wakanda/wakanda-issues/issues/19)
- Project creation with [Angular-Wakanda 1.0.2](http://wakanda.github.io/angular-wakanda)

---

## 1.0.0 (Dec. 7)

- [Angular-Wakanda 1.0.0 release](http://wakanda.github.io/angular-wakanda) and support in the Studio
- Angular-Wakanda project scaffolding on solution creation

---

## Beta

### Week 48 (Nov. 4 - Nov. 24)

- [Mobile] New Preview mobile apps in the studio
- [Mobile] New Run on mobile devices
- [Mobile] New troubleshooting application to setup and check your environment
- [Studio] Better Git support
- [Studio] New Deploy on cloud and git server
- [Studio] New "Getting Started" Start Page
- [Studio] Improvement on file creation:
  - New menu item to create CSS files
  - HTML files now created empty
  - No more magic destination and folder creation, except for Page and Component Prototypes
- [Web] New Run Page with live-reload support
- [Model] Improvement: model files scaffolding for MySQL connector
- [Add-ons] 10 new core Studio components updatable directly from Add-ons

### Week 45 (Oct. 19 - Nov. 3)

- [Mobile] New Run on mobile simulators
- [Mobile] New Build mobile apps from the studio
- [Studio] New Project directory structure
- [Studio] Improvement: a single Start / Stop server in the Studio that automatically loads the solution
- [Studio] New Studio panels:
  - One new left panel for Home and Solution Explorer
  - One new bottom panel for consoles and editors

### Week 42 (Sept. 28 - Oct. 18)

- [Extensions] New onToolbarButtonMenuOpen trigger
- [Studio] Code editors themes support
  - Menu "Wakanda Studio" > "Preferences" then "Code Editor” tab
  - Try one of our 30+ default themes, light and dark
  - Or create your own theme
- [Studio] New Preferences panel
  - Menu "Wakanda Studio" > "Preferences"
  - All the Studio and Editor settings are now in one place

### Week 39 (Sept 10 - Sept. 27)

- [Extensions] New onSolutionBeforeClosing trigger
- [Code Editor] Smarter auto-completion on Wakanda Model
  - [Try this gist code example](https://gist.github.com/cedricss/e41f60fdcf6ca5c31ea0)

### Week 36 (August 17 - Sept. 9)

- [Extensions] New API to open a page with URL parameters
- [Extensions] New API to get selected projects in the studio
- [Code Editor] Find in Files results now highlighted in the web editor
- [Mobile] New console extension to perform startup requirement checks

### Week 33 (July 27 - August 16)

- [Code Editor] Smarter auto-completion on JS code
  - [Try this gist code example](https://gist.github.com/cedricss/e41f60fdcf6ca5c31ea0)

### Week 30 (July 6 - July 26)

- [Code Editor] Quote selected text typing a single character
- [Studio] The new "Find in files” now supports replacement

### Week 27 (June 15 - July 5)

- [Code Editor] Better closing blocks behaviours (JS files)
  - Customize them via your Studio preferences
- [Code Editor] New Wakanda Web Editor
  - Open any .html or .css file
  - Try [Emmet abbreviations](http://emmet.io/)
  - [Fork this new extension](https://github.com/Wakanda/wakanda-extension-web-editor) and create your own Studio Editor
- [Studio] New "Find in files"
  - Menu "Find" > "Find in Files…"

### Week 24 (May 25 - June 14)

- [Extensions] New API to develop editor extensions in Wakanda Studio
