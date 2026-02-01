-- Create these users in Supabase Auth first (Auth > Users).
-- Then run this seed; it will upsert profile data and seed posts.

insert into profiles (id, email, username, display_name, avatar_url, role, bio)
select
  id,
  email,
  'alice_wong',
  'Alice Wong',
  'https://placehold.co/200x200/FFD5C4/3D1A10.png?text=AW',
  'student',
  'Official announcements and weekly updates.'
from auth.users
where email = 'alice@qu.edu.qa'
union all
select
  id,
  email,
  'ava_martinez',
  'Ava Martinez',
  'https://placehold.co/200x200/FFD5C4/3D1A10.png?text=AM',
  'student',
  'CS major. Coffee-powered and always exploring the city.'
from auth.users
where email = 'ava@qu.edu.qa'
union all
select
  id,
  email,
  'leo_chen',
  'Leo Chen',
  'https://placehold.co/200x200/FFD5C4/3D1A10.png?text=LC',
  'student',
  'Photography + Econ. Looking for study buddies.'
from auth.users
where email = 'leo@qu.edu.qa'
on conflict (id) do update
set
  email = excluded.email,
  username = excluded.username,
  display_name = excluded.display_name,
  avatar_url = excluded.avatar_url,
  role = excluded.role,
  bio = excluded.bio;

insert into campus_posts (author_id, title, content, media_url, media_type, like_count)
values
  ((select id from profiles where username = 'alice_wong'), 'Career Fair Week',
   'Meet 120+ employers across two days. Bring your student ID and a polished resume.',
   'https://placehold.co/1200x675/F4A261/3A2515.png?text=Career%20Fair',
   'image', 124),
  ((select id from profiles where username = 'alice_wong'), 'Library Hours Extended',
   'Finals season means the library is open until 2AM. Quiet zones now include the 4th floor.',
   null, null, 86),
  ((select id from profiles where username = 'alice_wong'), 'Wellness Pop-Up',
   'Drop by the student center for free smoothie samples, mindfulness sessions, and giveaways.',
   'https://placehold.co/1200x675/DD6E42/FFFFFF.png?text=Wellness%20Pop-Up',
   'image', 59);

insert into community_posts (author_id, title, content, media_url, tags, upvotes, comment_count)
values
  ((select id from profiles where username = 'ava_martinez'), 'Anyone taking Data Structures with Prof. Lang?',
   'Looking to form a study group for the upcoming midterm. Drop your schedule!',
   null, '{study,cs}', 42, 12),
  ((select id from profiles where username = 'leo_chen'), 'Sunset photography walk',
   'Meet at the quad at 5:30 PM. Bringing my camera if anyone wants portraits.',
   'https://placehold.co/1200x675/6A994E/FFFFFF.png?text=Sunset%20Walk',
   '{photography,events}', 31, 6),
  ((select id from profiles where username = 'ava_martinez'), 'Best late-night food near campus?',
   'Cramming week is here. Share your go-to spots with delivery or takeout.',
   null, '{food,nightlife}', 58, 21);

insert into marketplace_listings (seller_id, title, description, price, image_url, status, location)
values
  ((select id from profiles where username = 'ava_martinez'), 'Graphing Calculator',
   'Barely used TI-84 Plus. Includes cover and batteries.', 55.00,
   'https://placehold.co/1200x900/FFE3C7/3A2515.png?text=Calculator',
   'available', 'North Hall'),
  ((select id from profiles where username = 'leo_chen'), 'Desk Lamp + Organizer Set',
   'Warm light desk lamp, pen holder, and storage tray. Perfect for dorm desks.', 28.00,
   'https://placehold.co/1200x900/DDEBCF/21371A.png?text=Desk%20Set',
   'available', 'Maple Residence'),
  ((select id from profiles where username = 'ava_martinez'), 'Mini Fridge',
   '2.7 cu ft mini fridge. Works great, just moving out.', 80.00,
   'https://placehold.co/1200x900/F5E4D8/5B4A3E.png?text=Mini%20Fridge',
   'available', 'South Campus');
