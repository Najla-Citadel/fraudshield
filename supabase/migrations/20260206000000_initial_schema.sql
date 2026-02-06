-- FraudShield Initial Schema (Reverse-Engineered)
-- Date: 2026-02-06

-- 1. PROFILES
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  full_name TEXT,
  avatar_seed TEXT DEFAULT 'Felix',
  extra JSONB DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. BEHAVIORAL EVENTS
CREATE TABLE IF NOT EXISTS public.behavioral_events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  event_type TEXT NOT NULL,
  screen_name TEXT,
  duration_ms INTEGER,
  meta JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. TRANSACTIONS
CREATE TABLE IF NOT EXISTS public.transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  amount NUMERIC(15, 2) NOT NULL,
  merchant TEXT,
  device_id TEXT,
  geo_location JSONB DEFAULT '{}'::jsonb,
  meta JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. SUBSCRIPTION PLANS
CREATE TABLE IF NOT EXISTS public.subscription_plans (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  price NUMERIC(10, 2) NOT NULL,
  features JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. USER SUBSCRIPTIONS
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  plan_id UUID REFERENCES public.subscription_plans ON DELETE SET NULL,
  status TEXT DEFAULT 'active', -- active, cancelled, expired
  started_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. POINTS TRANSACTIONS
CREATE TABLE IF NOT EXISTS public.points_transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  change INTEGER NOT NULL,
  reason TEXT,
  meta JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. ROW LEVEL SECURITY (RLS) - Basic Policies
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.behavioral_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.points_transactions ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can view and update their own profile
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Behavioral Events: Users can insert their own events and view them
CREATE POLICY "Users can insert own events" ON public.behavioral_events FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can view own events" ON public.behavioral_events FOR SELECT USING (auth.uid() = user_id);

-- Transactions: Users can view and insert their own transactions
CREATE POLICY "Users can view own transactions" ON public.transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own transactions" ON public.transactions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Subscription Plans: Everyone can view
CREATE POLICY "Everyone can view plans" ON public.subscription_plans FOR SELECT TO authenticated USING (true);

-- User Subscriptions: Users can view their own, insert new ones
CREATE POLICY "Users can view own subscriptions" ON public.user_subscriptions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own subscriptions" ON public.user_subscriptions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Points Transactions: Users can view their own
CREATE POLICY "Users can view own points history" ON public.points_transactions FOR SELECT USING (auth.uid() = user_id);

-- 8. SEED DATA (Subscription Plans)
INSERT INTO public.subscription_plans (name, price, features) VALUES
('Free Protection', 0.00, '["Basic risk check", "Weekly scam news", "Standard support"]'),
('Standard Protection', 5.90, '["Real-time phishing alerts", "Unlimited fraud checks", "Email protection", "Priority support"]'),
('Elite Shield', 12.90, '["AI-powered deepfake detection", "24/7 fraud concierge", "Identity theft insurance", "Credit monitoring"]');
