-- Sahayog — Supabase schema
-- Run this in Supabase: Project → SQL Editor → New query → paste → Run.
-- Matches the data model already used by the front-end (SCHEMES / PARTNERS
-- arrays in app.html), so the API endpoints in /api/schemes.js and
-- /api/partners.js can serve real rows instead of the built-in demo data.

-- ============================================================
-- SCHEMES
-- ============================================================
create table if not exists schemes (
  id text primary key,                     -- e.g. "women", "rural" (matches existing demo ids)
  tag text not null,                        -- audience tag used by the matching engine
  cat text not null,                        -- business category (agri/mfg/food/tech/craft/retail/other)
  name_en text not null,
  name_hi text not null,
  desc_en text not null,
  desc_hi text not null,
  benefits_en text[] not null default '{}',
  benefits_hi text[] not null default '{}',
  eligibility_en text[] not null default '{}',
  eligibility_hi text[] not null default '{}',
  docs_en text[] not null default '{}',
  docs_hi text[] not null default '{}',
  funding_range text,                       -- display string, e.g. "₹2L–5L"
  interest_rate numeric,                    -- annual %, e.g. 7.0
  max_loan numeric,                         -- ₹
  max_tenure_months integer,
  moratorium_options integer[] default '{}', -- e.g. {3,6,9,12}
  category_type text check (category_type in ('micro','term','education')),
  income_threshold numeric,
  location text,                            -- e.g. "UP", "All India"
  application_mode_en text,
  application_mode_hi text,
  verified_date date,
  official_source_url text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- CHANNEL PARTNERS
-- ============================================================
create table if not exists partners (
  id text primary key,
  name text not null,
  type text check (type in ('sca','psb','rrb','nbfc')) not null,
  state text not null,
  district text not null,
  categories_supported text[] not null default '{}',  -- subset of schemes.category_type values
  distance_km numeric,                      -- illustrative/demo only — see README caveat
  routing_status text check (routing_status in ('green','yellow','red')) not null default 'green',
  capacity integer check (capacity between 0 and 100),  -- illustrative/demo only
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- USER PROFILES  (extends Supabase's built-in auth.users)
-- ============================================================
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  phone text,
  category text,
  state_name text,
  district text,
  stage text,
  support_needed text[] default '{}',
  description text,
  audience_categories text[] default '{}',  -- women/rural/disability/lowincome/minority/tribal
  budget_range text,
  revenue_model text,
  growth_goal text,
  income numeric,
  language text default 'en',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- MATCHES  (a computed scheme match for a user, so results can be revisited)
-- ============================================================
create table if not exists matches (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references profiles(id) on delete cascade,
  scheme_id text references schemes(id) on delete cascade,
  score integer not null,
  factors jsonb,                            -- factor-by-factor breakdown for explainability
  created_at timestamptz not null default now()
);

-- ============================================================
-- SAVED SCHEMES
-- ============================================================
create table if not exists saved_schemes (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references profiles(id) on delete cascade,
  scheme_id text references schemes(id) on delete cascade,
  saved_at timestamptz not null default now(),
  unique (profile_id, scheme_id)
);

-- ============================================================
-- APPLICATIONS  (application journey tracker)
-- ============================================================
create table if not exists applications (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references profiles(id) on delete cascade,
  scheme_id text references schemes(id),
  partner_id text references partners(id),
  stage text check (stage in ('profile','documents','application','partner_selection','verification','approval','disbursement')) default 'profile',
  status text default 'in_review',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- DOCUMENT CHECKLIST STATUS
-- ============================================================
create table if not exists document_status (
  id uuid primary key default gen_random_uuid(),
  application_id uuid references applications(id) on delete cascade,
  document_name text not null,
  uploaded boolean not null default false,
  updated_at timestamptz not null default now()
);

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
create table if not exists notifications (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references profiles(id) on delete cascade,
  type text,                                -- new_match / missing_doc / deadline / scheme_updated
  message_en text,
  message_hi text,
  read boolean not null default false,
  created_at timestamptz not null default now()
);

-- ============================================================
-- ROW LEVEL SECURITY
-- Enable RLS and let each user read/write only their own rows.
-- Schemes and partners stay publicly readable (they're not user data).
-- ============================================================
alter table schemes enable row level security;
alter table partners enable row level security;
alter table profiles enable row level security;
alter table matches enable row level security;
alter table saved_schemes enable row level security;
alter table applications enable row level security;
alter table document_status enable row level security;
alter table notifications enable row level security;

create policy "Public read access to active schemes" on schemes
  for select using (active = true);

create policy "Public read access to active partners" on partners
  for select using (active = true);

create policy "Users manage their own profile" on profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);

create policy "Users read their own matches" on matches
  for select using (auth.uid() = profile_id);

create policy "Users manage their own saved schemes" on saved_schemes
  for all using (auth.uid() = profile_id) with check (auth.uid() = profile_id);

create policy "Users manage their own applications" on applications
  for all using (auth.uid() = profile_id) with check (auth.uid() = profile_id);

create policy "Users read their own document status" on document_status
  for select using (
    exists (select 1 from applications a where a.id = application_id and a.profile_id = auth.uid())
  );

create policy "Users read their own notifications" on notifications
  for select using (auth.uid() = profile_id);

-- ============================================================
-- SEED DATA — the same 6 illustrative demo schemes and 10 demo partners
-- already built into the front-end, so a fresh Supabase project behaves
-- identically to the built-in fallback data.
-- ============================================================
insert into schemes (id, tag, cat, name_en, name_hi, desc_en, desc_hi, benefits_en, benefits_hi, eligibility_en, eligibility_hi, docs_en, docs_hi, funding_range, interest_rate, max_loan, max_tenure_months, moratorium_options, category_type, income_threshold, location, application_mode_en, application_mode_hi, verified_date)
values
('women','women','craft','Women Entrepreneurship Support Scheme','महिला उद्यमिता सहायता योजना',
 'Low-interest loans and mentorship for women starting or growing a small business.','महिलाओं के लिए व्यापार शुरू करने या बढ़ाने हेतु कम ब्याज़ पर कर्ज़ और मार्गदर्शन।',
 array['Loan up to a subsidised rate','Free business mentorship','Priority processing'],
 array['रियायती दर पर कर्ज़','मुफ्त व्यापार मार्गदर्शन','प्राथमिकता प्रक्रिया'],
 array['Woman-owned or woman-led business','Business less than 5 years old','Valid ID proof'],
 array['महिला के स्वामित्व/नेतृत्व वाला व्यापार','5 वर्ष से कम पुराना व्यापार','वैध पहचान प्रमाण'],
 array['Aadhaar card','Bank passbook','Business address proof'],
 array['आधार कार्ड','बैंक पासबुक','व्यापार पते का प्रमाण'],
 '₹2L–5L', 7.0, 500000, 60, array[3,6,9,12], 'micro', 300000, 'UP', 'Online', 'ऑनलाइन', '2026-08-01'),

('rural','rural','agri','Rural Business Growth Fund','ग्रामीण व्यापार विकास कोष',
 'Support for village and small-town businesses to reach wider markets.','गाँव और छोटे शहरों के व्यापार को बड़े बाज़ार तक पहुँचाने में सहायता।',
 array['Seed funding grant','Market linkage support','Transport subsidy'],
 array['शुरुआती अनुदान','बाज़ार जोड़ने में सहायता','परिवहन सब्सिडी'],
 array['Business located in a rural area','Operating for at least 6 months'],
 array['ग्रामीण क्षेत्र में व्यापार','कम से कम 6 महीने से चल रहा हो'],
 array['Aadhaar card','Residence proof','Business photo/proof'],
 array['आधार कार्ड','निवास प्रमाण','व्यापार का फोटो/प्रमाण'],
 '₹1L–3L', 8.5, 300000, 48, array[3,6,12], 'micro', 250000, 'All India', 'Offline', 'ऑफ़लाइन', '2026-07-15'),

('disability','disability','other','Disability-Inclusive Enterprise Scheme','दिव्यांग समावेशी उद्यम योजना',
 'Extra support, accessible resources, and funding for entrepreneurs with disabilities.','दिव्यांग उद्यमियों के लिए अतिरिक्त सहायता, सुलभ संसाधन और धन।',
 array['Higher subsidy rate','Accessible equipment support','Dedicated helpline'],
 array['अधिक सब्सिडी दर','सुलभ उपकरण सहायता','समर्पित हेल्पलाइन'],
 array['Valid disability certificate','Age 18 or above'],
 array['वैध दिव्यांगता प्रमाणपत्र','18 वर्ष या अधिक आयु'],
 array['Disability certificate','Aadhaar card','Bank passbook'],
 array['दिव्यांगता प्रमाणपत्र','आधार कार्ड','बैंक पासबुक'],
 '₹3L–6L', 6.5, 600000, 72, array[6,9,12], 'term', 400000, 'All India', 'Online', 'ऑनलाइन', '2026-08-22'),

('minority','minority','retail','Minority Business Development Program','अल्पसंख्यक व्यापार विकास कार्यक्रम',
 'Financial and training support for entrepreneurs from minority communities.','अल्पसंख्यक समुदाय के उद्यमियों के लिए वित्तीय और प्रशिक्षण सहायता।',
 array['Concessional loan','Skill training','Networking events'],
 array['रियायती कर्ज़','कौशल प्रशिक्षण','नेटवर्किंग कार्यक्रम'],
 array['Belongs to a notified minority community','Valid income certificate'],
 array['अधिसूचित अल्पसंख्यक समुदाय से हों','वैध आय प्रमाणपत्र'],
 array['Community certificate','Income certificate','Aadhaar card'],
 array['समुदाय प्रमाणपत्र','आय प्रमाणपत्र','आधार कार्ड'],
 '₹1.5L–4L', 7.5, 400000, 60, array[3,6,9], 'micro', 300000, 'UP', 'Online', 'ऑनलाइन', '2026-07-10'),

('tribal','tribal','craft','Tribal Enterprise Support Scheme','आदिवासी उद्यम सहायता योजना',
 'Support for tribal entrepreneurs, with a focus on local craft and produce businesses.','आदिवासी उद्यमियों के लिए सहायता, स्थानीय शिल्प और उत्पाद व्यापार पर केंद्रित।',
 array['Grant for raw materials','Craft market access','Transport support'],
 array['कच्चे माल के लिए अनुदान','शिल्प बाज़ार तक पहुँच','परिवहन सहायता'],
 array['Belongs to a Scheduled Tribe','Village-based business'],
 array['अनुसूचित जनजाति से हों','गाँव आधारित व्यापार'],
 array['Tribal certificate','Aadhaar card','Residence proof'],
 array['जनजाति प्रमाणपत्र','आधार कार्ड','निवास प्रमाण'],
 '₹80K–2L', 6.0, 200000, 36, array[3,6], 'micro', 200000, 'All India', 'Offline', 'ऑफ़लाइन', '2026-08-05'),

('general','lowincome','food','General Small Business Loan Scheme','सामान्य लघु व्यापार ऋण योजना',
 'A baseline loan scheme open to small business owners from low-income households.','कम आय वाले परिवारों के छोटे व्यापारियों के लिए एक बुनियादी ऋण योजना।',
 array['Low documentation loan','Flexible repayment'],
 array['कम कागज़ी काम वाला कर्ज़','लचीला भुगतान'],
 array['Annual household income below threshold','Valid ID'],
 array['वार्षिक पारिवारिक आय सीमा से कम','वैध पहचान'],
 array['Aadhaar card','Income proof'],
 array['आधार कार्ड','आय प्रमाण'],
 '₹50K–1.5L', 9.0, 150000, 36, array[3,6], 'micro', 350000, 'All India', 'Online', 'ऑनलाइन', '2026-07-28')
on conflict (id) do nothing;

insert into partners (id, name, type, state, district, categories_supported, distance_km, routing_status, capacity)
values
('p1','UP State Channelizing Agency','sca','Uttar Pradesh','Lucknow', array['micro','term'], 4, 'green', 90),
('p2','National Bank Lucknow Branch','psb','Uttar Pradesh','Lucknow', array['micro','term','education'], 6, 'green', 75),
('p3','Awadh Regional Rural Bank','rrb','Uttar Pradesh','Kanpur', array['micro'], 18, 'yellow', 45),
('p4','Bharat NBFC-MFI Services','nbfc','Uttar Pradesh','Varanasi', array['micro','term'], 34, 'green', 65),
('p5','Maharashtra State Channelizing Agency','sca','Maharashtra','Pune', array['micro','term','education'], 5, 'green', 88),
('p6','Konkan Regional Rural Bank','rrb','Maharashtra','Nagpur', array['micro'], 22, 'red', 20),
('p7','Bihar Public Sector Bank Branch','psb','Bihar','Patna', array['micro','term','education'], 7, 'green', 70),
('p8','Rajasthan NBFC-MFI Network','nbfc','Rajasthan','Jaipur', array['micro','term'], 12, 'yellow', 50),
('p9','Bengal State Channelizing Agency','sca','West Bengal','Kolkata', array['micro','term','education'], 9, 'green', 82),
('p10','Odisha Regional Rural Bank','rrb','Odisha','Bhubaneswar', array['micro'], 15, 'green', 60)
on conflict (id) do nothing;
