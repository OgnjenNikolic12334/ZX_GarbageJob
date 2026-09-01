# 🚛 ZX-GarbageJob

A lightweight and configurable **FiveM Garbage Collector Job** with random routes, garbage collection, animations, vehicle interaction and configurable payments.

## ✨ Features

- 🚛 Garbage truck job
- 👷 Employer NPC with animations
- 🗺️ Random garbage routes
- 🗑️ Multiple garbage/dumpster models
- 🎬 Pickup, carry and throw animations
- 📍 Blips, route zones and markers
- 💰 Configurable payment system
- 🎯 `ox_target`, `qb-target` and `textUI` support
- ⚙️ Fully configurable
- 🌐 Localization support
- ⚡ Lightweight and optimized

## 📦 Requirements

- [ZX_Core](https://github.com/OgnjenNikolic12334/ZX_Core)
- `ox_target` *(optional)*
- `qb-target` *(optional)*

> `ox_target` and `qb-target` are not required when using `textUI`.

## 🔧 Installation

1. Download `ZX-GarbageJob`
2. Place it inside your server's `resources` folder
3. Make sure `ZX_Core` is started before the job
4. Add the following to your `server.cfg`:

```cfg
ensure ZX_Core
ensure ZX-GarbageJob
Configure the resource through config.lua

```

⚙️ Configuration

You can configure:

Interaction system
Employer location and NPC
Garbage truck
Truck capacity
Garbage models
Routes and route locations
Payment amount and item
Blips and markers
Animations
Disabled actions
Localization
Interaction
Config.Settings.Interaction.type = "textUi"

Available:

textUi
ox_target
qb-target
💰 Payment

Payment is configured per route:
```
Rework = {
    item = "money_item",
    caunt = 15
}
```
The player receives payment after returning the garbage truck to the station.

## 🗺️ Routes

Routes can easily be added or removed through config.lua:
```
Config.Routes = {
    {
        Zone = {
            coords = vector3(-104.9505, -1416.2239, 29.7637),
            distance = 150.0
        },
        Rework = {
            item = "money_item",
            caunt = 15
        }
    }
}
```
## 🧩 ZX_Core

ZX-GarbageJob requires ZX_Core.

ZX_Core is used for core functionality such as:

Blips
Markers
Notifications
Item rewards
📞 Contact

Discord: oggiissa
Instagram: @ognjen.n

<p align="center"> Made with ❤️ by Ognjen </p> 
