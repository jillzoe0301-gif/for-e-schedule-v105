import './globals.css';
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'FOR-e 共享排程系統',
  description: 'V103 正式版 Next.js + Supabase 專案包',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="zh-Hant">
      <body>{children}</body>
    </html>
  );
}
