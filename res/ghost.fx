// Ghost car shader — colour and alpha driven from Lua (gColor / gAlpha)
// Normal state : blue-cyan, semi-transparent
// Hit state    : orange-red, more opaque  (set by Lua on proximity)
float4 main(PS_IN pin) {
  float ndotl = pin.NormalW.y * 0.35 + 0.65;
  return float4(gColor.rgb * ndotl, gAlpha);
}
