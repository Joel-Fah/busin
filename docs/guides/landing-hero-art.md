# Landing hero art: the layers to generate

The landing page's bus stop scene is built from separate images in the BusIn people illustration style (see the
styleguide, Imagery, and the references in `apps/admin_web/public/styleguide/references/`). The owner generates the
images with an image model; the portal places them, animates them a little and keeps the speech chips on top.

Put the finished files in `apps/admin_web/public/landing/scene/` with these names (PNG with a transparent background is
best; WebP with transparency also works). Sizes are minimums.

| File | What | Size |
|---|---|---|
| `background-day.png` | The street without people, by day | 3200 x 1060 |
| `background-night.png` | The same picture at night, same framing | 3200 x 1060 |
| `girl-walking.png` | The girl telling a story, walking right | about 1400 tall |
| `boy-walking.png` | The boy a step ahead, looking back laughing | about 1400 tall |
| `girl-bench.png` | The girl sitting on the bench, on her phone | about 1100 tall |
| `boy-waiting.png` | The boy by the sign, checking his watch | about 1400 tall |

## The style (start every prompt with this)

> Flat vector editorial illustration with a stippled grain texture (small lighter and darker specks on clothes, bags,
> foliage and walls, none on skin). Warm palette: mustard #f0b63c, terracotta #cf6a43, olive #7f8a3c, leaf green
> #79a744, deep green #36683a, sage #b9c8b0, sand #f0c57e, with deep teal #0c5d6d for structures and orange #f5951f as
> the single accent. Young African university students with rounded bodies, slightly long limbs, small expressive hands,
> chunky sneakers with light soles, simple faces with dot eyes and round rosy cheeks, expressive hair and big hoop
> earrings. Calm warm daylight, no outlines, no gradients, no 3D, no text, letters or logos anywhere in the image.

Give the model the two reference images as style references with every prompt, and generate all the people in the same
session so they match. Keep everyone the same scale: a standing person about 37% of the background's height.

## 1. Background, by day

> [style] A very wide panorama (3:1) of a campus street at a bus stop in the morning, with no people at all. Plain
> transparent sky (or plain white), nothing drawn above the trees and buildings. From left to right: a big leafy tree at
> the far left; an open stretch of pavement (left of centre, about 12% to 28% across) with nothing on it; in the
> middle a bus shelter with a deep teal frame, an orange curved roof, a glass back wall and an empty wooden bench centred
> at about 50% across, and an advert panel with abstract warm swirls on its right side; just right of the shelter (about
> 67% across) a bus stop pole with a square sign showing only a simple bus pictogram (no words); then an open spot of
> pavement (about 72% to 78%); at the right a warm sand campus building with a brick band, a brick tower, palm trees and
> soft sage hills behind. Street lamps on the pavement. The pavement's front edge (where people would stand) is a
> straight line about 75% down from the top; below it a kerb and a grey road with white dashed lane marks running the
> full width. No signs with words, no logos, no cars, no people.

## 2. Background, at night

Use the day image as the input and ask for an edit, so the framing stays identical:

> Same image, same framing and every shape in the same place, at night: deep teal blue-green dusk tones, warm lit
> windows in the campus building, street lamps glowing softly, the shelter's glass catching the light, the grain kept.
> Sky still transparent (or plain), no moon, no stars (the page draws them).

## 3. The girl walking (`girl-walking.png`)

The second reference is already this person; regenerate it on a transparent background if possible.

> [style] Full body, one young woman alone on a transparent background, walking to the right in side view, telling a
> story with one hand open in front of her: a long thick braid swinging out behind her, big gold hoop earrings, a
> speckled mustard sweater, a pleated teal skirt, a cream tote bag with an orange stripe on her shoulder, chunky dark
> teal sneakers with white soles. Smiling, mouth open as she talks. Nothing else in the image.

## 4. The boy walking (`boy-walking.png`)

> [style] Full body, one young man alone on a transparent background, walking to the right a step ahead of a friend but
> turning his head back over his shoulder to look at her, laughing; one thumb hooked under his backpack strap. Short
> tight curls, a speckled terracotta sweater, rolled blue jeans, a brown backpack, brown sneakers with light soles.
> Nothing else in the image.

## 5. The girl on the bench (`girl-bench.png`)

> [style] Full body, one young woman alone on a transparent background, sitting as if on a bench (no bench drawn), side
> view facing right, leaning forward with her elbows on her knees, looking down at a phone held in both hands; feet flat
> on the ground. A high bun with a mustard band, small gold studs, a speckled green top, terracotta trousers, mustard
> high-top sneakers, headphones around her neck. An olive backpack sits beside her at hip height on the right. Nothing
> else in the image.

## 6. The boy waiting (`boy-waiting.png`)

> [style] Full body, one young man alone on a transparent background, standing in three-quarter view facing left,
> worried, glancing at the wristwatch on his raised left arm, weight on one leg; a little sweat drop. Glasses, short
> hair, a speckled deep teal jacket with a mustard collar over a white tee, brown trousers, mustard sneakers, a
> terracotta backpack on one shoulder. Nothing else in the image.

## Checking the results before handing them over

- No words, letters or logos anywhere (the model often adds a sign or a brand: ask again without it).
- Transparent around every person; if the tool only gives white, say so and the portal side will cut it out.
- People drawn at the same scale and with the same grain and palette as each other and as the background.
- The background's pavement edge straight and level, the bench empty, the bus sign without text.
