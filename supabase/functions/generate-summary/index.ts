// Edge Function: generate-summary
// Calcula y persiste el resumen del partido en match_summary.
//
// Lógica:
//   1. Calcular el/los MVP(s): jugador(es) con más votos en mvp_votes (puede haber empate).
//   2. Calcular el protagonista de la jugada: jugador con más votos en play_of_match_votes.
//   3. Seleccionar 2-3 descripciones al azar sólo de los votos al protagonista ganador.
//   4. Insertar (o actualizar) el registro en match_summary.
//
// Anonimato: voter_id y el autor de cada descripción nunca se consultan ni exponen.
//
// Invocación: POST /functions/v1/generate-summary
// Body JSON: { "match_id": "<uuid>" }
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
    const { match_id } = await req.json();

    if (!match_id) {
      return new Response(
        JSON.stringify({ error: "match_id is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Usar la clave de servicio para omitir RLS al consolidar datos del resumen.
    // voter_id y el autor de cada descripción nunca se seleccionan ni exponen.
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // ---------------------------------------------------------------------------
    // 1. Verificar que el partido existe y está en estado 'closed'
    // ---------------------------------------------------------------------------
    const { data: match, error: matchError } = await supabase
      .from("matches")
      .select("id, status")
      .eq("id", match_id)
      .single();

    if (matchError || !match) {
      return new Response(
        JSON.stringify({ error: "Match not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    if (match.status !== "closed") {
      return new Response(
        JSON.stringify({
          error: `Match must be in 'closed' status to generate summary (current: '${match.status}')`,
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ---------------------------------------------------------------------------
    // 2. Calcular MVP(s): jugador(es) con más votos en mvp_votes
    //    Solo se selecciona voted_for_id — voter_id nunca se consulta.
    // ---------------------------------------------------------------------------
    const { data: mvpVotes, error: mvpError } = await supabase
      .from("mvp_votes")
      .select("voted_for_id")
      .eq("match_id", match_id);

    if (mvpError) {
      return new Response(
        JSON.stringify({ error: mvpError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const mvpIds = computeTopIds(
      (mvpVotes ?? []).map((v) => v.voted_for_id as string),
    );

    // ---------------------------------------------------------------------------
    // 3. Calcular el protagonista de la jugada del partido
    //    Solo se selecciona protagonist_id y description — voter_id nunca se consulta.
    // ---------------------------------------------------------------------------
    const { data: playVotes, error: playError } = await supabase
      .from("play_of_match_votes")
      .select("protagonist_id, description")
      .eq("match_id", match_id);

    if (playError) {
      return new Response(
        JSON.stringify({ error: playError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const votes = playVotes ?? [];

    // Protagonista: el más votado (primer lugar, sin empate requerido)
    const topProtagonists = computeTopIds(
      votes.map((v) => v.protagonist_id as string),
    );
    const playProtagonistId = topProtagonists.length > 0 ? topProtagonists[0] : null;

    // Descripciones: sólo de votos al protagonista ganador, 2-3 al azar
    let playDescriptions: string[] | null = null;
    if (playProtagonistId !== null) {
      const winnerDescriptions = votes
        .filter((v) => v.protagonist_id === playProtagonistId)
        .map((v) => v.description as string);

      const selected = pickRandom(winnerDescriptions, 2, 3);
      playDescriptions = selected.length > 0 ? selected : null;
    }

    // ---------------------------------------------------------------------------
    // 4. Insertar (o actualizar) el registro en match_summary
    // ---------------------------------------------------------------------------
    const { error: upsertError } = await supabase
      .from("match_summary")
      .upsert(
        {
          match_id,
          mvp_ids: mvpIds,
          play_protagonist_id: playProtagonistId,
          play_descriptions: playDescriptions,
          generated_at: new Date().toISOString(),
        },
        { onConflict: "match_id" },
      );

    if (upsertError) {
      return new Response(
        JSON.stringify({ error: upsertError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});

// ---------------------------------------------------------------------------
// Utilidades
// ---------------------------------------------------------------------------

/**
 * Dado un array de IDs (con repeticiones), devuelve los IDs que aparecen
 * con la frecuencia máxima. Si el array está vacío, devuelve [].
 */
export function computeTopIds(ids: string[]): string[] {
  if (ids.length === 0) return [];

  const counts: Record<string, number> = {};
  for (const id of ids) {
    counts[id] = (counts[id] ?? 0) + 1;
  }

  const maxCount = Math.max(...Object.values(counts));
  return Object.entries(counts)
    .filter(([, count]) => count === maxCount)
    .map(([id]) => id);
}

/** Mezcla un array en el lugar usando Fisher-Yates y devuelve el mismo array. */
function shuffle<T>(arr: T[]): T[] {
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

/**
 * Selecciona entre `min` y `max` elementos al azar de `items`.
 * Si hay menos elementos que `min`, devuelve todos los disponibles.
 */
export function pickRandom<T>(items: T[], min: number, max: number): T[] {
  if (items.length === 0) return [];
  const count = items.length <= min
    ? items.length
    : Math.min(items.length, min + Math.floor(Math.random() * (max - min + 1)));
  return shuffle([...items]).slice(0, count);
}
