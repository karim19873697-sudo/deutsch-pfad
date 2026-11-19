-- ============================================================
-- Deutsch Pfad v2  —  شغّله كاملًا في Supabase > SQL Editor > Run
-- (يحذف جداول النسخة القديمة التجريبية ويبني كل شيء من جديد)
-- ============================================================
drop trigger if exists on_signup on auth.users;
drop function if exists handle_new_user() cascade;
drop table if exists attempts, progress, question_texts, ui_strings, questions cascade;
drop table if exists awarded_runs, review_items, lesson_progress, answers, xp_log, exercise_keys, exercise_texts, exercises, lessons, units, profiles cascade;

create table profiles(
  id uuid primary key references auth.users on delete cascade,
  name text, avatar text default '🦊', ui_lang text default 'ar',
  goal int default 20, placement int default 0, onboarded boolean default false,
  xp int default 0, streak int default 0, best_streak int default 0, last_day date,
  created_at timestamptz default now());
create table xp_log(user_id uuid references auth.users on delete cascade, day date, xp int default 0, primary key(user_id,day));
create table units(id int primary key, level int not null, ord int not null, title jsonb, tip jsonb, icon text, color text);
create table lessons(id int primary key, unit_id int references units on delete cascade, ord int not null,
  kind text default 'lesson' check (kind in ('lesson','exam')), title jsonb);
create table exercises(
  id bigint primary key, lesson_id int references lessons on delete cascade,
  kind text not null check (kind in ('mc','type','match','order')),
  ins text, prompt text, html boolean default false, options jsonb, say text,
  after_text text, note_key text, note_text text, big boolean default false);
create table exercise_texts(exercise_id bigint references exercises on delete cascade, lang text, prompt text, options jsonb,
  primary key(exercise_id,lang));
create table exercise_keys(exercise_id bigint primary key references exercises on delete cascade, answer jsonb not null);
create table answers(id bigserial primary key, user_id uuid references auth.users on delete cascade,
  exercise_id bigint references exercises on delete cascade, ok boolean, ctx text, run text, at timestamptz default now());
create index on answers(user_id, run);
create table lesson_progress(user_id uuid references auth.users on delete cascade, lesson_id int references lessons on delete cascade,
  stars int default 0, done_at timestamptz default now(), primary key(user_id,lesson_id));
create table review_items(user_id uuid references auth.users on delete cascade, exercise_id bigint references exercises on delete cascade,
  box int default 0, due date default current_date, primary key(user_id,exercise_id));
create table awarded_runs(user_id uuid references auth.users on delete cascade, run text, primary key(user_id,run));

-- حماية البيانات: لا يستطيع أي متصفح قراءة الجداول أو كتابتها مباشرة.
-- كل شيء يمر عبر الدوال أدناه، والإجابات الصحيحة لا تُرسَل أبدًا قبل أن يجيب المتعلم.
alter table profiles enable row level security;       alter table xp_log enable row level security;
alter table units enable row level security;          alter table lessons enable row level security;
alter table exercises enable row level security;      alter table exercise_texts enable row level security;
alter table exercise_keys enable row level security;  alter table answers enable row level security;
alter table lesson_progress enable row level security; alter table review_items enable row level security;
alter table awarded_runs enable row level security;

create function handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin insert into profiles(id,name) values (new.id, coalesce(new.raw_user_meta_data->>'name','')); return new; end $$;
create trigger on_signup after insert on auth.users for each row execute function handle_new_user();

create view lesson_seq as
  select l.id, l.kind, u.level, row_number() over (order by u.level,u.ord,l.ord) as seq
  from lessons l join units u on u.id=l.unit_id;

create function norm_de(s text) returns text language sql immutable as $$
  select btrim(regexp_replace(regexp_replace(replace(replace(replace(replace(lower(s),'ä','ae'),'ö','oe'),'ü','ue'),'ß','ss'),
         '[.,!?;:’''…]','','g'),'\s+',' ','g')) $$;

create function lesson_open(p_user uuid, p_lesson int) returns boolean language plpgsql stable security definer set search_path=public as $$
declare v_prev int; v_lvl int; v_plvl int; v_pl int;
begin
  select prev, level, plvl into v_prev, v_lvl, v_plvl
    from (select id, level, lag(id) over (order by seq) prev, lag(level) over (order by seq) plvl from lesson_seq) x where id=p_lesson;
  if not found then return false; end if;
  if v_prev is null then return true; end if;
  select placement into v_pl from profiles where id=p_user;
  v_pl := coalesce(v_pl,0);
  if v_lvl < v_pl then return true; end if;
  if v_lvl = v_pl and (v_plvl is null or v_plvl < v_lvl) then return true; end if;
  return exists(select 1 from lesson_progress where user_id=p_user and lesson_id in (v_prev,p_lesson));
end $$;

create function award(p_xp int, p_run text) returns jsonb language plpgsql security definer set search_path=public as $$
declare p profiles; v_streak int; v_today int; n int;
begin
  select * into p from profiles where id=auth.uid();
  if p_run is not null then
    insert into awarded_runs(user_id,run) values (p.id,p_run) on conflict do nothing;
    get diagnostics n = row_count;
    if n=0 then
      select coalesce(xp,0) into v_today from xp_log where user_id=p.id and day=current_date;
      return jsonb_build_object('xp',0,'streak',p.streak,'today',coalesce(v_today,0),'goal',p.goal);
    end if;
  end if;
  if p.last_day = current_date then v_streak := p.streak;
  elsif p.last_day = current_date-1 then v_streak := p.streak+1;
  else v_streak := 1; end if;
  update profiles set xp=xp+p_xp, streak=v_streak, best_streak=greatest(best_streak,v_streak), last_day=current_date where id=p.id;
  insert into xp_log(user_id,day,xp) values (p.id,current_date,p_xp) on conflict (user_id,day) do update set xp=xp_log.xp+excluded.xp;
  select xp into v_today from xp_log where user_id=p.id and day=current_date;
  return jsonb_build_object('xp',p_xp,'streak',v_streak,'today',v_today,'goal',p.goal);
end $$;

create function get_me() returns jsonb language sql stable security definer set search_path=public as $$
  select to_jsonb(p)
    || jsonb_build_object('today', coalesce((select xp from xp_log where user_id=p.id and day=current_date),0),
         'due', (select count(*) from review_items where user_id=p.id and due<=current_date),
         'week', (select jsonb_agg(jsonb_build_object('day',d::date,'xp',coalesce(x.xp,0)) order by d)
                  from generate_series(current_date-6,current_date,'1 day') d left join xp_log x on x.user_id=p.id and x.day=d::date))
  from profiles p where p.id=auth.uid() $$;

create function get_path() returns jsonb language sql stable security definer set search_path=public as $$
  select coalesce(jsonb_agg(jsonb_build_object('id',u.id,'level',u.level,'title',u.title,'tip',u.tip,'icon',u.icon,'color',u.color,
    'lessons',(select jsonb_agg(jsonb_build_object('id',l.id,'kind',l.kind,'title',l.title,'open',lesson_open(auth.uid(),l.id),
                 'stars',coalesce(lp.stars,-1)) order by l.ord)
               from lessons l left join lesson_progress lp on lp.lesson_id=l.id and lp.user_id=auth.uid() where l.unit_id=u.id))
    order by u.level,u.ord),'[]'::jsonb)
  from units u $$;

create function ex_json(e exercises, tp text, topt jsonb) returns jsonb language sql immutable as $$
  select jsonb_build_object('id',e.id,'kind',e.kind,'ins',e.ins,'prompt',coalesce(tp,e.prompt),'html',e.html,
         'options',coalesce(topt,e.options),'say',e.say,'big',e.big) $$;

create function get_lesson(p_lesson int, p_lang text default 'en') returns jsonb language plpgsql security definer set search_path=public as $$
declare v_kind text;
begin
  if auth.uid() is null or not lesson_open(auth.uid(),p_lesson) then raise exception 'locked'; end if;
  select kind into v_kind from lessons where id=p_lesson;
  return coalesce((select jsonb_agg(x) from (
      select ex_json(e,t.prompt,t.options) x
      from exercises e left join exercise_texts t on t.exercise_id=e.id and t.lang=p_lang
      where e.lesson_id=p_lesson
      order by case when v_kind='exam' then random() else e.id::float8 end
      limit case when v_kind='exam' then 20 else 1000 end) q),'[]'::jsonb);
end $$;

create function get_placement(p_lang text default 'en') returns jsonb language sql security definer set search_path=public as $$
  select coalesce(jsonb_agg(ex_json(z.e,z.tp,z.topt) order by z.lv, z.rn),'[]'::jsonb) from (
    select u.level lv, e, t.prompt tp, t.options topt, row_number() over (partition by u.level order by random()) rn
    from exercises e join lessons l on l.id=e.lesson_id join units u on u.id=l.unit_id
    left join exercise_texts t on t.exercise_id=e.id and t.lang=p_lang
    where u.level between 1 and 5 and e.kind in ('mc','type') and coalesce(e.ins,'') not like 'i_listen%') z
  where z.rn <= case z.lv when 1 then 5 when 2 then 5 when 3 then 4 else 3 end $$;

create function get_review(p_lang text default 'en', p_n int default 12) returns jsonb language sql security definer set search_path=public as $$
  select coalesce(jsonb_agg(x),'[]'::jsonb) from (
    select ex_json(e,t.prompt,t.options) x
    from review_items ri join exercises e on e.id=ri.exercise_id
    left join exercise_texts t on t.exercise_id=e.id and t.lang=p_lang
    where ri.user_id=auth.uid() and ri.due<=current_date and e.kind<>'match'
    order by ri.box, random() limit p_n) q $$;

create function check_answer(p_ex bigint, p_lang text default 'en', p_choice int default null, p_text text default null,
                             p_pairs jsonb default null, p_ctx text default 'lesson', p_run text default null)
returns jsonb language plpgsql security definer set search_path=public as $$
declare e exercises; k jsonb; t exercise_texts; v_ok boolean:=false; v_correct text; opts jsonb;
begin
  if auth.uid() is null then raise exception 'auth'; end if;
  select * into e from exercises where id=p_ex;
  if e.id is null then raise exception 'no exercise'; end if;
  select answer into k from exercise_keys where exercise_id=p_ex;
  select * into t from exercise_texts where exercise_id=p_ex and lang=p_lang;
  opts := coalesce(t.options, e.options);
  if e.kind='mc' then
    v_ok := p_choice is not null and p_choice = (k->>'i')::int;
    v_correct := opts->>((k->>'i')::int);
  elsif e.kind='type' then
    v_ok := exists(select 1 from jsonb_array_elements_text(k->'a') a where norm_de(a)=norm_de(coalesce(p_text,'')));
    v_correct := k->'a'->>0;
  elsif e.kind='order' then
    v_ok := norm_de(coalesce(p_text,''))=norm_de(k->>'s');
    v_correct := k->>'s';
  else
    v_ok := p_pairs is not null and p_pairs = k->'m';
  end if;
  insert into answers(user_id,exercise_id,ok,ctx,run) values (auth.uid(),p_ex,v_ok,p_ctx,p_run);
  if p_ctx <> 'placement' then
    insert into review_items(user_id,exercise_id,box,due)
      values (auth.uid(),p_ex, case when v_ok then 1 else 0 end, current_date + case when v_ok then 1 else 0 end)
    on conflict (user_id,exercise_id) do update set
      box = case when v_ok then least(review_items.box+1,5) else 0 end,
      due = current_date + (case when v_ok then (array[0,1,3,7,21,60])[least(review_items.box+1,5)+1] else 0 end);
  end if;
  return jsonb_build_object('ok',v_ok,'correct',v_correct,'after',e.after_text,'note_key',e.note_key,'note',e.note_text,
                            'm',case when e.kind='match' then k->'m' end);
end $$;

create function complete_lesson(p_lesson int, p_run text) returns jsonb language plpgsql security definer set search_path=public as $$
declare v_kind text; v_level int; v_total int; v_ok int; v_ratio numeric; v_stars int; v_pass boolean; v_xp int; v_n int;
begin
  if not lesson_open(auth.uid(),p_lesson) then raise exception 'locked'; end if;
  select l.kind,u.level into v_kind,v_level from lessons l join units u on u.id=l.unit_id where l.id=p_lesson;
  select count(*), count(*) filter (where ok) into v_total, v_ok from (
    select distinct on (a.exercise_id) a.exercise_id, a.ok from answers a join exercises e on e.id=a.exercise_id
    where a.user_id=auth.uid() and a.run=p_run and e.lesson_id=p_lesson order by a.exercise_id, a.at) f;
  select count(*) into v_n from exercises where lesson_id=p_lesson;
  v_ratio := v_ok::numeric/greatest(v_total,1);
  if v_kind='exam' then v_pass := v_total>=least(20,v_n) and v_ratio>=0.9;
  else v_pass := v_total>=ceil(v_n*0.5); end if;
  v_stars := case when v_ratio=1 then 3 when v_ratio>=0.8 then 2 else 1 end;
  v_xp := case when v_kind='exam' then (case when v_pass then 30 else 5 end) else (case when v_pass then 10 + (case when v_stars=3 then 5 else 0 end) else 0 end) end;
  if v_pass then
    insert into lesson_progress(user_id,lesson_id,stars) values (auth.uid(),p_lesson,v_stars)
    on conflict (user_id,lesson_id) do update set stars=greatest(lesson_progress.stars,excluded.stars), done_at=now();
  end if;
  return award(v_xp,p_run) || jsonb_build_object('pass',v_pass,'stars',v_stars,'correct',v_ok,'total',v_total,
         'level_done',(v_kind='exam' and v_pass),'level',v_level,'kind',v_kind);
end $$;

create function complete_review(p_run text) returns jsonb language plpgsql security definer set search_path=public as $$
declare v_n int;
begin
  select count(distinct exercise_id) into v_n from answers where user_id=auth.uid() and run=p_run and ctx='review';
  if v_n<3 then return jsonb_build_object('xp',0,'pass',false); end if;
  return award(8,p_run) || jsonb_build_object('pass',true,'kind','review');
end $$;

create function finish_placement(p_run text) returns jsonb language plpgsql security definer set search_path=public as $$
declare r record; v_pl int:=0; v_now int;
begin
  for r in
    select u.level lv, count(*) n, count(*) filter (where f.ok) k from (
      select distinct on (a.exercise_id) a.exercise_id, a.ok from answers a
      where a.user_id=auth.uid() and a.run=p_run and a.ctx='placement' order by a.exercise_id, a.at) f
    join exercises e on e.id=f.exercise_id join lessons l on l.id=e.lesson_id join units u on u.id=l.unit_id
    group by u.level order by u.level
  loop
    if r.k::numeric/r.n >= 0.6 then v_pl := r.lv+1; else exit; end if;
  end loop;
  update profiles set placement=greatest(placement,v_pl), onboarded=true where id=auth.uid();
  select placement into v_now from profiles where id=auth.uid();
  return jsonb_build_object('placement',v_now);
end $$;

create function update_profile(p_name text default null, p_avatar text default null, p_goal int default null,
                               p_lang text default null, p_onboarded boolean default null)
returns void language sql security definer set search_path=public as $$
  update profiles set name=coalesce(p_name,name), avatar=coalesce(p_avatar,avatar),
    goal=coalesce(least(greatest(p_goal,5),100),goal), ui_lang=coalesce(p_lang,ui_lang), onboarded=coalesce(p_onboarded,onboarded)
  where id=auth.uid() $$;

revoke all on lesson_seq from anon, authenticated;
revoke execute on all functions in schema public from public, anon, authenticated;
grant execute on function get_me(), get_path(), get_lesson(int,text), get_placement(text), get_review(text,int),
  check_answer(bigint,text,int,text,jsonb,text,text), complete_lesson(int,text), complete_review(text),
  finish_placement(text), update_profile(text,text,int,text,boolean) to authenticated;

-- حسابات أُنشئت قبل هذه النسخة تحصل على ملف تعريف جديد
insert into profiles(id,name) select id, coalesce(raw_user_meta_data->>'name','') from auth.users on conflict do nothing;
