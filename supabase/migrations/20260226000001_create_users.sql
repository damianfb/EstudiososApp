-- Migration: create_users
-- Esta tabla es el perfil público del usuario.
-- El id debe coincidir con auth.users.id (Supabase Auth maneja la autenticación).
-- password_hash NO se incluye aquí.

CREATE TABLE IF NOT EXISTS users (
  id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  name       VARCHAR(100) NOT NULL,
  email      VARCHAR(150) UNIQUE NOT NULL,
  avatar_url TEXT,
  created_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Cualquier usuario autenticado puede leer perfiles
CREATE POLICY "Authenticated users can read profiles"
  ON users
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Cada usuario solo puede actualizar su propio perfil
CREATE POLICY "Users can update own profile"
  ON users
  FOR UPDATE
  USING (id = auth.uid());
