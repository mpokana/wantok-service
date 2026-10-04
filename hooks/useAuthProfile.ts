import type { Session } from '@supabase/supabase-js';
import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';

export type Profile = {
  id: string;
  full_name?: string | null;
  phone?: string | null;
  is_provider?: boolean | null;
  is_driver?: boolean | null;
  is_driver_approved?: boolean | null;
  is_admin?: boolean | null;
};

type UserRoleRow = {
  role_code: string;
  expires_at: string | null;
};

type UseAuthProfileResult = {
  session: Session | null;
  profile: Profile | null;
  roles: string[];
  hasRole: (role: string) => boolean;
  loading: boolean;
  error: string | null;
  refreshProfile: () => Promise<void>;
};

const errorMessage = (error: unknown, fallback: string) =>
  error instanceof Error ? error.message : fallback;

export function useAuthProfile(): UseAuthProfileResult {
  const [session, setSession] = useState<Session | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [roles, setRoles] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadRoles = async (userId: string) => {
    const { data, error: rolesError } = await supabase
      .from('user_roles')
      .select('role_code, expires_at')
      .eq('user_id', userId);

    if (rolesError) {
      console.log('Load roles error', rolesError);
      setRoles([]);
      return;
    }

    const now = Date.now();
    const activeRoles = ((data || []) as UserRoleRow[])
      .filter((row) => !row.expires_at || Date.parse(row.expires_at) > now)
      .map((row) => row.role_code);

    setRoles([...new Set(activeRoles)]);
  };

  const loadProfile = async (currentSession: Session | null) => {
    if (!currentSession?.user) {
      setProfile(null);
      setRoles([]);
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);

      const { data, error: profileError } = await supabase
        .from('profiles')
        .select(`
          id,
          full_name,
          phone,
          is_provider,
          is_driver,
          is_driver_approved,
          is_admin
        `)
        .eq('id', currentSession.user.id)
        .single();

      if (profileError) {
        if (
          profileError.code === 'PGRST116' ||
          profileError.message?.includes('No rows')
        ) {
          const { data: inserted, error: insertError } = await supabase
            .from('profiles')
            .insert({
              id: currentSession.user.id,
              full_name: currentSession.user.email,
            })
            .select(`
              id,
              full_name,
              phone,
              is_provider,
              is_driver,
              is_driver_approved,
              is_admin
            `)
            .single();

          if (insertError) {
            console.log('Create profile error', insertError);
            setError(insertError.message);
            setProfile(null);
            setRoles([]);
            return;
          }

          setProfile(inserted as Profile);
        } else {
          console.log('Load profile error', profileError);
          setError(profileError.message);
          setProfile(null);
          setRoles([]);
          return;
        }
      } else {
        setProfile(data as Profile);
      }

      await loadRoles(currentSession.user.id);
    } catch (caught) {
      console.log('Load profile exception', caught);
      setError(errorMessage(caught, 'Failed to load profile'));
      setProfile(null);
      setRoles([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    let isMounted = true;

    const init = async () => {
      try {
        const {
          data: { session: initialSession },
          error: sessionError,
        } = await supabase.auth.getSession();

        if (!isMounted) return;

        if (sessionError) {
          setError(sessionError.message);
          setSession(null);
          setProfile(null);
          setRoles([]);
          setLoading(false);
          return;
        }

        setSession(initialSession ?? null);
        await loadProfile(initialSession ?? null);
      } catch (caught) {
        if (!isMounted) return;
        console.log('Auth init error', caught);
        setError(errorMessage(caught, 'Failed to load session'));
        setLoading(false);
      }
    };

    init();

    const { data: authListener } = supabase.auth.onAuthStateChange(
      (_event, newSession) => {
        setSession(newSession);
        if (newSession?.user) {
          loadProfile(newSession);
        } else {
          setProfile(null);
          setRoles([]);
          setLoading(false);
        }
      },
    );

    return () => {
      isMounted = false;
      authListener.subscription.unsubscribe();
    };
  }, []);

  const refreshProfile = async () => {
    await loadProfile(session);
  };

  const hasRole = (role: string) => roles.includes(role);

  return {
    session,
    profile,
    roles,
    hasRole,
    loading,
    error,
    refreshProfile,
  };
}
