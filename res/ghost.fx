// Ghost car shader — Fresnel-style rim highlight
// Silhouette edges (horizontal normals) = bright, opaque
// Center panels (vertical normals)      = dark, nearly transparent
// gAlpha : base transparency  |  gHit : 0=normal, 1=hit (red-orange tint)
float4 main(PS_IN pin) {
  // Rim factor: 0 on top/bottom faces, 1 on vertical side faces / edges
  float rim = pow(saturate(1.0 - abs(pin.NormalW.y)), 2.0);

  // Gentle top-light diffuse
  float ndotl = pin.NormalW.y * 0.35 + 0.65;

  // Icy-blue base, white-blue rim
  float3 color = float3(0.45, 0.82, 1.0) * ndotl;
  color = lerp(color, float3(0.85, 0.95, 1.0), rim * 0.80);

  // Classic ghost alpha: nearly invisible center, solid silhouette
  float alpha = saturate(lerp(gAlpha * 0.25, gAlpha * 2.0, rim));

  // Hit: blend to red-orange, raise alpha
  color = lerp(color, float3(1.0, 0.20, 0.05), gHit * 0.70);
  alpha = saturate(alpha + gHit * 0.35);

  return float4(color, alpha);
}
