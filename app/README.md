# UniHub

A modern campus hub built with Flutter + Supabase. Includes a university feed, a community board, and a marketplace.

## Setup

1) Create a Supabase project and run the SQL in `supabase/schema.sql`.
2) Create a few users in Supabase Auth and copy their user IDs.
3) Update the placeholder UUIDs in `supabase/seed.sql` and run it.
4) Add your Supabase keys to `.env` (see `.env.example`).
5) Run the app:

```bash
flutter run
```

## Notes
- All data is stored in Supabase (auth + posts + marketplace).
- The UI uses a warm, non-blue palette by design.
