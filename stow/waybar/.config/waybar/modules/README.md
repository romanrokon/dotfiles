# Waybar custom modules

Linux counterparts of the macOS SwiftBar plugins. Add to your `~/.config/waybar/config.jsonc`:

```jsonc
{
  // ...
  "modules-right": [
    "custom/sysmon",
    "custom/disk",
    "custom/aria2",
    "custom/pihole",
    "tray",
    "clock"
  ],

  "custom/aria2": {
    "exec": "~/.config/waybar/modules/aria2.sh",
    "return-type": "json",
    "interval": 5,
    "on-click": "xdg-open https://ariang.mayswind.net/latest/"
  },
  "custom/pihole": {
    "exec": "~/.config/waybar/modules/pihole.sh",
    "return-type": "json",
    "interval": 30,
    "on-click": "xdg-open http://$PIHOLE_IP/admin"
  },
  "custom/disk": {
    "exec": "~/.config/waybar/modules/disk.sh",
    "return-type": "json",
    "interval": 60,
    "on-click": "xdg-open ~"
  },
  "custom/sysmon": {
    "exec": "~/.config/waybar/modules/sysmon.sh",
    "return-type": "json",
    "interval": 5,
    "on-click": "ghostty -e btop"
  }
}
```

Style classes (`ok`, `warn`, `error`, `off`, `idle`, `active`) — add to `~/.config/waybar/style.css`:

```css
#custom-aria2.active,
#custom-pihole.ok,
#custom-disk.ok,
#custom-sysmon.ok { color: #a6e3a1; }

#custom-aria2.off,
#custom-pihole.off { color: #6c7086; }

#custom-pihole.warn,
#custom-disk.warn,
#custom-sysmon.warn { color: #fab387; }

#custom-pihole.error,
#custom-disk.error,
#custom-sysmon.error { color: #f38ba8; }
```

Edit `disk.sh` `VOLUMES=(...)` to match your mount layout. Defaults to `/`, `/home`, `/mnt/work`.

## Pi-hole config (private)

`pihole.sh` reads `~/.config/dotfiles/pihole.env`:

```sh
PIHOLE_IP=100.x.x.x
PIHOLE_HOST=name.tailnet.ts.net
```

Keep this file in your private dotfiles repo, not the public one — it leaks tailnet identifiers.
