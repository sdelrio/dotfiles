
# https://support.system76.com/articles/kernelstub/
# https://unix.stackexchange.com/questions/554908/disable-spectre-and-meltdown-mitigations
#sudo kernelstub -a "mitigations=off"

sudo apt -y install zsh wl-clipboard

[ $SHELL = /bin/zsh ] || chsh -s /usr/bin/zsh $USER

