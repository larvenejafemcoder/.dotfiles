

## ✂️ Humanized README (you can paste this over yours)

````md
# KernelGhost’s terminal dotfiles

Minimal-ish dotfiles for terminal setups on **Arch / Ubuntu / Debian**  
(mainly GNOME, because yeah)

This repo is kinda empty right now, but the structure + installer are here.
I mostly use this to avoid redoing my terminal setup every time I reinstall Linux.

Stuff I care about:
- Zsh
- Alacritty
- GNOME Terminal
- not spending 3 hours reconfiguring fonts again

---

## What’s in here (or will be)

- Zsh config (oh-my-zsh, plugins, aliases, usual stuff)
- Alacritty config (nerd font, opacity, nothing fancy)
- GNOME Terminal profile backup via `dconf`
- A basic install script so I can just run one command and chill

Not claiming this is optimal or clean.  
It just works *for me*.

---

## Install (quick and dirty)

```bash
git clone https://github.com/larvenejafemcoder/terminal_dotfiles.git
cd terminal_dotfiles
chmod +x install.sh
./install.sh
````

If something breaks, that’s on you (and future me).

---

## Requirements

Install these first or the script will obviously complain.

### Arch-based

```bash
sudo pacman -S zsh curl alacritty dconf
```

### Ubuntu / Debian

```bash
sudo apt install zsh curl alacritty dconf-cli
```

---

## Repo layout (roughly)

```text
terminal_dotfiles/
├── alacritty/          # Alacritty config
├── gnome-terminal/     # dconf export
├── zsh/
│   ├── .zshrc
│   └── aliases.zsh
├── fonts/              # font files / scripts (location might change)
├── install.sh
├── README.md
└── LICENSE
```

This might change. I reorganize stuff a lot.

---

## GNOME Terminal backup / restore

Export:

```bash
dconf dump /org/gnome/terminal/ > gnome-terminal/gnome-terminal.dconf
```

Restore:

```bash
dconf load /org/gnome/terminal/ < gnome-terminal/gnome-terminal.dconf
```

Saved my ass more than once.

---

## Git basics (mostly for myself)

```bash
git add .
git commit -m "random tweaks"
git push
```

Or just don’t push. That’s also valid.

---

## Notes

* Repo is **English-only** for now
* Might add Vietnamese comments later, might not
* Feel free to fork it, break it, or steal parts of it

If you find something cursed, open an issue or just laugh at me.

---

MIT License
Do whatever, just don’t pretend you wrote it 😤

```



Say the word.
```
