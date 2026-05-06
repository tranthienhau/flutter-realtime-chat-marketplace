-- Marketplace chat schema
create table if not exists chat_threads (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null,
  listing_title text not null,
  listing_image_url text,
  buyer_id uuid not null references auth.users(id),
  seller_id uuid not null references auth.users(id),
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (listing_id, buyer_id, seller_id)
);

create table if not exists chat_messages (
  id uuid primary key,
  thread_id uuid not null references chat_threads(id) on delete cascade,
  sender_id uuid not null references auth.users(id),
  body text not null default '',
  kind text not null default 'text',
  attachment_url text,
  offer_amount numeric,
  sent_at timestamptz not null default now(),
  read_at timestamptz
);

create index if not exists idx_messages_thread_sent on chat_messages(thread_id, sent_at desc);

alter publication supabase_realtime add table chat_messages;

alter table chat_threads enable row level security;
alter table chat_messages enable row level security;

create policy "thread parties read" on chat_threads
  for select using (auth.uid() = buyer_id or auth.uid() = seller_id);

create policy "messages by thread parties" on chat_messages
  for select using (
    exists (
      select 1 from chat_threads t
      where t.id = chat_messages.thread_id
        and (t.buyer_id = auth.uid() or t.seller_id = auth.uid())
    )
  );

create policy "send as self" on chat_messages
  for insert with check (sender_id = auth.uid());
