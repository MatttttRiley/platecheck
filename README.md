# PlateCheck (SwiftUI, iOS 17+)

Vanity plate format checker (all 50 states + DC, Utah is the default) and a plate-to-vehicle lookup screen.

## Install

Every push to `main` builds an unsigned IPA in GitHub Actions
(`.github/workflows/build-ipa.yml`). Download the `PlateCheck-unsigned-ipa`
artifact from the run, then install it with SideStore (or AltStore/Sideloadly),
which re-signs it with your Apple ID. Free Apple ID installs expire after 7 days.

## Lookup tab

Plate lookup is baked in, with nothing to configure. The plate is matched to
a VIN by CarAPI (free tier: 100 lookups a month, no credit card — token lives
in `PlateCheck/PlateLookupService.swift`), then the VIN is decoded into full
specs by NHTSA's vPIC database (free, no key). The app returns vehicle details
only, never owner information.

## State rules

Utah limits and the checker link (Motor Vehicle Portal, mvp.tax.utah.gov) come
from dmv.utah.gov and form TC-817. Other states default to a 7-character limit
(MA 6, NY 8) and are NOT verified — edit `PlateCheck/StateData.swift`. Each
state's checker button falls back to a web search unless you fill in
`checkerURL`.

## Build locally (needs a Mac)

Open `PlateCheck.xcodeproj` in Xcode, pick your iPhone as the run destination,
set your Apple ID under Signing & Capabilities > Team, and press Run.
