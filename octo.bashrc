export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTTIMEFORMAT="%d/%m/%y %T "



# -- functions --------------


# quickly jot down ideas from anywhere
# req:
#   gum     - https://github.com/charmbracelet/gum
idea() {
    
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
    tags_string=$(echo "$selected_tags" | awk '{print "#"$0}' | awk 'ORS=" "' | sed 's/^# //' | sed 's/ # $//')
    
    tags_string=${tags_string% }  # Remove the trailing space
    
    # Display truncated content and tags
    echo "| $trunc_temp"
    echo "> $tags_string"
    echo ""
    
    # Prompt for a title
    title=$(gum input --placeholder "$tags_string" --header "Enter title (optional)")

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
    # Create a new file with the filename and append timestamp and tags
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


# quick single-reply duckduckgo search
# req: 
#   ddgr - https://github.com/jarun/ddgr
d () {
  local search_str="$*"
  ddgr -n 3 $search_str
}

# use my own readability API-as-a-service for loading pages in term
# req:
#   html2md - https://github.com/suntong/html2md
#   glow    - https://github.com/charmbracelet/glow
slow () {
  local url=$(echo "$*" | tr ' ' '+')
  local prefix="https://slow.octoshrimpy.dev/"
  local full="$prefix$url"
  echo "$full"
  
  # able to pipe results to other apps
  # check if standard output is being redirected
  if [ -t 1 ]; then
    # Not being piped - run 'glow'
    html2md --in "$full" | glow -p -w 80
  else
    # Being piped - do not run 'glow'
    html2md --in "$full"
  fi
}

# yeet code into the cloud ʕノ•ᴥ•ʔノ
# req:
#   git - https://github.com/git-guides/install-git
function yeet() {
    git add .
    git commit -a -m "$*"
    git push
}

# make missing directories between "here" and "there.md", create "there.md"
function mkmd() {
  mkdir -p "$(dirname "$1")" &&
  touch "$1.md"
}

# make directory path if not exist, and cd into it
mkcd() {
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


# format_rpg_text function:
# 0. Remove anything after and including @
# 1. Replace all '╌' with gray '╌'
# 2. Replace all '[' and ']' with gray versions
# 3. Replace the first 'x' with a red '━'
# 4. Replace all other characters with bright green versions

format_rpg_text() {
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
count_printable_chars() {
  local str="$1"
  local clean_str=$(echo -n "$str" | sed 's/\x1b\[[^a-zA-Z]*[a-zA-Z]//g')
  echo ${#clean_str}
}

# calculate how much space is left, for right-aligned text
calc_space() {
  FORMATTED_RPG=$(format_rpg_text)
  FORMATTED_RPG_LEN=$(count_printable_chars $FORMATTED_RPG)
  length=$(( $COLUMNS - $FORMATTED_RPG_LEN + 10))
  PS1_SPACES=$(printf '%*s' $length "")
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
function find() {
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
  local app_name="$1"
  local found=0

  # Function to check and execute a package manager command if it hasn't already been found
  check_and_execute() {
    if [ "$found" -eq 0 ] && command -v "$1" &>/dev/null; then
      output=$("$@" 2>&1)  # Capture both stdout and stderr
      if [[ $? -eq 0 ]]; then
        echo "$output"
        found=1
        echo "found with $1"
      fi
    fi
  }

  check_and_execute dpkg -l | grep -i "$app_name"
  check_and_execute rpm -qi "$app_name"
  check_and_execute yay -Qi "$app_name"
  check_and_execute flatpak info "$app_name"
  check_and_execute snap info "$app_name"

  # Check if none of the package manager commands were found
  if [ "$found" -eq 0 ]; then
    echo "Warning: Package manager commands (dpkg, rpm, yay, snap, or flatpak) not found. Searching in common directories only."
    # Search for the application in common directories with a timeout
    timeout 5 find /usr/bin -type f -iname "$app_name" 2>/dev/null || true
    timeout 5 find /usr/local/bin -type f -iname "$app_name" 2>/dev/null || true
    timeout 5 find /opt -type f -iname "$app_name" 2>/dev/null || true
    timeout 5 find ~/ -type f -iname "$app_name" 2>/dev/null || true
  fi
}

# reload bash with a newly updated bashrc
src() {
  source "$HOME/.bashrc"
}


# Dumps command history to a file for later analysis.
# Accepts an argument specifying the number of days ago for which to dump the history.

dump_history() {
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


# text as argument, pipe in text, or pass it a file
# req:
#   piper - https://github.com/rhasspy/piper
function speak() {
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


# -- rpg-cli --------------

# shorter command
rpg () {
    rpg-cli "$@"
    sync_rpg
}

# casual rpg cd, fight on arrival only
__cd () {
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
__ls () {
    command ls --color=auto "$@"
    if [ $# -eq 0 ] ; then
        rpg cd -f .
        rpg ls
    fi
}

# auto-explore for battles and items
dn () {
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
sync_rpg () {
    builtin cd "$($RPG pwd)"
}

# battle in current pwd
rpg-battle () {
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
    output=$(rpg battle)
    if [ -z "$output" ];then
      echo -ne "\r$message$(printf '%*s' $((cols - ${#message})))"
    else
      clear
      echo $(format_rpg_text)
      echo -e "\n"
      echo -e "$output"
      sleep 2
      output=$(__cd ~)
      if [ -z "$output" ];then
        clear
        echo $(format_rpg_text)
      fi
      __cd ~ > /dev/null
      rpg ls
      echo -e "home, resting"
      echo $(format_rpg_text)
      echo -e "\n"
      sleep 2
      __cd $current
      echo -e ""
      rpg ls
      echo $(format_rpg_text)
      echo -e "\n"
      sleep 2
      clear
    fi
  done
}

alias cd=__cd
alias ls=__ls

# only modify files if battle succeeds
alias rm="rpg battle && rm"
alias rmdir="rpg battle && rmdir"
alias mkdir="rpg battle && mkdir"
alias touch="rpg battle && touch"
alias mv="rpg battle && mv"
alias cp="rpg battle && cp"
alias chown="rpg battle && chown"
alias chmod="rpg battle && chmod"


# -- aliases --------------

alias l=ls
alias clera='clear'
alias pls='sudo "$BASH" -c "$(history -p !!)"'
alias m="micro"
# requires micro editor - https://micro-editor.github.io
alias mm='fzf --ansi --bind "enter:become(micro {})" --preview "bat --color=always {}"'



# -- PS1 --------------

# https://jon.sprig.gs/blog/post/1940
. /usr/share/git/completion/git-prompt.sh
GIT_PS1_DESCRIBE_STYLE='contains'
GIT_PS1_SHOWCOLORHINTS='y'
GIT_PS1_SHOWDIRTYSTATE='y'
GIT_PS1_SHOWSTASHSTATE='y'
GIT_PS1_SHOWUNTRACKEDFILES='y'
GIT_PS1_SHOWUPSTREAM='auto'

ps1_text="$USER in $PWD"

# requires rpg-cli - https://github.com/facundoolano/rpg-cli
rpg_text=$(rpg-cli -q | sed 's/@.*//' | sed 'y/-x/╌━/')
length=$(( ${#ps1_text} - ${#rpg_text} ))

PROMPT_COMMAND="calc_space"

PS1="\$PS1_SPACES"
PS1+="\$FORMATTED_RPG"
PS1+="\n╭ "
PS1+="\[\e[35m\]\[\e[95m\]\u"
PS1+="\[\e[35m\]\[\e[90m\] in "
PS1+="\[\e[92;1;3m\]\$(echo \$PWD | awk -v home=\$HOME 'BEGIN{FS=home;OFS=\"~\"} {if (\$1 == \"\") \$1=\"\"; print \$0}')/ "
PS1+="\[\e[0;36m\]\$(__git_ps1) "
PS1+="\n\[\e[0m\]└❱ "


