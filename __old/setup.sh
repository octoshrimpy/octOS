#!/usr/bin/bash


os_dir = "$HOME/.8os"



# check internet connection
os_hasnet=$(curl -sSf https://github.com > /dev/null && echo "1" || echo "0")

# check if previously installed
os_exists=$( [ -d "$os_dir" ] && echo "1" || echo "0" )

if [ $os_exists -eq 1 ]; then
  echo "found installation, reusing folder"
else
  mkdir -p $HOME/.8os/{temp,config}
fi


# ----------- font
# https://web.archive.org/web/20231105222400/https://phoikoi.io/2016/11/09/powerline-console.html

# setup terminus font
# TODO check var or flag for "use powerline symbols"
if [ $os_hasnet -eq 1 ]; then

  git clone https://github.com/powerline/fonts $os_dir/temp/powerline-fonts
  cp -r $os_dir/temp/powerline-fonts/Terminus/PSF/*.psf.gz /usr/share/consolefonts

  # backup /etc/default/console-setup
  sudo cp /etc/default/console-setup /etc/default/console-setup.8os.bak
  
  # apply font to /etc/default/console-setup  
  sed -i \
    -e '/^CODESET=/s/^/#/' \
    -e '/^FONTFACE=/s/^/#/' \
    -e '/^FONTSIZE=/s/^/#/' \
    -e '/^VIDEOMODE=/a\FONT="ter-powerline-v32b.psf.gz"' \
    /etc/default/console-setup


    
    # setup grub gfx mode
    sudo cp /etc/default.grub /etc/default.grub.8os.bak
    echo "GRUB_GFXMODE=1024x768x16" >> /etc/default.grub
    echo "GRUB_GFXPAYLOAD_LINUX=keep" >> /etc/default.grub

    sudo update-grub
fi



