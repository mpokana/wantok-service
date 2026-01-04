// lib/supabase.ts
import { createClient } from '@supabase/supabase-js';

// ✅ Your Supabase project credentials
const SUPABASE_URL = 'https://dzedrtxkdupxorbinqva.supabase.co';
const SUPABASE_ANON_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR6ZWRydHhrZHVweG9yYmlucXZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI2OTA5MTAsImV4cCI6MjA3ODI2NjkxMH0.7UcMMfgsp7VavmwDaWXapw4A4t2riUW2ugL3mKlpv4M';

// ✅ Create and export the Supabase client
export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true, // Keep user logged in between app restarts
    autoRefreshToken: true, // Refresh expired sessions automatically
    detectSessionInUrl: false, // Prevent unwanted redirects on mobile
  },
});
