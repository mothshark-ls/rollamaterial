# Feed Gubby or ELSE — Game Design

This is the single source of truth for how the game works. Code changes are
checked against this document. If something here is wrong or out of date, fix
this document first, then change the code.

The two `.docx` files in this folder are the original plans. They are kept for
reference only; where they disagree with this document, **this document wins**.

---

## 1. Premise

A whole server works together to keep feeding Gubby. Gubby grows through
stages, gets hungry and angry if the server stops feeding him, and explodes
when his timer runs out.

Losing is expected and still rewarding: players earn permanent currency based
on how far the run got, and spend it on permanent upgrades.

The hook:

> "I wonder what happens if we keep going. We lost, but we got upgrades, so
> let's go again. Let's use Robux to speed this up, I want to see what
> happens."

The game is meant to be long. Different things happen at different stages,
and the ending is uncertain.

## 2. Who does what

| Owner  | Responsibility |
|--------|----------------|
| Damien | Map, models, animations, sounds, UI. All built in Studio and imported. |
| Claude | Code only. Every task is discussed and agreed before it is written. Only what the task needs is added. |

## 3. Core rules

- **Shared run:** every player in a server feeds the same Gubby. His growth
  and hunger belong to the run and reset when the run ends.
- **Permanent player:** currency and upgrades belong to the player and are
  saved between runs.
- **Server-wide effects:** events triggered by one player, and anything bought
  with Robux, affect the whole server.
- **Server decides:** the server owns food, carried amounts, Gubby's food
  total, stage, hunger, rewards and purchases. Clients only show things
  (animations, sounds, camera, UI) and send requests.

## 4. Food

### 4.1 Spawning

- Food spawns at random points on the top surface of **food zones** placed in
  the map.
- Each zone has a maximum amount of food alive in it at once and refills over
  time.
- Which food spawns is random, weighted by **rarity**. Rarer foods spawn less
  often.
- Every player sees all food. Whoever reaches it first gets it, so players can
  steal food from each other.

### 4.2 Food types

- All foods share the same behaviour and animations: spawn animation, floating
  animation and pickup animation.
- Foods differ only in what config says about them:
  - **FoodValue:** how much they add to the carried counter (for example
    Apple +1, Carrot +2).
  - **Event foods:** some foods give no FoodValue and instead start a
    server-wide event where they were picked up. Example: picking up a Taco
    starts "Raining Tacos" around that spot, and those tacos give FoodValue.
- Adding a new food only needs a model and one config entry, never new code.
- The food roster is **not final** (see section 11).

### 4.3 Pickup

- Food is collected by touching it. The server checks each player's distance
  to nearby food, so the Magnet upgrade later just means a bigger distance.
- If the player's counter is full, the food is **not** picked up and stays on
  the ground for others.

## 5. Carrying

- Carrying is **one number** with a capacity, shown as `current/capacity`.
  Players start at `0/15`. Each capacity upgrade adds +5.
- Picking up a food adds `min(FoodValue, space left)` to the counter.
- There is no item inventory. The server only keeps a **pickup queue** so the
  feeding animation can show the right food.

### 5.1 Pickup queue rules

Each queue entry is a FoodId plus how many clicks it is still worth. The
clicks in the queue always add up to exactly the counter.

1. **Pickup:** add `min(FoodValue, space left)` to the counter and push
   `{FoodId, that many clicks}` onto the back of the queue. At 14/15, a
   Carrot (+2) only counts for 1 click.
2. **Feed:** each fed unit takes 1 from the counter and 1 click from the
   front entry. That entry's FoodId is the food shown flying to Gubby. When
   the entry reaches 0 clicks it leaves the queue.
3. **Empty:** when the counter reaches 0, the queue is cleared completely as a
   safety reset.

A partly used entry stays at the front. New pickups go behind it, so amounts
always line up.

Example: picking up Apple +1, Carrot +2, Carrot +2, then two +5 foods:

| Clicks | Food shown | Counter after |
|--------|------------|---------------|
| 1      | Apple      | 14/15 |
| 2–3    | Carrot     | 12/15 |
| 4–5    | Carrot     | 10/15 |
| 6–10   | first +5 food  | 5/15 |
| 11–15  | second +5 food | 0/15, queue cleared |

## 6. Feeding Gubby

- The player must be within a set radius of Gubby, then **clicks Gubby**.
  Each click feeds. Players spam-click to empty their counter.
- Each click feeds **FeedPerClick** units (default 1). A future upgrade may
  raise this.
- Each fed unit adds 1 to Gubby's shared food total.
- An outline shows on Gubby while hovering him (planned).

### 6.1 Feeding animation and sounds (client presentation)

- Each fed unit plays one animation: the food (by FoodId) appears from inside
  the player, floats to Gubby's mouth, and disappears on arrival.
- Fed units go into an **animation queue** and are played with a short delay
  between each one. When one click feeds several units, they fly one after
  another instead of overlapping.
- When food reaches his mouth: the **Eat** sound plays, then **Chew**. If
  Chew finishes without more food arriving, **Burp** plays. If more food
  arrives first, Eat and Chew start again. He only burps once chewing
  finishes without interruption. Sounds restart instead of stacking.

## 7. Gubby's run

### 7.1 Stages

- Gubby's shared food total decides his stage. Thresholds live in
  `GubbyConfig`.
- Each stage has its **own model**, and the mouth is in a different place on
  each.
- On reaching a new stage: the camera pans to Gubby, he grows (model swap),
  and he roars or growls at the camera.
- Different things can happen at certain stages (details TBD).

### 7.2 Hunger and losing

- Gubby runs on a hunger timer. Feeding keeps it up.
- As it runs down he becomes **Hungry**, then **Angry**.
- If it reaches zero, he **explodes** and the run is lost. The camera pans to
  him as it does for a stage change, but he explodes.
- Timer length, how much feeding adds, and whether it scales with active
  players are TBD (section 11).

### 7.3 Ending

The ending is uncertain. Ideas on the table:

- He explodes and players win a large amount of currency.
- Something else unexpected happens.
- A fake-out, time-limited boss fight with a chance at something exclusive or
  extra currency if beaten.

## 8. Rewards and upgrades

- The highest stage reached guarantees a set amount of **permanent
  currency**, including when the run is lost.
- Currency buys permanent upgrades, "Slime RNG style" (details TBD).
- Known upgrades:
  - **Capacity:** +5 per upgrade.
  - **Magnet:** collect food from further away.
  - **Food per click:** raise FeedPerClick.

## 9. Robux

- Developer products benefit the whole server, never just the buyer.
- Robux should help a server see what happens next (speed things up, rescue a
  run), never be required to play.
- Product list TBD.

## 10. Studio conventions the code relies on

| Location | What it is | Rules |
|----------|------------|-------|
| `Workspace/Map/FoodZones` | Folder of flat zone Parts | Anchored, Transparency 1, CanCollide/CanTouch/CanQuery off, never tilted. Food spawns on the top face. A `ZoneType` attribute (`Short`, `Long`) picks the zone's settings from config. |
| `Workspace/Food` | Folder for live food | Filled by code. |
| `Workspace/GubbySpawn` | Invisible Part | Marks where Gubby's `Root` goes and which way he faces. |
| `ServerStorage/FoodModels` | Food templates | Each is a Model with an invisible `Root` Part as PrimaryPart, a `FoodId` attribute matching `FoodConfig`, and all parts Anchored with CanCollide/CanTouch/CanQuery off. |
| `ServerStorage/GubbyStages` | One Model per stage | Named after the stage IDs in `GubbyConfig`. Each has a `Root` PrimaryPart at his feet and a `Mouth` point (an Attachment or a Bone named `Mouth`). Visible parts keep CanQuery on so he can be clicked. |
| `ReplicatedStorage/GubbySounds` | Sound objects | `Eat`, `Chew`, `Burp`. |
| `ReplicatedStorage/Remotes` | RemoteEvents | `FeedRequest`, `GameStateUpdated`. |

## 11. Undecided

- Final food roster, values, rarities and which foods trigger events.
- Zone types and their max food and refill time.
- Stage list, thresholds and what happens at each stage.
- Hunger timer length, how much a feed adds, and scaling with active players.
- Currency amounts per stage, and the upgrade system.
- The ending.
- Robux products.
- Feeding radius and the delay between queued feed animations.

## 12. Cut from the original plans

- The ring-based map layout. Zones go wherever the map needs them.
- Luck upgrade, Pizza Frenzy and Food Rain events.
- Item inventory. Carrying is one number.

## 13. Build order

One task at a time, each discussed before code is written:

1. Food system: zones, rarity-weighted spawning, refilling, touch pickup,
   capacity counter and pickup queue.
2. Feeding: click within range, shared food total, feed animation queue and
   sounds.
3. Stages: model swap, camera pan.
4. Hunger timer and explosion.
5. Run end, currency and upgrades.
6. Events, Robux products, ending.
