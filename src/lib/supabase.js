import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://ifpopyplwpmrapaofimi.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_kazC7uOBFXz8-AuIfXD7mA_cBb4_EtH';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

export async function getSession() {
  const { data: { session } } = await supabase.auth.getSession();
  return session;
}

export async function requireAuth(redirectTo = '/login') {
  const session = await getSession();
  if (!session) {
    window.location.href = redirectTo;
    return null;
  }
  return session;
}

export async function getProfile(userId) {
  const { data } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .single();
  return data;
}

export async function getWalletBalance(userId) {
  const { data } = await supabase
    .from('wallet_transactions')
    .select('amount, type')
    .eq('user_id', userId);

  if (!data) return 0;
  return data.reduce((sum, t) => sum + (t.type === 'credit' ? t.amount : -t.amount), 0);
}
