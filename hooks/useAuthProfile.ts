// app/hooks/useAuthProfile.ts

import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import type { Session } from '@supabase/supabase-js';

export type Profile = {
  id: string;
  full_name?: string | null;
  phone?: string | null;
  is_provider?: boolean | null;
  is_driver?: boolean | null;
  is_driver_approved?: boolean | null;
  is_admin?: boolean | null;
};

type UseAuthProfileResult = {
  session: Session | null;
  profile: Profile | null;
  loading: boolean;
  error: string | null;
  refreshProfile: () => Promise<void>;
};

export function useAuthProfile(): UseAuthProfileResult {
  const [session, setSession] = useState<Session | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  // Load initial session + listen for changes
  useEffect(() => {
    let isMounted = true;

    const init = async () => {
      try {
        const {
          data: { session },
          error,
        } = await supabase.auth.getSession();

        if (!isMounted) return;

        if (error) {
          setError(error.message);
          setSession(null);
          setProfile(null);
          setLoading(false);
          return;
        }

        setSession(session ?? null);

        if (session?.user) {
          await loadProfile(session);
        } else {
          setProfile(null);
          setLoading(false);
        }
      } catch (err: any) {
        if (!isMounted) return;
        console.log('Auth init error', err);
        setError(err.message || 'Failed to load session');
        setLoading(false);
      }
    };

    init();

    const {
      data: authListener,
    } = supabase.auth.onAuthStateChange((_event, newSession) => {
      setSession(newSession);
      if (newSession?.user) {
        loadProfile(newSession);
      } else {
        setProfile(null);
      }
    });

    return () => {
      isMounted = false;
      authListener.subscription.unsubscribe();
    };
  }, []);

  const loadProfile = async (currentSession: Session | null) => {
    if (!currentSession?.user) {
      setProfile(null);
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);

      const { data, error } = await supabase
        .from('profiles')
        .select(
          `
          id,
          full_name,
          phone,
          is_provider,
          is_driver,
          is_driver_approved,
          is_admin
        `,
        )
        .eq('id', currentSession.user.id)
        .single();

      if (error) {
        // If no row yet, create a basic one
        if (error.code === 'PGRST116' || error.message?.includes('No rows')) {
          const { data: inserted, error: insertError } = await supabase
            .from('profiles')
            .insert({
              id: currentSession.user.id,
              full_name: currentSession.user.email,
            })
            .select(
              `
              id,
              full_name,
              phone,
              is_provider,
              is_driver,
              is_driver_approved,
              is_admin
            `,
            )
            .single();

          if (insertError) {
            console.log('Create profile error', insertError);
            setError(insertError.message);
            setProfile(null);
          } else {
            setProfile(inserted as Profile);
          }
        } else {
          console.log('Load profile error', error);
          setError(error.message);
          setProfile(null);
        }
      } else {
        setProfile(data as Profile);
      }
    } catch (err: any) {
      console.log('Load profile exception', err);
      setError(err.message || 'Failed to load profile');
      setProfile(null);
    } finally {
      setLoading(false);
    }
  };

  const refreshProfile = async () => {
    await loadProfile(session);
  };

  return {
    session,
    profile,
    loading,
    error,
    refreshProfile,
  };
}
