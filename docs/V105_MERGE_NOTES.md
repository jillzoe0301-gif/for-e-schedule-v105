# FOR-e V105 Merged Production

本版本以 V103 正式版完整介面為基礎，保留原本電腦版與手機版功能，並加入 V105 調整：

- 登入頁名稱統一為「FOR-e 共享排程系統」
- 移除首頁測試帳號、Demo 快速登入、重置測試資料按鈕
- 保留 V103 的電腦版完整排程介面
- 保留 V103 的手機版底部導覽
- 依角色顯示導覽權限：
  - staff：一般、個人、今日
  - supervisor / adminStaff：一般、外務、個人、今日、通知
  - admin：一般、外務、個人、今日、統計、通知
- 一般行事曆重複行程刪除加入：
  - 僅刪除這天
  - 刪除今日起後續行程
  - 刪除全部行程
  - 刪除全部超過 20 筆需輸入 DELETE
- 外務行事曆刪除增加同步取消一般行事曆提示

部署方式：
1. 解壓縮後整包覆蓋 GitHub 專案根目錄
2. `npm install`
3. `npm run build`
4. `git add . && git commit -m "FOR-e V105 merged production" && git push`
5. Vercel 會自動重新部署
