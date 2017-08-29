# zsh themes

Fork of the fishy theme found in oh-my-zsh, with much of the extraneous stuff
cut out. Loads much faster.

Also includes a battery gauge and git display that can be added to the right
prompt.


## Installation 

### Manual

Clone this repo and source fishy.zsh in your zshrc, e.g.:
```
source /path/to/zsh-themes/fishy.zsh
```

To enable the battery gauge or git prompt, source battery-gauge.zsh and
git-prompt.zsh, respectively.


### Antigen

Antigen compatibility is provided by the symlinks in the plugins/ and themes/
directories. Add the following to your zshrc to enable the custom fishy theme:
```
antigen theme pseudorook/zsh-themes themes/fishy
```

To add the battery gauge and git prompt:
```
antigen bundle pseudorook/zsh-themes plugins/git
antigen bundle pseudorook/zsh-themes plugins/battery
```
