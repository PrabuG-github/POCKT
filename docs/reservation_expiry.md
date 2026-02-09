# Reservation Expiry Logic

Since PostgreSQL/Supabase does not natively delete or update rows based on time without an external trigger, we implement the following strategy:

## 1. Schema Level
Each reservation has an `expires_at` column (Default: `NOW() + INTERVAL '60 minutes'`).

## 2. Background Task (The "Cleaner")
We use a background worker (part of our Go service) to periodically run the following cleanup query:

```sql
UPDATE reservations
SET status = 'expired'
WHERE status = 'pending' 
  AND expires_at < NOW();
```

## 3. Real-time Notification
When the status changes (either manually by the shop owner or automatically by the background task), **Supabase Realtime** broadcasts the change.
- The Flutter app listens to the `reservations` table.
- If a reservation expires, the UI reflects this immediately for both the User and the Shop Owner.

## 4. Frontend Enforcement
The Flutter app should also locally check the `expires_at` value to show a countdown timer and prevent users from trying to claim an expired reservation before the background task has run.
