// Edge Function: close-match
// Cierra un partido (status → 'closed') y dispara generate-summary.
//
// Condiciones de cierre (al menos una debe cumplirse):
//   (a) Todos los participantes completaron su evaluación (evaluation_status = 'completed').
//   (b) Se venció el tiempo límite (evaluation_deadline < now).
//   (c) Cierre manual explícito por Admin (campo force = true en el body).
//
// Autorización:
//   - Admin del equipo dueño del partido (verificado vía JWT → team_members.is_admin).
//   - Sistema (Edge Function invocada con SUPABASE_SERVICE_ROLE_KEY, sin JWT de usuario).
//
// Invocación: POST /functions/v1/close-match
// Body JSON: { "match_id": "<uuid>", "force"?: true }
// Header:    Authorization: Bearer <jwt>

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  // Preflight CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const match_id: string | undefined = body?.match_id;
    // force=true habilita el cierre manual por Admin incluso si no se cumple (a) ni (b)
    const force: boolean = body?.force === true;

    if (!match_id) {
      return new Response(
        JSON.stringify({ error: "match_id is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Cliente de servicio para operaciones privilegiadas (bypass RLS)
    const serviceClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // ---------------------------------------------------------------------------
    // 1. Verificar autorización
    // ---------------------------------------------------------------------------
    const authHeader = req.headers.get("Authorization") ?? "";
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const isServiceRole = authHeader === `Bearer ${serviceKey}`;

    if (!isServiceRole) {
      // Llamada desde un usuario: verificar que sea Admin del equipo del partido.
      // Creamos un cliente con el JWT del usuario para respetar RLS en la verificación.
      const userClient = createClient(
        Deno.env.get("SUPABASE_URL")!,
        Deno.env.get("SUPABASE_ANON_KEY")!,
        { global: { headers: { Authorization: authHeader } } },
      );

      // Obtener el uid del usuario autenticado
      const { data: { user }, error: userError } = await userClient.auth.getUser();

      if (userError || !user) {
        return new Response(
          JSON.stringify({ error: "Unauthorized" }),
          { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }

      // Obtener el team_id del partido (sin restricción de estado aún)
      const { data: matchTeam, error: matchTeamError } = await serviceClient
        .from("matches")
        .select("team_id")
        .eq("id", match_id)
        .single();

      if (matchTeamError || !matchTeam) {
        return new Response(
          JSON.stringify({ error: "Match not found" }),
          { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }

      // Verificar que el usuario es Admin del equipo
      const { data: membership, error: membershipError } = await serviceClient
        .from("team_members")
        .select("id")
        .eq("team_id", matchTeam.team_id)
        .eq("user_id", user.id)
        .eq("is_admin", true)
        .eq("is_active", true)
        .single();

      if (membershipError || !membership) {
        return new Response(
          JSON.stringify({ error: "Forbidden: user is not an admin of this team" }),
          { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }
    }

    // ---------------------------------------------------------------------------
    // 2. Obtener datos del partido y verificar estado
    // ---------------------------------------------------------------------------
    const { data: match, error: matchError } = await serviceClient
      .from("matches")
      .select("id, team_id, status, evaluation_deadline")
      .eq("id", match_id)
      .single();

    if (matchError || !match) {
      return new Response(
        JSON.stringify({ error: "Match not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    if (match.status !== "evaluating") {
      return new Response(
        JSON.stringify({
          error: `Match must be in 'evaluating' status to be closed (current: '${match.status}')`,
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ---------------------------------------------------------------------------
    // 3. Verificar condiciones de cierre
    // ---------------------------------------------------------------------------

    // (a) Todos los participantes completaron su evaluación
    const { data: pendingPlayers, error: pendingError } = await serviceClient
      .from("match_players")
      .select("id")
      .eq("match_id", match_id)
      .eq("evaluation_status", "pending");

    if (pendingError) {
      return new Response(
        JSON.stringify({ error: pendingError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const allCompleted = (pendingPlayers?.length ?? 0) === 0;

    // (b) Se venció el tiempo límite
    const deadlineExpired =
      match.evaluation_deadline !== null &&
      new Date(match.evaluation_deadline) <= new Date();

    // Se debe cumplir al menos una condición
    if (!allCompleted && !deadlineExpired && !force) {
      return new Response(
        JSON.stringify({
          error:
            "No closure condition met: evaluations are still pending, deadline has not expired, and force=true was not set",
        }),
        { status: 422, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Determinar la razón de cierre (informativa).
    // Precedencia: all_completed > deadline_expired > manual.
    const closeReason = allCompleted
      ? "all_completed"
      : deadlineExpired
      ? "deadline_expired"
      : "manual";

    // ---------------------------------------------------------------------------
    // 4. Marcar jugadores con evaluación pendiente como 'incomplete'
    // ---------------------------------------------------------------------------
    if (!allCompleted) {
      const { error: incompleteError } = await serviceClient
        .from("match_players")
        .update({ evaluation_status: "incomplete" })
        .eq("match_id", match_id)
        .eq("evaluation_status", "pending");

      if (incompleteError) {
        return new Response(
          JSON.stringify({ error: incompleteError.message }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }
    }

    // ---------------------------------------------------------------------------
    // 5. Cambiar el estado del partido a 'closed'
    // ---------------------------------------------------------------------------
    const { error: updateError } = await serviceClient
      .from("matches")
      .update({ status: "closed" })
      .eq("id", match_id);

    if (updateError) {
      return new Response(
        JSON.stringify({ error: updateError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ---------------------------------------------------------------------------
    // 6. Invocar generate-summary para el partido
    // ---------------------------------------------------------------------------
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;

    const summaryResponse = await fetch(
      `${supabaseUrl}/functions/v1/generate-summary`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          // Usar la clave de servicio para que generate-summary también bypass RLS
          Authorization: `Bearer ${serviceKey}`,
          apikey: serviceKey,
        },
        body: JSON.stringify({ match_id }),
      },
    );

    if (!summaryResponse.ok) {
      const summaryError = await summaryResponse.text();
      console.warn(
        `[close-match] generate-summary respondió con status ${summaryResponse.status}: ${summaryError}`,
      );
      // No se revierte el cierre del partido; el resumen puede regenerarse manualmente.
      return new Response(
        JSON.stringify({
          success: true,
          close_reason: closeReason,
          warning: `Match closed but generate-summary failed: ${summaryError}`,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    return new Response(
      JSON.stringify({ success: true, close_reason: closeReason }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
