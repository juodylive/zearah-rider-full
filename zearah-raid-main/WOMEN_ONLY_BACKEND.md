# Women-only service – backend / admin panel requirements

The two apps are done. The admin panel and API are not part of the uploaded
projects, so these items must be built there.

## What the apps already do
Rider app (female riders only see the switch "طلب سائقة (للسيدات فقط)"):
- Searches only drivers whose Firestore doc has `gender == "female"`.
- Sends `women_only` = "1" / "0" in the `bookItem` request.
- Writes `womenOnly: true` in the `ride_request` map delivered to the driver.
Driver app:
- Writes `gender` ("male"/"female"/"others", from the profile) to
  `drivers/<id>` when going online, on every location update and on creation.
- Shows a "Women only / للسيدات فقط" badge on the incoming request card.

## Admin panel – required
1. Driver profile: show and allow editing of **gender**. Drivers with an empty
   gender are never offered women-only rides.
2. Settings: switch to enable/disable the women-only service globally
   (and optionally an extra fee / fare multiplier for it).
3. Bookings list + details: show the **women_only** flag; add a filter.
4. Reports: count of women-only rides and drivers eligible.

## API – required (do not trust the client)
- `bookItem`: accept `women_only`; store it on the booking; if 1, reject the
  booking when the assigned driver's gender is not "female" or the rider's
  gender is not "female".
- Return `women_only` in booking/history responses.
- Gender must come from the verified profile, not from Firestore alone
  (a modified client could write any value to its own driver doc).

## Firestore
- Existing drivers get `gender` the next time they go online or move.
- Consider a security rule so a driver cannot change `gender` after approval.
