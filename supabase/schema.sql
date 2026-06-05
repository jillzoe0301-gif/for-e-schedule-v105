-- FOR-e 共享排程系統 V103 正式版 Supabase Schema
-- 使用方式：Supabase Dashboard → SQL Editor → New Query → 全部貼上 → Run

create extension if not exists "pgcrypto";

-- 角色與狀態 enum
DO $$ BEGIN
  CREATE TYPE app_role AS ENUM ('admin', 'supervisor', 'staff', 'admin_staff');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- 使用者延伸資料，對應 auth.users
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique,
  display_name text not null default '',
  role app_role not null default 'staff',
  person_id uuid,
  line_id text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 人員名稱
create table if not exists public.people (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  department text not null default '',
  job_title text not null default '',
  line_id text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  is_deleted boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles
  drop constraint if exists profiles_person_id_fkey;
alter table public.profiles
  add constraint profiles_person_id_fkey foreign key (person_id) references public.people(id) on delete set null;

-- 下拉選項，可存行程類型、目的、地點、顏色等
create table if not exists public.option_sets (
  id uuid primary key default gen_random_uuid(),
  group_key text not null,
  label text not null,
  value text not null,
  extra jsonb not null default '{}'::jsonb,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(group_key, value)
);

-- 外務地點與地址
create table if not exists public.field_locations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text not null default '',
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 一般行事曆
create table if not exists public.schedules (
  id uuid primary key default gen_random_uuid(),
  series_id uuid,
  source_field_schedule_id uuid,
  created_by uuid references public.profiles(id) on delete set null,
  updated_by uuid references public.profiles(id) on delete set null,
  person_ids uuid[] not null default '{}',
  start_date date not null,
  end_date date not null,
  time_label text not null default '不指定',
  end_time_label text,
  category text not null default '',
  customer_location text not null default '',
  title text not null default '',
  schedule_type text not null default '',
  additional_type text,
  additional_note text,
  content text,
  status text not null default '未完成',
  translator_status text,
  vehicle text,
  service_record_required boolean not null default false,
  service_record_submitted boolean not null default false,
  service_record_submitted_date date,
  next_visit_date date,
  next_visit_time text,
  next_visit_person_id uuid references public.people(id) on delete set null,
  registration_number text,
  is_deleted boolean not null default false,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 外務行事曆
create table if not exists public.field_schedules (
  id uuid primary key default gen_random_uuid(),
  series_id uuid,
  linked_schedule_id uuid references public.schedules(id) on delete set null,
  created_by uuid references public.profiles(id) on delete set null,
  updated_by uuid references public.profiles(id) on delete set null,
  person_id uuid references public.people(id) on delete set null,
  start_date date not null,
  end_date date not null,
  time_label text not null default '不指定',
  end_time_label text,
  location_id uuid references public.field_locations(id) on delete set null,
  location_name text default '',
  address text default '',
  purpose text default '',
  status text default '',
  content text,
  cash text,
  seal text,
  certificate text,
  must_send boolean not null default false,
  cannot_change_worker boolean not null default false,
  next_pickup_date date,
  next_pickup_person_id uuid references public.people(id) on delete set null,
  failure_reason text,
  is_field_day_notice boolean not null default false,
  exclude_from_stats boolean not null default false,
  is_deleted boolean not null default false,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 操作紀錄
create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  before_data jsonb,
  after_data jsonb,
  note text,
  created_at timestamptz not null default now()
);

-- LINE 通知紀錄
create table if not exists public.line_notifications (
  id uuid primary key default gen_random_uuid(),
  schedule_id uuid references public.schedules(id) on delete set null,
  field_schedule_id uuid references public.field_schedules(id) on delete set null,
  recipient_profile_id uuid references public.profiles(id) on delete set null,
  recipient_person_id uuid references public.people(id) on delete set null,
  line_id text,
  message text not null,
  status text not null default 'pending',
  error_message text,
  sent_at timestamptz,
  created_at timestamptz not null default now()
);

-- 顏色設定，可使用 user_id 空值表示全系統預設
create table if not exists public.color_settings (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references public.profiles(id) on delete cascade,
  key text not null,
  bg_color text,
  text_color text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(profile_id, key)
);

-- 更新時間 trigger
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

DO $$ DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['profiles','people','option_sets','field_locations','schedules','field_schedules','color_settings'] LOOP
    EXECUTE format('drop trigger if exists trg_%I_updated_at on public.%I', t, t);
    EXECUTE format('create trigger trg_%I_updated_at before update on public.%I for each row execute function public.set_updated_at()', t, t);
  END LOOP;
END $$;

-- RLS：正式版先開啟，開發初期可依 README 暫時使用 service role 初始化資料
alter table public.profiles enable row level security;
alter table public.people enable row level security;
alter table public.option_sets enable row level security;
alter table public.field_locations enable row level security;
alter table public.schedules enable row level security;
alter table public.field_schedules enable row level security;
alter table public.audit_logs enable row level security;
alter table public.line_notifications enable row level security;
alter table public.color_settings enable row level security;

-- 基本讀取政策：登入者可讀取系統資料
DO $$ DECLARE tbl text;
BEGIN
  FOREACH tbl IN ARRAY ARRAY['profiles','people','option_sets','field_locations','schedules','field_schedules','audit_logs','line_notifications','color_settings'] LOOP
    EXECUTE format('drop policy if exists "authenticated_read_%I" on public.%I', tbl, tbl);
    EXECUTE format('create policy "authenticated_read_%I" on public.%I for select using (auth.role() = ''authenticated'')', tbl, tbl);
  END LOOP;
END $$;

-- 寫入政策：正式版 API routes 會使用 service role；前端可先不開放直接寫入，避免資料外洩。

-- 預設下拉選項
insert into public.option_sets (group_key, label, value, sort_order) values
('schedule_type','外務','外務',1),
('schedule_type','醫療(看診、回診、住院、急診、開刀)','醫療(看診、回診、住院、急診、開刀)',2),
('schedule_type','收送簽文件(證件、用印、簽文件)','收送簽文件(證件、用印、簽文件)',3),
('schedule_type','銀行(開戶、補辦、領錢、異動)','銀行(開戶、補辦、領錢、異動)',4),
('schedule_type','定期 (開會)','定期 (開會)',5),
('schedule_type','送工(新入境、承接)','送工(新入境、承接)',6),
('schedule_type','車禍處理(做筆錄、現場協調、和解、出庭)','車禍處理(做筆錄、現場協調、和解、出庭)',7),
('schedule_type','面談','面談',8),
('schedule_type','其他','其他',9),
('schedule_type','逃跑通知','逃跑通知',10),
('schedule_type','轉出追蹤','轉出追蹤',11),
('schedule_type','住變資訊','住變資訊',12),
('schedule_type','視訊/面試','視訊/面試',13),
('schedule_type','上線/教育訓練','上線/教育訓練',14),
('schedule_type','宿舍','宿舍',15),
('schedule_type','返台提醒','返台提醒',16),
('field_purpose','送件','送件',1),
('field_purpose','申請','申請',2),
('field_purpose','登記','登記',3),
('field_purpose','送審','送審',4),
('field_purpose','領件','領件',5),
('field_purpose','認證','認證',6),
('field_purpose','繳費','繳費',7),
('field_purpose','外務日-若有非外務行程請先確認','外務日-若有非外務行程請先確認',8),
('field_status','','',0),
('field_status','未完成','未完成',1),
('field_status','已完成','已完成',2),
('field_status','已送件','已送件',3),
('field_status','異常','異常',4),
('field_status','要補件','要補件',5),
('field_status','送件失敗','送件失敗',6)
on conflict (group_key, value) do nothing;

-- 預設外務地點
insert into public.field_locations (name, address, sort_order) values
('', '', 0),
('內湖_印辦','台北市內湖區瑞光路550號2樓',1),
('內湖_菲辦','台北市內湖區洲子街55-57號2樓',2),
('台北_越辦(領件只能下午)','臺北市中山區松江路101號2樓',3),
('台北_越南換護照','臺北市中山區松江路65號2，3樓',4),
('台北_泰辦','台北市大安區信義路三段151號 10 樓',5),
('台北_勞動部','臺北市中正區中華路1段39號10樓',6),
('桃園移民署','桃園市桃園區縣府路106號1樓',7),
('中壢就業中心','桃園市中壢區新興路182號',8),
('桃園就業中心','桃園市桃園區縣府路59號',9),
('中和就業中心','新北市中和區景安路118號',10),
('板橋就業中心','新北市板橋區漢生東路163號',11),
('三重就業中心(不同仲介要不同天)','新北市三重區重新路四段12號',12),
('新竹就業中心','新竹市光華東街56號',13),
('竹北就業中心','新竹縣竹北市光明九路7-3號',14),
('宜蘭羅東就業中心','宜蘭縣羅東鎮東榮路二段91號',15),
('苗栗就業中心','苗栗市中山路558號',16),
('新北移民署','新北市中和區民安街135號',17),
('竹北移民署','新竹縣竹北市三民路133號1樓',18),
('基隆移民署','基隆市中正區義一路18號11樓A棟',19),
('新竹移民署','新竹市北區中華路三段12號1樓',20)
on conflict do nothing;

-- 預設顏色
insert into public.color_settings (profile_id, key, bg_color, text_color) values
(null,'dept_一部翻譯','#f8ee88','#111827'),
(null,'dept_二部翻譯','#bfe1f6','#111827'),
(null,'date_header','#efefef','#111827'),
(null,'weekend_holiday','#e8f4ff','#111827'),
(null,'today','#fff4ce','#111827'),
(null,'schedule_incomplete','#fff7c2','#111827'),
(null,'schedule_completed','#dcebf5','#111827')
on conflict (profile_id, key) do nothing;
