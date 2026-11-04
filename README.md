# NetScore Golf

A lightweight Garmin Connect IQ app for recording golf scores and calculating
Stableford points on your watch. It does not use GPS or location services.

## Features

- Play 9-hole or 18-hole rounds.
- Configure up to 10 courses, with up to 4 loops per course.
- Combine two 9-hole loops into an 18-hole round, or use a single 18-hole loop.
- Set the playing handicap for each round; the last value is remembered.
- Plus handicaps are supported and apply deductions on the highest-index holes.
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

Each course can have up to four loops. Enter each loop in its own Loop A–D
setting. Use the format that matches the loop:

```text
18-hole loop: Loop name|par-index,par-index,...
Standalone 9-hole loop: Loop name|par-index,par-index,...
9-hole loop for combinations: Loop name|par-OUT_index-IN_index,...
```

Separate holes with commas. The numbers before the first hyphen are the par.
For a combination loop, the second number is that hole's published OUT index
and the third is its published IN index. For example, `4-1-2` means par 4,
OUT index 1, IN index 2. Indexes can be written with or without leading zeroes:
`5` and `05` are equivalent. Garmin Connect may remove leading zeroes when it
saves settings.

The Blue indexes you provided are enough to play that loop as a standalone
9-hole round:

```text
Karlstad GK
Blue|5-17,3-5,4-1,4-7,3-15,5-9,4-13,4-3,4-11
```

To combine two 9-hole loops into 18 holes, configure both OUT and IN indexes
for every hole. The example below illustrates the format and pairing only; it
is not Karlstad GK course data:

```text
Loop A|4-1-2,4-3-4,4-5-6,4-7-8,4-9-10,4-11-12,4-13-14,4-15-16,4-17-18
Loop B|4-1-2,4-3-4,4-5-6,4-7-8,4-9-10,4-11-12,4-13-14,4-15-16,4-17-18
```

When Loop A is selected first and Loop B second, the round uses Loop A's OUT
indexes for holes 1–9 and Loop B's IN indexes for holes 10–18. Together those
sets must contain every index from 1 to 18 exactly once. Use the OUT and IN
values from the club's scorecard; do not derive one set from the other. The
single-index Blue setting above does not include IN values, so it cannot yet be
used in an 18-hole combination. If both selected sets use local indexes 1–9,
the app keeps Loop A's indexes as 1–9 and adds 9 to Loop B's indexes for the
18-hole round. This lets clubs with local 1–9 rankings combine two loops without
changing their scorecard entries.

Each loop must contain exactly 9 or 18 holes. Par must be 3, 4, or 5, and
indexes in each set must be unique. An 18-hole loop must use every index from
1 to 18. A standalone 9-hole loop may use its published 1–18 course indexes;
the watch displays and uses those indexes directly when calculating strokes
received from the playing handicap. A single-index 9-hole setting remains
valid for standalone play. Loop names cannot contain `|`.

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

## Run tests

Compile the unit-test build, then run it in the Connect IQ simulator. Replace
`venu2` with another supported device ID if needed:

```sh
monkeyc -t -d venu2 -f monkey.jungle -o /tmp/netscoregolf-test.prg -y /path/to/developer_key
monkeydo /tmp/netscoregolf-test.prg venu2 -t
```

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
