-- Migration: Seed Subscription Plans
-- Created: 2026-02-04
-- Description: Inserts initial subscription plan data

-- ============================================
-- FIX: Ensure 'name' is unique (Required for ON CONFLICT)
-- ============================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'subscription_plans_name_key'
    ) THEN
        ALTER TABLE public.subscription_plans ADD CONSTRAINT subscription_plans_name_key UNIQUE (name);
    END IF;
END $$;

-- ============================================
-- INSERT SUBSCRIPTION PLANS
-- ============================================
INSERT INTO public.subscription_plans (name, price, features)
VALUES
    (
        'Free',
        0.00,
        '[
            "Basic fraud checking",
            "Limited daily checks (5/day)",
            "Access to fraud awareness tips",
            "Basic scam reporting"
        ]'::jsonb
    ),
    (
        'Standard',
        5.90,
        '[
            "Unlimited fraud checking",
            "Advanced risk analysis",
            "Priority scam reporting",
            "Access to fraud awareness tips",
            "Email alerts for new scams",
            "50 points bonus on signup"
        ]'::jsonb
    ),
    (
        'Premium',
        9.90,
        '[
            "All Standard features",
            "Real-time fraud alerts",
            "Voice call scam detection",
            "QR code fraud analysis",
            "Document verification",
            "Priority customer support",
            "100 points bonus on signup",
            "Ad-free experience"
        ]'::jsonb
    )
ON CONFLICT (name) DO NOTHING;
