# NetScore Golf

A lightweight Garmin Connect IQ app for recording golf scores and calculating
Stableford points on your watch. It does not use GPS or location services.

## Features

- Play 9-hole or 18-hole rounds.
- Configure up to 10 courses, with up to 4 loops per course.
- Combine two 9-hole loops into an 18-hole round, or use a single 18-hole loop.
- Set the playing handicap for each round.
- Adjust strokes with the touchscreen or watch buttons; swipe or tap to change
  holes.
- Resume an in-progress round after leaving the app.
- See gross strokes, net strokes, and Stableford points after finishing the
  round.

## Configure courses

Open the app's settings in Garmin Connect and enter a course name and one or
more loops. Leave unused course and loop fields blank.

The course selector reloads settings when they are delivered to the app. If
the app is already open after saving settings, tap the screen (or press
Select on **RELOAD**) to check for updated settings without reopening it.

Each loop uses this format:

```text
Loop name|par-index,par-index,...
```

For example, a 9-hole loop with par 4 on every hole and handicap indexes 1–9:

```text
Red|4-01,4-02,4-03,4-04,4-05,4-06,4-07,4-08,4-09
```

Each loop must contain exactly 9 or 18 holes. Par must be 3, 4, or 5, and
handicap indexes must be unique and cover the full range from 1 to 9 or 1 to
18. Loop names cannot contain `|`.

On the watch, choose the course and round length, then select the loop or
loops. For an 18-hole round made from two 9-hole loops, the first selected
loop is holes 1–9 and the second is holes 10–18. Clubs with a single
18-hole loop can use it directly.

## Play a round

Set the playing handicap (PHCP) before starting. Adjust the gross strokes for
each hole with the on-screen controls or the watch's up/down buttons. Swipe
left or tap **NEXT** to advance; swipe right or tap **PREV** to go back.
Press the Action/Select button to confirm ending the round early. Press Back
on the confirmation prompt to return to the round; Back during the round does
not navigate to another hole or exit the round.

The app saves the current hole and scores locally as you play. Gross strokes,
net strokes, and Stableford points are calculated on the watch and shown on
the final summary screen.

## Build

Install the Garmin Connect IQ SDK and provide a developer key. Build for a
supported device with the SDK's `monkeyc` compiler, using `monkey.jungle` as
the project file. For example:

```sh
monkeyc -d venu2 -f monkey.jungle -o bin/netscoregolf.prg -y /path/to/developer_key
```

Supported device targets are listed in [manifest.xml](manifest.xml). Build
outputs and local developer keys are not part of the source repository.

## Connect IQ Store images

Store-ready images are in [store-assets](store-assets/):

- [Hero image](store-assets/hero-redesigned-banner.png) — 1440 × 720, dark teal
  and mint palette.
- [Cover image](store-assets/cover-image-500x500.png) — 500 × 500, using the
  project launcher icon; under the 300 KB limit.
- [64-color device icon](store-assets/device-icon-64-color-128x128.png) and
  [24-bit device icon](store-assets/device-icon-24-bit-128x128.png) — both
  128 × 128.

The original launcher icon remains at
[resources/drawables/icon.png](resources/drawables/icon.png).
