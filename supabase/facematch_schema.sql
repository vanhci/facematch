-- FaceMatch 数据库表结构

-- 用户表
CREATE TABLE IF NOT EXISTS facematch_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nickname TEXT NOT NULL DEFAULT 'unnamed',
  avatar_url TEXT,
  phone TEXT UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_login TIMESTAMPTZ NOT NULL DEFAULT now(),
  tier TEXT NOT NULL DEFAULT 'free' CHECK (tier IN ('free', 'premium')),
  premium_expires_at TIMESTAMPTZ,
  bonus_credits INTEGER NOT NULL DEFAULT 0,
  daily_usage INTEGER NOT NULL DEFAULT 0,
  daily_usage_date DATE NOT NULL DEFAULT CURRENT_DATE
);

-- 仿妆历史表
CREATE TABLE IF NOT EXISTS facematch_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES facematch_users(id) ON DELETE CASCADE,
  reference_image_url TEXT,
  selfie_image_url TEXT,
  result_image_url TEXT,
  analysis JSONB,
  status TEXT NOT NULL DEFAULT 'completed' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 用量记录表
CREATE TABLE IF NOT EXISTS facematch_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES facematch_users(id) ON DELETE CASCADE,
  action TEXT NOT NULL CHECK (action IN ('analyze', 'transfer', 'full_match')),
  cost_credits INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_facematch_history_user ON facematch_history(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_facematch_usage_user ON facematch_usage(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_facematch_usage_date ON facematch_usage(user_id, created_at::date);
CREATE INDEX IF NOT EXISTS idx_facematch_users_phone ON facematch_users(phone) WHERE phone IS NOT NULL;

-- 启用 RLS
ALTER TABLE facematch_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE facematch_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE facematch_usage ENABLE ROW LEVEL SECURITY;

-- RLS 策略：用户只能看自己的数据
CREATE POLICY "users_view_own" ON facematch_users
  FOR SELECT USING (id = auth.uid());
CREATE POLICY "users_update_own" ON facematch_users
  FOR UPDATE USING (id = auth.uid());

CREATE POLICY "history_view_own" ON facematch_history
  FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "history_insert_own" ON facematch_history
  FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "history_delete_own" ON facematch_history
  FOR DELETE USING (user_id = auth.uid());

CREATE POLICY "usage_view_own" ON facematch_usage
  FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "usage_insert_own" ON facematch_usage
  FOR INSERT WITH CHECK (user_id = auth.uid());
