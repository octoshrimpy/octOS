# octoOS
tui tools for daily drivers

* editor
  * micro

* dev work
  * cani
  * lazygit

* word precessing

* translate
  * gtt

* podcast
  * castero
  * shellcaster

* clock, timer
  * clock-tui

* login
  * ly
  * lemurs

* launcher
  * sway-launcher-desktop

* task management
  * taskline (CLI, not TUI)
  * taskwarrior-tui
  * topydo
  * kabmat [!]
  * projectable
  * yoku
    * might make cursor invisible on close

* system
  * bluetooth
    * bltui

* Maps
  * mercator
    
* music
  * spotify-tui (spotify)
  * gomu (local)
  * ytui-music (youtube)
  * pyradio (radio)
  
* chat
  * gomuks (element)
  * discli (discord)
  
* search
  * ddgr 

* read ebook
  * baca

* gpt
  * tgpt

* internet browser
  * carbonyl
  * html2md | glow -p

* file browser
  * tuifimanager

* markdown browser (gh too)
  * frogmouth
  
* calendar
  * calcurse
  * calcure
  * khal
  
* news
  * rttt
  
* install tools & environments
  * pipx
  * pkm

* spreadsheet & data
  * visidata.org

* flashcards
  * hascard

* system management
  * cylon

* newbie help
  * https://github.com/timepigeon/explainshell-cli

---

bash functions

> search duckduckgo and show top 3 results
> `d sushi near manhattan square`
```
d () {
  local search_str="$*"
  ddgr -n 3 $search_str
}
```

> browse web with slow.octo proxy
> `slow www.bbc.com`
```
slow () {
  local url=$(echo "$*" | tr ' ' '+')
  local prefix="https://slow.octoshrimpy.dev/"
  local full="$prefix$url"
  echo "$full"
  html2md --in $full | glow -p -w 80
}
```

> quick-commit into current git branch
> `yeet adds new feature, fixes bug `
```
function yeet() {
    git add .
    git commit -a -m "$*"
    git push
}
```

> make markdown file, create folders if missing
> `mkmd path/to/file/and/then/filename`
```
function mkmd() {
  mkdir -p "$(dirname "$1")" &&
  touch "$1.md"
}
```
