// Edge Function: assign-feedback
// Genera las filas en feedback_assignments al pasar un partido a estado 'evaluating'.
//
// Algoritmo de asignación:
//   - Capitán del partido: 6 receptores al azar.
//   - Jugador normal: 3 receptores al azar.
//   - Se garantiza que cada jugador recibe mínimo 2 devoluciones.
//   - Sin autoasignaciones ni duplicados (match_id, giver_id, receiver_id).
//
// Invocación: POST /functions/v1/assign-feedback
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

    // Usar la clave de servicio para omitir RLS al generar asignaciones.
    // El mapeo giver→receiver nunca se expone fuera de esta función.
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // 1. Obtener datos del partido
    const { data: match, error: matchError } = await supabase
      .from("matches")
      .select("id, captain_id, status")
      .eq("id", match_id)
      .single();

    if (matchError || !match) {
      return new Response(
        JSON.stringify({ error: "Match not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    if (match.status !== "played") {
      return new Response(
        JSON.stringify({ error: "Match must be in 'played' status to assign feedback" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // 2. Obtener participantes del partido
    const { data: matchPlayers, error: playersError } = await supabase
      .from("match_players")
      .select("team_member_id")
      .eq("match_id", match_id);

    if (playersError || !matchPlayers || matchPlayers.length < 2) {
      return new Response(
        JSON.stringify({ error: "Match must have at least 2 players" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const playerIds = matchPlayers
      .map((p) => p.team_member_id as string | null)
      .filter((id): id is string => id !== null && id !== undefined);

    // 3. Generar asignaciones con el algoritmo de devolución
    const assignments = buildAssignments(playerIds, match.captain_id as string | null, match_id);

    // 4. Insertar las filas en feedback_assignments
    const { error: insertError } = await supabase
      .from("feedback_assignments")
      .insert(assignments);

    if (insertError) {
      return new Response(
        JSON.stringify({ error: insertError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // 5. Actualizar el estado del partido a 'evaluating'
    const { error: updateError } = await supabase
      .from("matches")
      .update({ status: "evaluating" })
      .eq("id", match_id);

    if (updateError) {
      return new Response(
        JSON.stringify({ error: updateError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    return new Response(
      JSON.stringify({ success: true, assignments_count: assignments.length }),
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
// Algoritmo de asignación
// ---------------------------------------------------------------------------

type FeedbackRow = {
  match_id: string;
  giver_id: string;
  receiver_id: string;
};

/** Mezcla un array en el lugar usando Fisher-Yates y devuelve el mismo array. */
function shuffle<T>(arr: T[]): T[] {
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

/**
 * Construye las filas de feedback_assignments según las reglas de negocio:
 *   - Capitán: 6 receptores al azar (o todos los disponibles si el equipo es pequeño).
 *   - Jugador normal: 3 receptores al azar.
 *   - Cada jugador recibe mínimo MIN_RECEIVED devoluciones (redistribución si es necesario).
 *   - Sin autoasignaciones ni pares duplicados.
 */
export function buildAssignments(
  playerIds: string[],
  captainId: string | null,
  matchId: string,
): FeedbackRow[] {
  const MIN_RECEIVED = 2;
  const CAPTAIN_QUOTA = 6;
  const NORMAL_QUOTA = 3;

  // Conjunto de pares ya asignados: `${giverId}:${receiverId}`
  const assignedPairs = new Set<string>();

  // Contador de devoluciones recibidas por jugador
  const receivedCount: Record<string, number> = {};
  for (const id of playerIds) receivedCount[id] = 0;

  const rows: FeedbackRow[] = [];

  /** Asigna `quota` receptores al azar a `giverId`, respetando restricciones. */
  function assignForGiver(giverId: string, quota: number): void {
    // Candidatos: todos excepto el propio jugador, mezclados al azar
    const candidates = shuffle(playerIds.filter((id) => id !== giverId));
    const actualQuota = Math.min(quota, candidates.length);
    let assigned = 0;

    for (const receiverId of candidates) {
      if (assigned >= actualQuota) break;
      const pairKey = `${giverId}:${receiverId}`;
      if (!assignedPairs.has(pairKey)) {
        assignedPairs.add(pairKey);
        receivedCount[receiverId]++;
        rows.push({ match_id: matchId, giver_id: giverId, receiver_id: receiverId });
        assigned++;
      }
    }
  }

  // Asignar primero al capitán (cuota mayor)
  if (captainId && playerIds.includes(captainId)) {
    assignForGiver(captainId, CAPTAIN_QUOTA);
  }

  // Asignar a jugadores normales
  for (const playerId of playerIds) {
    if (playerId === captainId) continue;
    assignForGiver(playerId, NORMAL_QUOTA);
  }

  // Redistribución: garantizar mínimo MIN_RECEIVED devoluciones por jugador
  for (const receiverId of playerIds) {
    while (receivedCount[receiverId] < MIN_RECEIVED) {
      // Buscar un donante que aún no haya asignado a este receptor
      const potentialGivers = shuffle(
        playerIds.filter(
          (id) => id !== receiverId && !assignedPairs.has(`${id}:${receiverId}`),
        ),
      );

      if (potentialGivers.length === 0) {
        // No hay más donantes posibles (todos ya asignaron a este jugador).
        // En equipos muy pequeños puede ser matemáticamente imposible garantizar MIN_RECEIVED.
        console.warn(
          `[assign-feedback] No se pudo garantizar mínimo ${MIN_RECEIVED} devoluciones ` +
            `para el jugador ${receiverId} en el partido ${matchId}.`,
        );
        break;
      }

      const giverId = potentialGivers[0];
      const pairKey = `${giverId}:${receiverId}`;
      assignedPairs.add(pairKey);
      receivedCount[receiverId]++;
      rows.push({ match_id: matchId, giver_id: giverId, receiver_id: receiverId });
    }
  }

  return rows;
}
