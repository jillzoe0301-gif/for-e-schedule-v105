ㄝ # FOR-e 共享排程系統｜V103 正式版專案包

這包是 V103 測試版轉正式版用的 Next.js + Supabase + Vercel 專案骨架。

> 重要：`public/v103-prototype.html` 是 V103 原型畫面，保留給你對照功能與版面。正式多人同步資料需要逐步把功能接到 Supabase 資料表。

## 1. 建立 Supabase

1. 到 Supabase 建立 Project。
2. 進入 `SQL Editor` → `New Query`。
3. 打開本專案 `supabase/schema.sql`。
4. 全選複製，貼到 SQL Editor。
5. 按 `Run`。
6. 到 `Table Editor` 檢查是否有資料表：profiles、people、schedules、field_schedules 等。

## 2. 設定環境變數

複製 `.env.example` 成 `.env.local`，填入你的 Supabase 資訊：

```bash
NEXT_PUBLIC_SUPABASE_URL=...
NEXT_PUBLIC_SUPABASE_ANON_KEY=...
SUPABASE_SERVICE_ROLE_KEY=...
```

Supabase 新版可能沒有 `service_role key` 字樣，請找 `Secret key`，貼到 `SUPABASE_SERVICE_ROLE_KEY`。

## 3. 本機測試

```bash
npm install
npm run dev
```

開啟：

```text
http://localhost:3000
```

## 4. 部署到 Vercel

1. 把整個資料夾上傳到 GitHub。
2. 到 Vercel → Add New → Project → Import Git Repository。
3. Framework Preset 會自動偵測 Next.js。
4. 到 Settings → Environment Variables 貼上：
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY`
5. Deploy。

## 5. 後續正式開發順序

建議依序接：

1. Supabase Auth 登入與 profiles 角色。
2. people 人員資料。
3. schedules 一般行事曆 CRUD。
4. field_schedules 外務行事曆 CRUD 與同步一般行事曆。
5. 外務明細、個人行程明細。
6. 統計報表與服務紀錄單。
7. LINE Messaging API 自動通知。
8. Audit Log 與權限細化。

## 6. V103 原型

正式版網頁啟動後，可點首頁的「開啟 V103 原型畫面」，或直接開：

```text
/v103-prototype.html
```

## V103 root entrance fix
This package redirects `/` to `/v103-prototype.html`, so the deployed Vercel homepage opens the V103 system prototype directly instead of the starter/checklist page.
