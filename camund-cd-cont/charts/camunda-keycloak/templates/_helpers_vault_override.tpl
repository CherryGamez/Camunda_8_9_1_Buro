{{/*
  ------------------------------------------------------------------
  Updated implementation of "common.tplvalues.render".
  Goal:
    • Preserve the original templating behaviour for normal values.
    • **Skip `tpl`** when the value looks like a Vault secret block
      (contains the literal string "{{- with secret").
    • **Never emit a stray `$`** outside of a {{ … }} expression.
  ------------------------------------------------------------------
*/}}
{{- define "common.tplvalues.render" -}}
{{/*
  Input (passed via the dict from the chart):
    .value   – raw value (string or map)
    .context – the Helm context (the dot)
    .scope   – optional relative‑scope (used by the upstream helper)
*/}}

{{- /* Preserve original type handling: strings stay strings,
      maps / slices become YAML when rendered. */ -}}
{{- $val := typeIs "string" .value | ternary .value (.value | toYaml) -}}

{{/* --------------------------------------------------------------
    Vault‑secret detection – return the value *as‑is*.
   -------------------------------------------------------------- */}}
{{- if contains "{{- with secret" (toJson .value) -}}
    {{- $val }}   {{/* literal output, no tpl evaluation */}}

{{/* --------------------------------------------------------------
    Normal Helm templating – unchanged from upstream.
   -------------------------------------------------------------- */}}
{{- else if contains "{{" (toJson .value) -}}
    {{- if .scope -}}
        {{- /* Keep the exact wrapping logic the upstream helper used.
               All variables stay inside the outer {{ … }} delimiters,
               so no stray $$ appears. */ -}}
        {{- tpl (cat "{{- with $.RelativeScope -}}" $val "{{- end }}") (merge (dict "RelativeScope" .scope) .context) -}}
    {{- else -}}
        {{- tpl $val .context -}}
    {{- end }}

{{/* --------------------------------------------------------------
    Plain string / yaml – no templating needed.
   -------------------------------------------------------------- */}}
{{- else -}}
    {{- $val }}
{{- end }}
{{- end -}}