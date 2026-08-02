# <img alt="OpenSK logo" src="../img/OpenSK.svg" width="200px">

## nice!nano (and compatible boards)

This targets the nice!nano and clones that ship the same Adafruit UF2
bootloader (mass storage device named e.g. `NICENANOBOOT`).

Unlike the other supported boards, nice!nano has no dedicated user-presence
button — only RESET, which is wired directly to the chip's reset pin, not to
a GPIO. **Without wiring a switch, user-presence checks will simply time out.**
By default this runner reads the button on pin **P0.02**, a free pin on the
header. Wire a momentary switch (a jumper wire or tweezers is enough to test)
between P0.02 and any GND pin on the header. Double-check against your
board's silkscreen before soldering, since clones may differ. Confirmed on
hardware: shorting P0.02 to GND fires the button event.

By default the onboard status LED (P0.15) is used to show state; it is
wired active-high and this is handled in `board/led.rs`. This has also been
confirmed on hardware (it lights up while the button is held).

Some boards additionally have a small blue LED near the USB connector that
blinks on its own. That one is a hardware charge-status indicator wired to
the battery charging circuit, not to any GPIO — it is unrelated to this
runner and cannot be controlled or read by the firmware.

#### Changing the button or LED pin

Both pins can be moved at build time, without editing any source, via
environment variables read by `crates/runner-nordic/build.rs`:

- `WASEFIRE_NICENANO_BUTTON_PIN` (default `P0.02`)
- `WASEFIRE_NICENANO_LED_PIN` (default `P0.15`, e.g. to drive an external LED
  instead of the onboard one)

Format is `P<port>.<pin>`, e.g. `P1.11` for pin 11 on port 1. Set them before
calling `flash.sh`:

```sh
WASEFIRE_NICENANO_BUTTON_PIN=P1.11 WASEFIRE_NICENANO_LED_PIN=P0.06 \
  ./flash.sh nrf52840_nicenano
```

Any pin can be picked this way; nothing prevents selecting one of the
special-purpose pins (NFC, the VCC-cutoff pin, the battery ADC pin), so avoid
those unless you know what you are doing.

### Flashing

Double-tap the reset button so the board remounts as a USB mass storage
device (`NICENANOBOOT`), then run:

```sh
./flash.sh nrf52840_nicenano
```

On at least one bootloader build (Adafruit UF2 bootloader 0.6.0), the board
does not automatically jump to the freshly-flashed firmware and stays in
mass-storage mode after the write completes. If that happens, press RESET
**once** (a single short press, not the double-tap) to boot into it.

`flash.sh --update` (in-place update over USB, preserving storage) has not
been tested on this board and is not expected to need anything nice!nano
specific, but it does require the host to have USB permission to the
device's raw HID/vendor interface (a udev rule matching its vendor/product
ID). Prefer a full `flash.sh nrf52840_nicenano` if in doubt.

### Buttons and LEDs

The button wired to P0.02 conveys user presence. The onboard status LED has
a single color (no RGB), so it only conveys state through blinking:

| Pattern               | Cause                  |
|-----------------------|------------------------|
| Slow blinking         | Asking for touch       |
| Fast blinking for 5s  | Wink (just saying Hi!) |
| Steady on             | Busy                   |
