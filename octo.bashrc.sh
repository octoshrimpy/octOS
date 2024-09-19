# increase saved history and set a same datetime format
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTTIMEFORMAT="%d/%m/%y %T "


# setup required vs optional funcs
declare -A load_functions=(
    ["idea"]="no"
    ["d"]="no"
    ["slow"]="no"
    ["yeet"]="no"
    ["mkmd"]="no"
    ["mkcd"]="no"
    ["find"]="no"
    ["launch"]="no"
    ["gather"]="no"
    ["src"]="yes"
    ["dump_history"]="no"
    ["speak"]="no"
    ["setup_rpg"]="no"
    
    # rpg extras, ran by setup_rpg
    # ["format_rpg_text"]="optional"
    # ["count_printable_chars"]="optional"
    # ["calc_space"]="optional"
    # ["rpg"]="optional"
    # ["__cd"]="optional"
    # ["__ls"]="optional"
    # ["dn"]="optional"
    # ["sync_rpg"]="optional"
    # ["rpg-battle"]="optional"
)

# -- functions ------------------------------------------------------

# check if command exists and execute another command if not
# 
# usage: if_no micro "curl getmic.ro | bash"

function if_no {
    local cmd_to_check="$1"
    local cmd_to_exec="$2"
    
    if ! command -v "$cmd_to_check" &> /dev/null; then
        echo "$cmd_to_check not found, executing provided command…"
        eval "$cmd_to_exec"
    fi
}


# quickly jot down ideas from anywhere
# req:
#   gum     - https://github.com/charmbracelet/gum

idea {
    # if disabled, do not bother running
    [[ ${load_functions[${FUNCNAME[0]}]} == false ]] && return
    
    # Check if the environment variable IDEAS_PATH is set
    if [ -n "$IDEAS_PATH" ]; then
      mainpath="$IDEAS_PATH"
    else
      mainpath="$HOME/ideas"
    fi
    
    # Enter alternate buffer and move cursor to top-left
    echo -e "\033[?1049h\033[H"
    
    # Capture multi-line input from gum textarea into a temporary file
    tempfile=$(mktemp)
    gum write --header "Type your full idea here (CTRL+D to continue)" > "$tempfile"

    # Check if the file is empty (no input given)
    if [ ! -s "$tempfile" ]; then
        echo "No input provided. Exiting..."
        rm "$tempfile"
        return
    fi

    # Read the contents of the file into a variable and truncate
    file_contents="$(cat $tempfile)"

    # Check if the string length is greater than 25 characters before truncating
    if [ ${#file_contents} -gt 25 ]; then
      trunc_temp="${file_contents:0:25} ..."
    else
      trunc_temp="$file_contents"
    fi
    
    # Ensure the tags file exists
    tags_file="$mainpath/.tags"
    mkdir -p "$(dirname "$tags_file")"
    touch "$tags_file"
    

    selected_tags=""

    while :; do
      do_loop=false

      # Read old tags from the .tags file
      old_tags="$(cat $tags_file)"

      # Use gum filter to select tags (add any necessary options)
      selected_tags=$(gum filter --no-limit --no-strict <<< "$old_tags")
      for tag in $selected_tags; do
        found=false

        # Check if the selected tag is already in old_tags
        for line in $old_tags; do
          if [ "$tag" == "$line" ]; then
            found=true
            break
          fi
        done

        # If the tag is not found, append it to old_tags
        if [ "$found" == "false" ]; then
          echo "$tag" >> $tags_file
          do_loop=true
        fi
      done

      if [ "$do_loop" == "false" ]; then
        break
      fi
    done


    # Generate the tags string
    tags_string=$(\
      echo "$selected_tags" \
      | awk '{print "#"$0}' \
      | awk 'ORS=" "' \
      | sed 's/^# //' \
      | sed 's/ # $//')
    
    tags_string=${tags_string% }  # Remove the trailing space
    
    # Display truncated content and tags
    echo "| $trunc_temp"
    echo "> $tags_string"
    echo ""
    
    # Prompt for a title
    title=$(\
      gum input \
        --placeholder "$tags_string" \
        --header "Enter title (optional)"\
    )

    # Determine the filename with timestamp and title
    timestamp=$(date +"%Y%m%d_%H%M%S")

    # Check if title is empty, if not, use it, otherwise use tags
    if [ -n "$title" ]; then
      filename="$title"
    else
      filename="$tags"
    fi

    # Ensure the thoughts directory exists and move the file
    mkdir -p "$mainpath/"

    filepath="$mainpath/$filename.txt"
    # Create a new file with filename, append timestamp and tags
    touch "$filepath"

    echo "---------------" > "$filepath"
    echo "title : $title" >> "$filepath"
    echo "time  : $timestamp" >> "$filepath"
    echo "tags  : $tags_string" >> "$filepath"
    echo "---------------"  >> "$filepath"
    cat "$tempfile" >> "$filepath"

    # Remove the temporary file
    rm "$tempfile"

    # Exit alternate buffer
    echo -e "\033[?1049l"
}


# quick duckduckgo search with top 3 results only
# req: 
#   ddgr - https://github.com/jarun/ddgr
# 
# usage: d puppies near me

d () {
  # if disabled, do not bother running
  [[ ${load_functions[${FUNCNAME[0]}]} == false ]] && return
  local search_str="$*"
  ddgr -n 3 $search_str
}


# use octo's readability API-as-a-service for loading pages in term
# req:
#   html2md - https://github.com/suntong/html2md
# opt:
#   glow    - https://github.com/charmbracelet/glow
# 
# usage: slow https://catgirl.ai/log/comfy-software/

slow () {
  # if disabled, do not bother running
  [[ ${load_functions[${FUNCNAME[0]}]} == false ]] && return

  # TODO: add a .dev/raw/url so html2md is no longer necessary
  # TODO: add a .dev/md/url so html2md is no longer necessary
  local url=$(echo "$*" | tr ' ' '+')
  local prefix="https://slow.octoshrimpy.dev/"
  local full="$prefix$url"
  echo "$full"
  
  # able to pipe results to other apps
  # check if standard output is being redirected
  # TODO: default to less/more if no glow
  if [ -t 1 ]; then
    # Not being piped - run 'glow'
    html2md --in "$full" | glow -p -w 80
  else
    # Being piped - do not run 'glow'
    html2md --in "$full"
  fi
}


# yeet code into the cloud ʕノ•ᴥ•ʔノ📦
# req:
#   git - https://github.com/git-guides/install-git
# 
# usage: yeet this commit is :fire:

function yeet() {
  # if disabled, do not bother running
  [[ ${load_functions[${FUNCNAME[0]}]} == false ]] && return
  
  msg="$*"
  # if no changes, exit
  if ! git diff-index --quiet HEAD --; then
    git add .
    git commit -m "$msg"
    git push
  else
    echo "No changes to commit."
  fi
}


# yoink code from the cloud 📦 ⊂ʕ•ᴥ•⊂ʔ
# req:
#   git - https://github.com/git-guides/install-git

function yoink() {
  # find default branch
  branch=$(git remote show origin | awk '/HEAD branch/ {print $NF}')
  git checkout "$branch"
  git pull origin "$branch"
  git submodule update --recursive
}

# make missing dirs between "here" and "there.md", create "there.md"
# 
# usage: mkmd foo/bar/baz

function mkmd() {
  # if disabled, do not bother running
  [[ ${load_functions[${FUNCNAME[0]}]} == false ]] && return
  
  mkdir -p "$(dirname "$1")" &&
  touch "$1.md"
}

# make directory path if not exist, and cd into it
# 
# usage: mkcd foo/bar/baz

mkcd() {
  # if disabled, do not bother running
  [[ ${load_functions[${FUNCNAME[0]}]} == false ]] && return
  
  \cd "$@" 2> /dev/null;
  if [ $? -ne 0 ]; then
      read -p "Folder does not exist. Create it? (Y/n): " choice;
      case "$choice" in
          Y | y | "")
              mkdir -p "$1" && \cd "$1"
          ;;
          *)
              echo "Not changing directory."
          ;;
      esac;
  fi
}


# Two-phase filtering with Ripgrep and fzf
#
# 1. Search for text in files using Ripgrep
# 2. Interactively restart Ripgrep with reload action
#    * Press alt-enter to switch to fzf-only filtering
# 3. Open the file in micro
# req:
#   fzf     - https://github.com/junegunn/fzf
#   ripgrep - https://github.com/BurntSushi/ripgrep
# opt:
#   bat     - https://github.com/sharkdp/bat

function find() {
  # if disabled, do not bother running
  [[ ${load_functions[${FUNCNAME[0]}]} == false ]] && return

  # TODO: default to cat if no bat
  RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case "
  INITIAL_QUERY="${*:-}"
  : | fzf --ansi --disabled --query "$INITIAL_QUERY" \
      --bind "start:reload:$RG_PREFIX {q}" \
      --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
      --bind "alt-enter:unbind(change,alt-enter)+change-prompt(2. fzf> )+enable-search+clear-query" \
      --color "hl:-1:underline,hl+:-1:underline:reverse" \
      --prompt '1. ripgrep> ' \
      --delimiter : \
      --preview 'bat --color=always {1} --highlight-line {2}' \
      --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
      --bind 'enter:become(micro {1} +{2})'
}


# app launcher for arch (currently not working as wanted)
# req:
#   fzf - https://github.com/junegunn/fzf
#   yay - https://github.com/Jguer/yay

 launch() {
  # if disabled, do not bother running
  [[ ${load_functions[${FUNCNAME[0]}]} == false ]] && return

  # disable unless debugging
  [[ $DEBUG == false ]] && return
  
  yay -Q \
  | awk '{print $1}' \
  | fzf \
    --ansi --preview-window=wrap --preview \
      'yay -Qi {} \
      | awk -F": " "BEGIN {desc=\"\"; other=\"\"} /Name/ {name=\$2} /Version/ {version=\$2} /Description/ {desc=\$2; getline; while (\$1 ~ /^ /) {desc=desc \" \" \$1; getline}} {gsub(/  +/, \" \", desc)} {if(\$1!=\"\" && \$1!=\"Name\" && \$1!=\"Version\" && \$1!=\"Description\" && \$1 !~ /^ /) {other=other \"\033[1;34m\" \$1 \":\033[0m\" substr(\$0, length(\$1)+2) \"\\n\"} else if(\$1==\"\" || \$1 ~ /^ /) {other=other \$0 \"\\n\"}} END {printf \"\033[1;32m%s\033[0m \033[1;30m@ %s\033[0m\\n\\n%s\\n\\n%s\", name, version, desc, other}" \
      | awk "{gsub(/\[installed\]/, \"\\033[1;30m[installed]\\033[0m\"); print}"'
  
}


# attempt to gather info for any app, from any package manager

gather() {
  # TODO: setup disable toggle for this
  # if disabled, do not bother running
  [[ ${load_functions[${FUNCNAME[0]}]} == false ]] && return

  local app_name="$1"
  local found=0

  # Function to check and execute a package manager command if it hasn't already been found
  check_and_execute() {
    if [ "$found" -eq 0 ] && command -v "$1" &>/dev/null; then
      output=$("${@:2}" 2>&1)  # Execute the command with all arguments except the first
      if [[ $? -eq 0 && -n "$output" ]]; then
        echo "Found '$app_name' using $1:"
        echo "$output"
        found=1
      fi
    fi
  }

  # Attempt to gather info from various package managers
  check_and_execute dpkg dpkg -l | grep -i "$app_name"
  check_and_execute rpm rpm -qi "$app_name"
  check_and_execute yay yay -Qi "$app_name"
  check_and_execute pacman pacman -Qi "$app_name"
  check_and_execute flatpak flatpak info "$app_name"
  check_and_execute snap snap info "$app_name"
  check_and_execute brew brew info "$app_name"
  check_and_execute apt apt show "$app_name"

  # If the package was not found in package managers, search common directories
  if [ "$found" -eq 0 ]; then
    echo "Warning: Package manager commands did not find '$app_name'. Searching in common directories..."
    timeout 5 find /usr/bin /usr/local/bin /opt ~/ -type f -iname "$app_name" 2>/dev/null | while read -r line; do
      echo "Found in file system: $line"
      found=1
    done

    # If still not found, provide a final message
    if [ "$found" -eq 0 ]; then
      echo "Error: '$app_name' not found in package managers or common directories."
    fi
  fi
}


# reload current shell - sources fresh bashrc
src() {
  # TODO: setup disable toggle for this
  # if disabled, do not bother running
  [[ ${load_functions[${FUNCNAME[0]}]} == false ]] && return
  
  # source "$HOME/.bashrc"
  exec "$SHELL"
}


# Dumps command history to a file for later analysis.
# Accepts an argument specifying the number of days ago for which to dump the history.

dump_history() {
  # TODO: setup disable toggle for this
  # if disabled, do not bother running
  [[ ${load_functions[${FUNCNAME[0]}]} == false ]] && return
  
  # Append the current session's history to the history file.
  history -a

  # Number of days ago, default is 0 (today).
  local days_ago=${1:-0}

  # Get the date for the specified number of days ago in YYYY-MM-DD format.
  local target_date=$(date -d "$days_ago days ago" '+%Y-%m-%d')

  # File to which the history will be appended.
  local history_file="$HOME/.history_$target_date.txt"

  # If the file already exists, delete it.
  if [ -f "$history_file" ]; then
    rm "$history_file"
  fi

  # Write filename at the top.
  echo "==== $history_file ====" >> $history_file

  # Filter history by target date.
  history | grep "$target_date" > /tmp/filtered_history.txt

  # Initialize index for each session.
  local index=0

  # Process filtered history and append to history file.
  awk -F" " -v session_gap=900 -v file="$history_file" -v idx="$index" '
    BEGIN { prev_time = 0; sessions = 0; print "---- session start ----" >> file; }
    {
      # Format the command index, time and command itself.
      print "[" idx++ "] " $3 " " substr($0, index($0, $4)) >> file;

      # Convert the timestamp to seconds since midnight.
      split($3, time, ":");
      current_time = time[1] * 3600 + time[2] * 60 + time[3];

      # Check if a new session should start.
      if (current_time - prev_time > session_gap) {
        print "---- session end ----" >> file;
        print "---- session start ----" >> file;
        idx = 0;
        sessions++;
      }
      
      # Update prev_time for the next iteration.
      prev_time = current_time;
    }
  ' /tmp/filtered_history.txt

  # Correctly count the number of commands from the history file itself.
  commands=$(wc -l < "$history_file")

  # Count the number of sessions from the history file.
  sessions=$(grep -c '---- session start ----' "$history_file")

  # Print the filename on a new line.
  echo "$history_file"

  # Print the session and command counts.
  echo "$(tput setaf 2)$commands$(tput sgr0) commands across $(tput setaf 2)$sessions$(tput sgr0) sessions"

  # Clean up the temporary filtered history file.
  rm /tmp/filtered_history.txt
}


# speak the given text as argument, piped-in text, or filepath
# req:
#   piper - https://github.com/rhasspy/piper
# 
# usage: speak hello world

function speak() {
  # TODO: setup disable toggle for this
  # if disabled, do not bother running
  [[ ${load_functions[${FUNCNAME[0]}]} == false ]] && return
  
  local input

  # Check if data is being piped in
  if [ -t 0 ]; then
    # No pipe, use arguments
    input="$*"
  else
    # Data is being piped in, read from standard input
    input=$(cat)
  fi

  # Check if the input is a file and its extension is .md or .txt
  if [[ -f "$input" && ( "$input" == *.md || "$input" == *.txt ) ]]; then
    # Read the file content
    input=$(cat "$input")
  fi
  
  # Pass the text to piper-tts and play the output using aplay
  echo "$input" \
  | piper-tts --model ~/tools/piper_tts/en_US-ryan-high.onnx --output-raw \
  | aplay -r 22050 -f S16_LE -t raw -
}


# better touch, creates folder paths as necessary
function smart_touch() {
  # TODO: setup disable toggle for this
  local filepath="$1"
  local dirpath=$(dirname "$filepath")

  # Create directory path if it does not exist
  if [ ! -d "$dirpath" ]; then
      mkdir -p "$dirpath"
  fi

  # Use the built-in touch command to create or update the file's timestamp
  command touch "$filepath"
}


# view commits from current git repo
# req:
#   git - https://github.com/git-guides/install-git

gmit() {
  # TODO: setup disable toggle for this
  _glog='GIT_PAGER= git log --format="%C(yellow italic)%ad%C(reset) %s %C(black)%h%C(reset)" --date=short'

  _slog='GIT_PAGER= git log --format="%C(black italic)%y %C(white italic)%m %C(yellow italic)%d %C(reset) %s %C(black)%h%C(reset)" --date=short'
  commits=$(eval $_glog)

  selected_commit=$(echo "$commits" | fzf --ansi --no-sort --preview "echo {} | awk '{print \$NF}' | xargs -I % sh -c 'git show --color=always %'" --preview-window=right:40%)

  # If a commit is selected, show the diff
  if [ -n "$selected_commit" ]; then
    commit_hash=$(echo "$selected_commit" | awk '{print $NF}')
    git diff "$commit_hash^" "$commit_hash"
  else
    echo "No commit selected."
  fi
}

# Install packages using yay (change to pacman/AUR helper of your choice)
function install() {
  # TODO: setup disable toggle for this
    yay -Slq | fzf -q "$1" -m --preview 'yay -Si {1}'| xargs -ro yay -S
}

# Remove installed packages (change to pacman/AUR helper of your choice)
function remove() {
  # TODO: setup disable toggle for this
    yay -Qq | fzf -q "$1" -m --preview 'yay -Qi {1}' | xargs -ro yay -Rns
}

# use fzf to search through terminal history
# req:
#   fzf - https://github.com/junegunn/fzf
__fzf_history {
  # TODO: setup disable toggle for this 
  __ehc $(history | fzf --tac --tiebreak=index | perl -ne 'm/^\s*([0-9]+)/ and print "!$1"')
}

__ehc {
  # TODO: setup disable toggle for this
  if [[ -n $1 ]]; then
    bind '"\er": redraw-current-line'
    bind '"\e^": magic-space'
    READLINE_LINE=${READLINE_LINE:+${READLINE_LINE:0:READLINE_POINT}}${1}${READLINE_LINE:+${READLINE_LINE:READLINE_POINT}}
    READLINE_POINT=$(( READLINE_POINT + ${#1} ))
  else
    bind '"\er":'
    bind '"\e^":'
  fi
}

# TODO clean up below
# requires: 
#   fzf
#   man
#   bat (or replace all instances of bat with cat below)
export MANPAGER="sh -c 'col -bx | bat -l man -p --paging always'"
help() {
    man -k . | fzf -q "$1" --prompt='man> '  --preview $'echo {} | tr -d \'()\' | awk \'{printf "%s ", $2} {print $1}\' | xargs -r man | col -bx | bat -l man -p --color always' | tr -d '()' | awk '{printf "%s ", $2} {print $1}' | xargs -r man
}

# -- setup rpg-cli --------------------------------------------------
# 
# req:
#   rpg-cli   - https://github.com/facundoolano/rpg-cli

function setup_rpg() {
  # if disabled, do not bother running
  [[ ${load_functions[${FUNCNAME[0]}]} == false ]] && return
  
  # format_rpg_text function:
  # 0. Remove anything after and including @
  # 1. Replace all '╌' with gray '╌'
  # 2. Replace all '[' and ']' with gray versions
  # 3. Replace the first 'x' with a red '━'
  # 4. Replace all other characters with bright green versions
  
  function setup_rpg.format_rpg_text() {
    counter=0
    output_parts=""
    rpg -q | sed 's/@.*//; s/]\[/\n/g; s/x/═/g ; s/-/╌/g' \
    | while IFS= read -r part; do
      ((counter++))
      if [ "$counter" -eq 2 ]; then
        # Colorize '═' in green for Part 2
        colored_part=$(echo "$part" | sed 's/═/\'$(tput setaf 2)'&\'$(tput sgr0)'/g')
        colored_part=$(echo "$colored_part" | sed 's/╌/\'$(tput setaf 0)'&\'$(tput sgr0)'/g')
        colored_part+="]["
      elif [ "$counter" -eq 3 ]; then
        # Colorize '═' in blue for Part 3
        colored_part=$(echo "$part" | sed 's/═/\'$(tput setaf 4)'&\'$(tput sgr0)'/g')
        colored_part=$(echo "$colored_part" | sed 's/╌/\'$(tput setaf 0)'&\'$(tput sgr0)'/g')
        colored_part+="]["
  
      elif [ "$counter" -eq 4 ]; then
        # Colorize '═' in orange for Part 4
        colored_part=$(echo "$part" | sed 's/═/\'$(tput setaf 3)'&\'$(tput sgr0)'/g')
        colored_part=$(echo "$colored_part" | sed 's/╌/\'$(tput setaf 0)'&\'$(tput sgr0)'/g')
  
      else
        colored_part=$(echo "$part")
        colored_part+="]["
      fi
  
      # last minute color replace
      colored_part=$(echo "$colored_part" | awk '
      BEGIN {
        gray_code="\033[90m";
        reset_code="\033[0m";
      }
  
      {
        len = length($0);
        in_escape = 0;
        for (i = 1; i <= len; ++i) {
          char = substr($0, i, 1);
          if (in_escape) {
            if (char == "m") {
              in_escape = 0;
            }
          } else {
            if (char == "\033") {
              in_escape = 1;
            }
          }
          
          if (in_escape || (char != "[" && char != "]")) {
            printf "%s", char;
          } else {
            printf "%s%s%s", gray_code, char, reset_code;
          }
        }
        printf "\n";
      }')
      printf '%s' "$colored_part"
    done
  
  }
  
  # count printable chars, ignore color codes in strings
  function setup_rpg.count_printable_chars() {
    local str="$1"
    local clean_str=$(echo -n "$str" | sed 's/\x1b\[[^a-zA-Z]*[a-zA-Z]//g')
    echo ${#clean_str}
  }
  
  # calculate how much space is left, for right-aligned text
  function setup_rpg.calc_space() {
    FORMATTED_RPG=$(setup_rpg.format_rpg_text)
    FORMATTED_RPG_LEN=$(setup_rpg.count_printable_chars $FORMATTED_RPG)
    length=$(( $COLUMNS - $FORMATTED_RPG_LEN + 10))
    PS1_SPACES=$(printf '%*s' $length "")
  }

  
  # shorter command
  function setup_rpg.rpg () {
      rpg-cli "$@"
      sync_rpg
  }
  
  # casual rpg cd, fight on arrival only
  function setup_rpg.__cd () {
      __mkcd "$@"
      rpg-cli cd -f .
      rpg-cli battle
  }
  
  # full rpg cd override
  # Try to move the hero to the given destination, and cd match the shell pwd
  # to that of the hero's location:
  # - the one supplied as parameter, if there weren't any battles
  # - the one where the battle took place, if the hero wins
  # - the home dir, if the hero dies
  #
  # cd () {
  #     rpg-cli cd "$@"
  #     builtin cd "$(rpg-cli pwd)"
  # }
  
  # look for loot
  function setup_rpg.__ls () {
      command ls --color=auto "$@"
      if [ $# -eq 0 ] ; then
          setup_rpg.rpg cd -f .
          setup_rpg.rpg ls
      fi
  }
  
  # auto-explore for battles and items
  function setup_rpg.dn () {
      current=$(basename $PWD)
      number_re='^[0-9]+$'
  
      if [[ $current =~ $number_re ]]; then
          next=$(($current + 1))
          command mkdir -p $next && cd $next && rpg ls
      elif [[ -d 1 ]] ; then
          cd 1 && rpg ls
      else
          command mkdir -p dungeon/1 && cd dungeon/1 && rpg ls
      fi
  }
  
  # helper used to make pwd match the internal path
  function setup_rpg.sync_rpg () {
      builtin cd "$($RPG pwd)"
  }
  
  # battle in current pwd
  function setup_rpg.rpg-battle () {
    current=$PWD
    message="nothing to fight"
    clear
  
  #   __rpg-print-stats
  # 
  #   while true; do
  #     __rpg-fight-here
  #     __rpg-go-home
  #     __rpg-go-back
  #   done
  #   
  
    while true; do
      output=$(setup_rpg.rpg battle)
      if [ -z "$output" ];then
        echo -ne "\r$message$(printf '%*s' $((cols - ${#message})))"
      else
        clear
        echo $(setup_rpg.format_rpg_text)
        echo -e "\n"
        echo -e "$output"
        sleep 2
        output=$(setup_rpg.__cd ~)
        if [ -z "$output" ];then
          clear
          echo $(setup_rpg.format_rpg_text)
        fi
        setup_rpg.__cd ~ > /dev/null
        setup_rpg.rpg ls
        echo -e "home, resting"
        echo $(setup_rpg.format_rpg_text)
        echo -e "\n"
        sleep 2
        setup_rpg.__cd $current
        echo -e ""
        rpg ls
        echo $(setup_rpg.format_rpg_text)
        echo -e "\n"
        sleep 2
        clear
      fi
    done
  }
  
  alias cd=setup_rpg.__cd
  alias ls=setup_rpg.__ls
  
  # only modify files if battle succeeds
  alias rm="setup_rpg.rpg battle && rm"
  alias rmdir="setup_rpg.rpg battle && rmdir"
  alias mkdir="setup_rpg.rpg battle && mkdir"
  alias touch="setup_rpg.rpg battle && touch"
  alias mv="setup_rpg.rpg battle && mv"
  alias cp="setup_rpg.rpg battle && cp"
  alias chown="setup_rpg.rpg battle && chown"
  alias chmod="setup_rpg.rpg battle && chmod"
  
  
}

# -- aliases --------------------------------------------------------

alias l=ls
alias clera='clear'
alias bashrc="m ~/.bashrc"
alias pls='sudo "$BASH" -c "$(history -p !!)"'
alias poke='smart_touch'

# requires micro editor - https://micro-editor.github.io
alias m="micro"
alias mm='fzf --ansi --bind "enter:become(micro {})" --preview "bat --color=always {}" --query "$*"'

# opens a file
alias open='fzf --ansi --bind "enter:become(xdg-open {} &>1 >2)"'

# requires jqp
#   https://github.com/noahgorstein/jqp
alias jj='fzf --ansi --bind "enter:become(jqp -f {})" --preview "bat --color=always {}"'

# git aliases
alias gdif='git diff'


# -- hotkeys --------------------------------------------------------

# ctrl-R to fzf-search on history
bind '"\C-r": "\C-x1\e^\er"'
bind -x '"\C-x1": __fzf_history';

# fzf tab autocompletion
# req:
#   fzf     - https://github.com/junegunn/fzf
#   script  - https://github.com/lincheney/fzf-tab-completion
source /home/octoshrimpy/.config/bash-fzf-autocompletion.sh
bind -x '"\t": fzf_bash_completion'

# -- PS1 ------------------------------------------------------------

# https://jon.sprig.gs/blog/post/1940
. /usr/share/git/completion/git-prompt.sh
GIT_PS1_DESCRIBE_STYLE='contains'
GIT_PS1_SHOWCOLORHINTS='y'
GIT_PS1_SHOWDIRTYSTATE='y'
GIT_PS1_SHOWSTASHSTATE='y'
GIT_PS1_SHOWUNTRACKEDFILES='y'
GIT_PS1_SHOWUPSTREAM='auto'

ps1_text="$USER in $PWD"

PS1 = ""

# if disabled, do not bother running
if [[ ${load_functions["setup_rpg"]} == true ]]; then
   
  # requires rpg-cli - https://github.com/facundoolano/rpg-cli
  rpg_text=$(rpg-cli -q | sed 's/@.*//' | sed 'y/-x/╌━/')
  length=$(( ${#ps1_text} - ${#rpg_text} ))

  PROMPT_COMMAND="setup_rpg.calc_space"

  PS1+="\$PS1_SPACES"
  PS1+="\$FORMATTED_RPG"
  PS1+="\n"
fi

PS1+="╭ "
PS1+="\[\e[35m\]\[\e[95m\]\u"
PS1+="\[\e[35m\]\[\e[90m\] in "
PS1+="\[\e[92;1;3m\]\$(echo \$PWD | awk -v home=\$HOME 'BEGIN{FS=home;OFS=\"~\"} {if (\$1 == \"\") \$1=\"\"; print \$0}')/ "
PS1+="\[\e[0;36m\]\$(__git_ps1) "
PS1+="\n\[\e[0m\]└❱ "


