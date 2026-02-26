-- Seed data para EstudiososApp
-- Los usuarios de prueba se crean desde Supabase Auth (Dashboard o CLI),
-- ya que las contraseñas son gestionadas por Supabase Auth y no se almacenan en la tabla users.

-- Equipo de prueba
INSERT INTO teams (name, invite_code)
VALUES ('Los Estudiosos FC', 'ESTUDI2025')
ON CONFLICT (invite_code) DO NOTHING;
