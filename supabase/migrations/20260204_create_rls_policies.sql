-- Migration: Row Level Security (RLS) Policies
-- Created: 2026-02-04
-- Description: Enables RLS and creates security policies for all tables

-- ============================================
-- ENABLE RLS ON ALL TABLES
-- ============================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.points_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.behavioral_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scam_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fraud_checks ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PROFILES POLICIES
-- ============================================
-- Users can view their own profile
CREATE POLICY "Users can view own profile"
    ON public.profiles
    FOR SELECT
    USING (auth.uid() = id);

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile"
    ON public.profiles
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON public.profiles
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- ============================================
-- SUBSCRIPTION_PLANS POLICIES
-- ============================================
-- Anyone (authenticated) can view subscription plans
CREATE POLICY "Anyone can view subscription plans"
    ON public.subscription_plans
    FOR SELECT
    USING (true);

-- ============================================
-- USER_SUBSCRIPTIONS POLICIES
-- ============================================
-- Users can view their own subscriptions
CREATE POLICY "Users can view own subscriptions"
    ON public.user_subscriptions
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own subscriptions
CREATE POLICY "Users can insert own subscriptions"
    ON public.user_subscriptions
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own subscriptions
CREATE POLICY "Users can update own subscriptions"
    ON public.user_subscriptions
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================
-- POINTS_TRANSACTIONS POLICIES
-- ============================================
-- Users can view their own points transactions
CREATE POLICY "Users can view own points transactions"
    ON public.points_transactions
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own points transactions
CREATE POLICY "Users can insert own points transactions"
    ON public.points_transactions
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ============================================
-- BEHAVIORAL_EVENTS POLICIES
-- ============================================
-- Users can view their own behavioral events
CREATE POLICY "Users can view own behavioral events"
    ON public.behavioral_events
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own behavioral events
CREATE POLICY "Users can insert own behavioral events"
    ON public.behavioral_events
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ============================================
-- TRANSACTIONS POLICIES
-- ============================================
-- Users can view their own transactions
CREATE POLICY "Users can view own transactions"
    ON public.transactions
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own transactions
CREATE POLICY "Users can insert own transactions"
    ON public.transactions
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ============================================
-- SCAM_REPORTS POLICIES
-- ============================================
-- Users can view their own scam reports
CREATE POLICY "Users can view own scam reports"
    ON public.scam_reports
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own scam reports
CREATE POLICY "Users can insert own scam reports"
    ON public.scam_reports
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own scam reports
CREATE POLICY "Users can update own scam reports"
    ON public.scam_reports
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================
-- FRAUD_CHECKS POLICIES
-- ============================================
-- Users can view their own fraud checks
CREATE POLICY "Users can view own fraud checks"
    ON public.fraud_checks
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own fraud checks
CREATE POLICY "Users can insert own fraud checks"
    ON public.fraud_checks
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ============================================
-- ADMIN POLICIES (Future Enhancement)
-- ============================================
-- Note: Admin policies can be added later for managing scam reports
-- Example: CREATE POLICY "Admins can view all scam reports"
--    ON public.scam_reports FOR SELECT
--    USING (auth.jwt() ->> 'role' = 'admin');
