create extension if not exists "pgcrypto";

create table if not exists profiles (
  id uuid primary key references auth.users on delete cascade,
  email text not null,
  username text not null unique,
  display_name text,
  avatar_url text,
  bio text,
  role text not null default 'student',
  created_at timestamptz not null default now(),
  updated_at timestamptz
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, username, display_name, avatar_url, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    new.raw_user_meta_data->>'display_name',
    new.raw_user_meta_data->>'avatar_url',
    'student'
  )
  on conflict (id) do update
    set email = excluded.email,
        username = excluded.username,
        display_name = excluded.display_name,
        avatar_url = excluded.avatar_url;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

create table if not exists campus_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  content text not null,
  media_url text,
  media_type text,
  like_count integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists campus_post_saves (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  post_id uuid not null references campus_posts(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, post_id)
);

create table if not exists community_post_saves (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  post_id uuid not null references community_posts(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, post_id)
);

create table if not exists community_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  content text not null,
  media_url text,
  tags text[] not null default '{}',
  upvotes integer not null default 0,
  comment_count integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists community_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references community_posts(id) on delete cascade,
  author_id uuid not null references profiles(id) on delete cascade,
  parent_id uuid references community_comments(id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now()
);

create table if not exists marketplace_listings (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  description text not null,
  price numeric(10, 2) not null,
  image_url text,
  status text not null default 'available',
  location text,
  created_at timestamptz not null default now()
);

create index if not exists campus_posts_created_idx on campus_posts (created_at desc);
create index if not exists campus_post_saves_user_idx on campus_post_saves (user_id);
create index if not exists campus_post_saves_post_idx on campus_post_saves (post_id);
create index if not exists community_post_saves_user_idx on community_post_saves (user_id);
create index if not exists community_post_saves_post_idx on community_post_saves (post_id);
create index if not exists community_posts_created_idx on community_posts (created_at desc);
create index if not exists community_comments_post_idx on community_comments (post_id);
create index if not exists community_comments_parent_idx on community_comments (parent_id);
create index if not exists community_comments_created_idx on community_comments (created_at asc);
create index if not exists marketplace_created_idx on marketplace_listings (created_at desc);

alter table profiles enable row level security;
alter table campus_posts enable row level security;
alter table campus_post_saves enable row level security;
alter table community_post_saves enable row level security;
alter table community_posts enable row level security;
alter table community_comments enable row level security;
alter table marketplace_listings enable row level security;

create policy "Profiles are viewable by authenticated" on profiles
  for select
  using (auth.role() = 'authenticated');

create policy "Profiles are insertable by owner" on profiles
  for insert
  with check (auth.uid() = id);

create policy "Profiles are updatable by owner" on profiles
  for update
  using (auth.uid() = id);

create policy "Campus posts readable" on campus_posts
  for select
  using (auth.role() = 'authenticated');

create policy "Campus posts insert by owner" on campus_posts
  for insert
  with check (auth.uid() = author_id);

create policy "Campus posts update by owner" on campus_posts
  for update
  using (auth.uid() = author_id);

create policy "Campus post saves readable" on campus_post_saves
  for select
  using (auth.uid() = user_id);

create policy "Campus post saves insert by owner" on campus_post_saves
  for insert
  with check (auth.uid() = user_id);

create policy "Campus post saves delete by owner" on campus_post_saves
  for delete
  using (auth.uid() = user_id);

create policy "Community post saves readable" on community_post_saves
  for select
  using (auth.uid() = user_id);

create policy "Community post saves insert by owner" on community_post_saves
  for insert
  with check (auth.uid() = user_id);

create policy "Community post saves delete by owner" on community_post_saves
  for delete
  using (auth.uid() = user_id);

create policy "Community posts readable" on community_posts
  for select
  using (auth.role() = 'authenticated');

create policy "Community posts insert by owner" on community_posts
  for insert
  with check (auth.uid() = author_id);

create policy "Community posts update by owner" on community_posts
  for update
  using (auth.uid() = author_id);

create policy "Community posts delete by owner" on community_posts
  for delete
  using (auth.uid() = author_id);

create policy "Community comments readable" on community_comments
  for select
  using (auth.role() = 'authenticated');

create policy "Community comments insert by owner" on community_comments
  for insert
  with check (auth.uid() = author_id);

create policy "Community comments delete by owner" on community_comments
  for delete
  using (auth.uid() = author_id);

create or replace function public.handle_community_comment_count()
returns trigger
language plpgsql
as $$
begin
  if (tg_op = 'INSERT') then
    update community_posts
      set comment_count = comment_count + 1
      where id = new.post_id;
    return new;
  elsif (tg_op = 'DELETE') then
    update community_posts
      set comment_count = greatest(comment_count - 1, 0)
      where id = old.post_id;
    return old;
  end if;
  return null;
end;
$$;

drop trigger if exists community_comment_count_trigger on community_comments;

create trigger community_comment_count_trigger
after insert or delete on community_comments
for each row execute procedure public.handle_community_comment_count();

create policy "Marketplace listings readable" on marketplace_listings
  for select
  using (auth.role() = 'authenticated');

create policy "Marketplace listings insert by owner" on marketplace_listings
  for insert
  with check (auth.uid() = seller_id);

create policy "Marketplace listings update by owner" on marketplace_listings
  for update
  using (auth.uid() = seller_id);
