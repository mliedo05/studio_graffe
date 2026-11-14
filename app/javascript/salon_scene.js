// Studio Graffé — salón 3D en line art para el hero de la portada.
// Se carga bajo demanda desde salon_hero_controller (solo en la portada).
import * as THREE from "three";
import { mergeGeometries } from "three/addons/utils/BufferGeometryUtils.js";
import { RoundedBoxGeometry } from "three/addons/geometries/RoundedBoxGeometry.js";

export function createSalonScene({ hero, canvas, steps, bars, hint }) {
const MOBILE = innerWidth < 760;
const REDUCE = matchMedia("(prefers-reduced-motion: reduce)").matches;
const clamp = (x, a = 0, b = 1) => Math.min(b, Math.max(a, x));
const rand = (a, b) => a + Math.random() * (b - a);

// ── Renderer ──────────────────────────────────────────────────────────
const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, powerPreference: "high-performance" });
renderer.setPixelRatio(Math.min(devicePixelRatio, MOBILE ? 1.5 : 2));
renderer.outputColorSpace = THREE.SRGBColorSpace;
const scene = new THREE.Scene();
const BG = 0xEDE4D5, INK = 0x5C4B39;
scene.background = new THREE.Color(BG);
scene.fog = new THREE.Fog(BG, 16, 58); // las líneas lejanas se desvanecen en el beige
const cam = new THREE.PerspectiveCamera(50, 1, 0.05, 160);

// ── Texturas procedurales ─────────────────────────────────────────────
function canvasTex(w, h, draw, rx = 1, ry = 1, color = true) {
  const c = document.createElement("canvas"); c.width = w; c.height = h;
  draw(c.getContext("2d"), w, h);
  const t = new THREE.CanvasTexture(c);
  t.wrapS = t.wrapT = THREE.RepeatWrapping; t.repeat.set(rx, ry);
  if (color) t.colorSpace = THREE.SRGBColorSpace;
  t.anisotropy = renderer.capabilities.getMaxAnisotropy();
  return t;
}
function logoTexture() {
  return canvasTex(2048, 820, (g, w, h) => {
    g.clearRect(0, 0, w, h); g.fillStyle = "#5C4B39"; g.strokeStyle = "#5C4B39";
    g.font = "italic 600 470px 'Noto Serif', Georgia, serif"; g.fillText("Graffé", 380, 650);
    g.font = "600 92px Inter, Arial, sans-serif"; g.fillText("STUDIO", 40, 650);
    for (let k = 0; k < 5; k++) { g.lineWidth = 18 - k * 2; g.beginPath(); g.moveTo(400, 250 + k * 30);
      g.bezierCurveTo(800, 60 + k * 26, 1100, 330 + k * 18, 1500, 90 + k * 22); g.stroke(); }
  }, 1, 1);
}

// ── Materiales ────────────────────────────────────────────────────────
const fill = new THREE.MeshBasicMaterial({ color: BG, side: THREE.DoubleSide, polygonOffset: true, polygonOffsetFactor: 1, polygonOffsetUnits: 1 });
const logoMat = new THREE.MeshBasicMaterial({ map: logoTexture(), transparent: true });
const M = new Proxy({ logo: logoMat }, { get: (o, k) => o[k] || fill }); // un solo material: todo es papel beige
document.fonts?.ready.then(() => { if (stopped) return; M.logo.map?.dispose(); M.logo.map = logoTexture(); M.logo.needsUpdate = true; });
let stopped = false, raf = 0;

// ── Helpers ───────────────────────────────────────────────────────────
const castables = [];
function add(mesh, parent = scene, cast = true) { parent.add(mesh); if (cast) castables.push(mesh); mesh.receiveShadow = true; return mesh; }
function box(w, h, d, m, x, y, z, p, cast = true) { const o = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), m); o.position.set(x, y, z); return add(o, p, cast); }
function rbox(w, h, d, r, m, x, y, z, p) { const o = new THREE.Mesh(new RoundedBoxGeometry(w, h, d, 4, r), m); o.position.set(x, y, z); return add(o, p); }
function cyl(rt, rb, h, m, x, y, z, p, seg = 32, cast = true) { const o = new THREE.Mesh(new THREE.CylinderGeometry(rt, rb, h, seg), m); o.position.set(x, y, z); return add(o, p, cast); }
function sph(r, m, x, y, z, p) { const o = new THREE.Mesh(new THREE.SphereGeometry(r, 24, 16), m); o.position.set(x, y, z); return add(o, p); }
function group(x, y, z, ry = 0) { const g = new THREE.Group(); g.position.set(x, y, z); g.rotation.y = ry; scene.add(g); return g; }

// ── Dimensiones de la sala ────────────────────────────────────────────
const FY = -2.6, CY = 4.4, W = 9, Z0 = 4, Z1 = -42;

// ── Arquitectura ──────────────────────────────────────────────────────
const floor = add(new THREE.Mesh(new THREE.PlaneGeometry(W * 2, Z0 - Z1), M.floor), scene, false);
floor.rotation.x = -Math.PI / 2; floor.position.set(0, FY, (Z0 + Z1) / 2);
[-W, W].forEach(x => { const w = add(new THREE.Mesh(new THREE.PlaneGeometry(Z0 - Z1, CY - FY), M.plaster), scene, false);
  w.rotation.y = x < 0 ? Math.PI / 2 : -Math.PI / 2; w.position.set(x, (CY + FY) / 2, (Z0 + Z1) / 2); });
// zócalo
[-W + .02, W - .02].forEach(x => box(.04, .12, Z0 - Z1, M.black, x, FY + .06, (Z0 + Z1) / 2, scene, false));
// vigas
for (let z = 1; z > Z1; z -= 7.5) box(W * 2, .75, 1, M.concrete, 0, CY - .37, z, scene, false);
box(1.2, .75, Z0 - Z1, M.concrete, -W + .6, CY - .37, (Z0 + Z1) / 2, scene, false);
// cañerías con codos
[[-7.6, .11], [-7.15, .08], [-6.8, .06], [6.9, .13]].forEach(([x, r], i) => {
  const p = cyl(r, r, Z0 - Z1, M.pipe, x, CY - .9 - i * .07, (Z0 + Z1) / 2, scene, 16, false); p.rotation.x = Math.PI / 2;
  for (let z = -2; z > Z1; z -= 6) { const c = cyl(r * 1.25, r * 1.25, .1, M.pipe, x, p.position.y, z, scene, 16, false); c.rotation.x = Math.PI / 2; }
});
// ductos de aire con rejilla
[[2.5, -6], [-1.5, -27]].forEach(([x, z]) => {
  box(2.2, .5, 7, M.pipe, x, CY - 1.05, z, scene, false);
  for (let k = 0; k < 4; k++) box(1.1 - k * .22, .02, 1.1 - k * .22, k % 2 ? M.pipe : M.matte, x, CY - 1.31 - k * .01, z + 2, scene, false);
});

// ── Rieles con focos (con luces reales) ───────────────────────────────
const spotLights = [];
function track(x, z0, z1, aimX, lightsEvery = 0) {
  const len = Math.abs(z1 - z0), zc = (z0 + z1) / 2;
  box(.07, .07, len, M.black, x, CY - 1.0, zc, scene, false);
  [z0 + .3, z1 - .3].forEach(z => cyl(.008, .008, 1, M.black, x, CY - .5, z, scene, 6, false));
  let n = 0;
  for (let z = Math.max(z0, z1) - .4; z > Math.min(z0, z1); z -= 1.25, n++) {
    const s = new THREE.Group(); s.position.set(x, CY - 1.1, z); scene.add(s);
    const body = new THREE.Mesh(new THREE.CylinderGeometry(.11, .11, .42, 24), M.black); body.rotation.z = (aimX - x) * .08; body.rotation.x = .5; s.add(body);
    const lens = new THREE.Mesh(new THREE.CircleGeometry(.095, 24), M.spotLens); lens.position.set(0, -.21, 0); lens.rotation.x = Math.PI / 2; body.add(lens);
    if (lightsEvery && n % lightsEvery === 0 && !MOBILE) {
      const L = new THREE.SpotLight(0xfff1dd, 5, 10, .5, .7, 2); L.position.copy(s.position);
      L.target.position.set(aimX, FY, z - 1.2); scene.add(L, L.target); spotLights.push(L);
    }
  }
}
track(-2.6, 0, -18, -4.5, 4); track(2.8, -3, -18, 4.5, 4); track(0, -26, -38, 1.5, 4); track(-6.2, 2, -8, -8, 0);

// ── Ventanal al fondo ─────────────────────────────────────────────────
const winW = W * 2 - .6, winH = 5.0, winY = .2;
add(new THREE.Mesh(new THREE.PlaneGeometry(winW + 4, winH + 1), M.sky), scene, false).position.set(0, winY, Z1 - .5);
box(W * 2, CY - (winY + winH / 2), .3, M.plaster, 0, (CY + winY + winH / 2) / 2, Z1, scene, false);
box(W * 2, .55, .35, M.porcelain, 0, FY + .27, Z1 + .05, scene, false);
for (let x = -W + .3; x <= W; x += 3.0) box(.1, winH, .12, M.black, x, winY, Z1 + .05, scene, true);
box(winW, .1, .12, M.black, 0, winY + winH / 2, Z1 + .05, scene, false);
box(winW, .08, .12, M.black, 0, winY - winH / 2 + .3, Z1 + .05, scene, false);
for (let x = -W + 1.8, k = 0; x < W; x += 3.0, k++) {
  const h = [2.3, 1.7, 2.8, 2.0, 1.5, 2.5][k % 6];
  box(2.85, h, .03, M.roller, x, winY + winH / 2 - h / 2, Z1 + .2, scene, true);
  box(2.9, .1, .1, M.pipe, x, winY + winH / 2 + .02, Z1 + .2, scene, false);
}
// ── Recepción / lounge con logo ───────────────────────────────────────
add(new THREE.Mesh(new THREE.PlaneGeometry(4.6, 1.85), M.logo), scene, false).position.set(-W + .03, 1.25, -9.2);
scene.children.at(-1).rotation.y = Math.PI / 2;
[-11.1, -9.4, -7.7].forEach((z, i) => {
  const g = group(-W + .2, 2.75 + [0, .2, .05][i], z);
  add(new THREE.Mesh(new THREE.CylinderGeometry(.12, .12, .3, 20), M.black), g).rotation.z = Math.PI / 2;
  const L = new THREE.SpotLight(0xffe2b8, 6, 4, .5, .8, 2); L.position.set(-W + .4, 2.6, z); L.target.position.set(-W, .6, z); scene.add(L, L.target);
});
// alfombra
box(4.2, .02, 5, M.fabric, -6.4, FY + .01, -9.3, scene, false).material = new THREE.MeshStandardMaterial({ color: 0xe9e3da, roughness: 1 });
// sillones (gris y crema con manta negra)
function loungeChair(x, z, ry, throwOn) {
  const g = group(x, FY, z, ry);
  rbox(1.7, .45, 1.15, .1, M.fabric, 0, .65, 0, g);
  rbox(1.7, .95, .28, .1, M.fabric, 0, 1.25, -.48, g);
  if (throwOn) { rbox(1.2, .9, .06, .03, M.throw, .1, 1.3, -.32, g).rotation.x = -.1; rbox(1.0, .05, .7, .03, M.throw, .1, .9, -.05, g); }
  [-1, 1].forEach(s => {
    box(.04, .04, 1.2, M.black, s * .9, 1.0, 0, g); box(.04, .04, 1.2, M.black, s * .9, .02, 0, g);
    box(.04, 1.0, .04, M.black, s * .9, .5, .58, g); box(.04, 1.0, .04, M.black, s * .9, .5, -.58, g);
  });
}
loungeChair(-7.6, -10.6, Math.PI / 2, false); loungeChair(-7.2, -7.2, Math.PI / 2.6, true);
// mesita + vela rosada + florero con eucalipto
cyl(.42, .42, .04, M.black, -7.7, -1.45, -8.8); cyl(.025, .025, 1.1, M.black, -7.7, -2.05, -8.8, scene, 8); cyl(.3, .3, .04, M.black, -7.7, FY + .02, -8.8);
cyl(.12, .12, .14, M.pink, -7.55, -1.36, -8.65);
const vase = new THREE.Mesh(new THREE.TorusGeometry(.13, .06, 16, 32), M.porcelain); vase.position.set(-7.85, -1.2, -8.9); vase.rotation.y = Math.PI / 2; add(vase);
for (let k = 0; k < 9; k++) { const st = cyl(.006, .006, .8, M.leaf, -7.85, -.75, -8.9, scene, 4); st.rotation.set(rand(-.4, .4), 0, rand(-.4, .4));
  for (let j = 0; j < 5; j++) sph(.035, new THREE.MeshStandardMaterial({ color: 0x8d9c8a, roughness: .8 }), -7.85 + st.rotation.z * -.8 * j / 5, -.9 + j * .1, -8.9 + st.rotation.x * .8 * j / 5); }
// mesa redonda de madera (primer plano)
cyl(1.2, 1.2, .06, M.oak, -4.6, -1.05, -4.2); cyl(.06, .06, 1.5, M.black, -4.6, -1.85, -4.2, scene, 12); cyl(.5, .55, .04, M.black, -4.6, FY + .02, -4.2);
// plantas
const leafShape = new THREE.Shape(); leafShape.moveTo(0, 0); leafShape.bezierCurveTo(.13, .1, .13, .34, 0, .55); leafShape.bezierCurveTo(-.13, .34, -.13, .1, 0, 0);
const leafGeo = new THREE.ShapeGeometry(leafShape, 8);
function plant(x, z, s = 1, pot = M.matte) {
  cyl(.32 * s, .25 * s, .7 * s, pot, x, FY + .35 * s, z);
  const n = MOBILE ? 60 : 170, im = new THREE.InstancedMesh(leafGeo, M.leaf, n), d = new THREE.Object3D(), col = new THREE.Color();
  for (let k = 0; k < n; k++) {
    const a = k * 2.399, h = Math.pow(k / n, .75), r = (.08 + Math.sin(h * 3.0) * .55) * s;
    d.position.set(x + Math.cos(a) * r, FY + (.7 + h * 1.9) * s, z + Math.sin(a) * r);
    d.rotation.set(rand(-.5, .5) + .9 * (1 - h), -a + Math.PI / 2, rand(-.5, .5)); d.scale.setScalar(s * rand(.8, 1.45)); d.updateMatrix(); im.setMatrixAt(k, d.matrix);
    im.setColorAt(k, col.setHSL(rand(.27, .33), rand(.35, .55), rand(.16, .3)));
  }
  im.castShadow = !MOBILE; im.receiveShadow = true; scene.add(im);
}
plant(-8.2, -12.3, 1.1); plant(-8.2, -5.6, .8); plant(8.2, -23.5, 1); plant(7.9, -14.2, .9);
// lámparas triángulo con ampolleta
const triGeo = new THREE.TorusGeometry(.38, .018, 4, 3);
[[-5.7, 2.2, -6.2], [-5.35, 1.55, -6.6], [-5.8, .95, -6.35]].forEach(([x, y, z]) => {
  add(new THREE.Mesh(triGeo, M.black)).position.set(x, y, z); scene.children.at(-1).rotation.z = Math.PI / 2;
  sph(.075, M.bulb, x, y - .05, z); cyl(.004, .004, CY - 1 - y, M.black, x, (CY - 1 + y) / 2, z, scene, 4, false);
});
cyl(.25, .25, .04, M.black, -5.6, CY - 1, -6.4, scene, 24, false);
const triL = new THREE.PointLight(0xffbe6e, 4, 7, 2); triL.position.set(-5.5, 1.4, -6.4); scene.add(triL);

// ── Repisas con productos (tienda) ────────────────────────────────────
const bottleMats = [0x111111, 0xf5f3ef, 0xc9a96e, 0x2f2f2f, 0xe8d8c3, 0x7a5c3e].map(c => new THREE.MeshPhysicalMaterial({ color: c, roughness: .25, clearcoat: .8 }));
for (let row = 0; row < 3; row++) {
  const y = -.4 + row * .75, z = -15.2;
  box(.35, .05, 3.4, M.black, -W + .2, y, z);
  for (let k = 0; k < 11; k++) {
    const h = rand(.25, .48), r = rand(.05, .09), m = bottleMats[(k + row) % bottleMats.length];
    const b = cyl(r, r, h, m, -W + .22, y + h / 2 + .03, z - 1.5 + k * .3, scene, 16);
    cyl(r * .5, r * .5, .06, M.black, -W + .22, y + h + .06, z - 1.5 + k * .3, scene, 12);
  }
}

// ── Tocadores (espejos en arco, LED, flores) ──────────────────────────
const archShape = new THREE.Shape();
archShape.moveTo(-.9, 0); archShape.lineTo(.9, 0); archShape.lineTo(.9, 1.35); archShape.absarc(0, 1.35, .9, 0, Math.PI, false); archShape.lineTo(-.9, 0);
const archFrame = new THREE.ExtrudeGeometry(archShape, { depth: .05, bevelEnabled: true, bevelSize: .03, bevelThickness: .02, curveSegments: 40 });
const archMirror = new THREE.ShapeGeometry(archShape, 40);
const leds = [];
const tubShape = new THREE.Shape(); tubShape.absarc(0, 0, .64, -.3, Math.PI + .3, false); tubShape.absarc(0, 0, .5, Math.PI + .3, -.3, true);
const tubGeo = new THREE.ExtrudeGeometry(tubShape, { depth: .5, bevelEnabled: true, bevelSize: .055, bevelThickness: .07, bevelSegments: 6, curveSegments: 40 });
const baseGeo = new THREE.LatheGeometry([[0, .11], [.1, .105], [.16, .085], [.3, .05], [.48, .03], [.55, .012], [.56, 0]].map(([a, b]) => new THREE.Vector2(a, b)), 64);
function chair(x, z, ry) {
  const g = group(x, FY, z, ry);
  rbox(1.06, .24, 1.0, .11, M.leather, 0, 1.13, .05, g);
  rbox(.92, .1, .86, .05, M.leather, 0, 1.28, .07, g);
  const tub = new THREE.Mesh(tubGeo, M.leather); tub.rotation.x = -Math.PI / 2; tub.position.set(0, 1.3, .1); add(tub, g);
  const b = new THREE.Mesh(baseGeo, M.chrome); add(b, g);
  cyl(.055, .055, .55, M.chrome, 0, .4, 0, g); cyl(.085, .085, .32, M.black, 0, .86, 0, g);
  const foot = new THREE.Mesh(new THREE.TorusGeometry(.3, .016, 10, 40, Math.PI), M.chrome); foot.position.set(0, .42, .25); foot.rotation.x = Math.PI / 2; add(foot, g);
  [-1, 1].forEach(s => { const a = cyl(.012, .012, .5, M.chrome, s * .3, .68, .22, g, 8); a.rotation.x = .75; });
  return g;
}
// silla de terciopelo rosa con costuras verticales y patas doradas
function velvetChair(x, z, ry) {
  const g = group(x, FY, z, ry);
  rbox(1.0, .2, .92, .09, M.velvet, 0, .98, .02, g);
  for (let k = -5; k <= 5; k++) { const a = k * .24; const fl = new THREE.Mesh(new THREE.CapsuleGeometry(.075, .42, 6, 12), M.velvet); fl.position.set(Math.sin(a) * .54, 1.42 - Math.abs(k) * .016, -Math.cos(a) * .4 + .02); fl.rotation.set(-.14, 0, 0); add(fl, g); }
  const ring = new THREE.Mesh(new THREE.TorusGeometry(.56, .012, 10, 48, Math.PI * 1.1), M.gold); ring.rotation.x = Math.PI / 2 - .05; ring.rotation.z = Math.PI + 1.42; ring.position.set(0, 1.18, .0); add(ring, g);
  [[-.4, .36], [.4, .36], [-.36, -.36], [.36, -.36]].forEach(([dx, dz]) => { const l = cyl(.017, .012, .98, M.gold, dx * 1.12, .46, dz * 1.12, g, 10); l.rotation.set(dz * .28, 0, -dx * .28); });
}
// ramo: peonías y hortensias en canasto tejido
const petalGeo = new THREE.SphereGeometry(1, 10, 7);
const flowerCols = [0xf3c7c9, 0xeca8ae, 0xf6efe0, 0xefe2c8, 0xe7929e];
function bouquet(x, y, z, s = 1) {
  cyl(.15 * s, .115 * s, .28 * s, M.wicker, x, y + .14 * s, z);
  for (let k = 0; k < 5; k++) { const t = new THREE.Mesh(new THREE.TorusGeometry((.118 + k * .007) * s, .006 * s, 5, 26), M.wicker); t.rotation.x = Math.PI / 2; t.position.set(x, y + (.04 + k * .052) * s, z); add(t, scene, false); }
  const blooms = 11, per = 16, im = new THREE.InstancedMesh(petalGeo, new THREE.MeshStandardMaterial({ roughness: .75 }), blooms * per), d = new THREE.Object3D(), c = new THREE.Color();
  for (let b = 0; b < blooms; b++) {
    const a = b * 2.399, rr = (.06 + .19 * Math.sqrt(b / blooms)) * s, cx = x + Math.cos(a) * rr, cy = y + (.42 + (1 - rr / (.25 * s)) * .16 + rand(-.02, .02)) * s, cz = z + Math.sin(a) * rr, base = flowerCols[b % 5], R = rand(.065, .1) * s;
    for (let p = 0; p < per; p++) {
      const t = p / per, pa = p * 2.399, pr = R * Math.sqrt(t);
      d.position.set(cx + Math.cos(pa) * pr, cy + (1 - t) * R * .5, cz + Math.sin(pa) * pr);
      d.rotation.set(rand(-1, 1), pa, rand(-1, 1)); d.scale.set(R * .5, R * .16, R * .42); d.updateMatrix(); im.setMatrixAt(b * per + p, d.matrix);
      im.setColorAt(b * per + p, c.set(base).offsetHSL(0, 0, (1 - t) * -.09 + rand(-.015, .015)));
    }
  }
  im.castShadow = !MOBILE; scene.add(im);
  const lv = new THREE.InstancedMesh(leafGeo, new THREE.MeshStandardMaterial({ color: 0x7f9a84, roughness: .8, side: THREE.DoubleSide }), 26);
  for (let k = 0; k < 26; k++) { const a = k * 1.1; d.position.set(x + Math.cos(a) * .14 * s, y + .32 * s, z + Math.sin(a) * .14 * s); d.rotation.set(1 + rand(-.3, .3), -a + Math.PI / 2, 0); d.scale.setScalar(.55 * s); d.updateMatrix(); lv.setMatrixAt(k, d.matrix); }
  scene.add(lv);
}
function station(x, z) {
  // mueble
  rbox(2.7, .1, 1.15, .02, M.oak, x, -1.0, z);
  rbox(2.7, .55, 1.05, .02, M.oak, x, -1.35, z);
  [-.87, 0, .87].forEach(o => { rbox(.82, .46, .02, .006, M.oak, x + o, -1.35, z + .535); });
  rbox(.12, 1.6, 1.05, .02, M.oak, x - 1.29, -1.85, z); rbox(.12, 1.6, 1.05, .02, M.oak, x + 1.29, -1.85, z);
  // espejo
  const fr = new THREE.Mesh(archFrame, M.black); fr.position.set(x, -.95, z - .5); add(fr);
  const mi = new THREE.Mesh(archMirror, M.mirror); mi.position.set(x, -.95, z - .405); scene.add(mi);
  // LED verticales
  [-1, 1].forEach(s => { rbox(.1, 1.7, .1, .03, M.black, x + s * 1.15, -.1, z - .2); const l = box(.05, 1.55, .06, M.led, x + s * 1.15, -.1, z - .14, scene, false); leds.push(l); });
  if (!MOBILE) { const L = new THREE.PointLight(0xffdca6, 1.2, 3, 2); L.position.set(x, .1, z + .2); scene.add(L); }
  bouquet(x - .75, -.95, z + .05);
  // secador y cepillo
  cyl(.06, .06, .35, M.black, x + .6, -.9, z + .1).rotation.z = Math.PI / 2;
  cyl(.04, .04, .22, M.black, x + .45, -.87, z + .2);
  // termo
  cyl(.05, .05, .25, new THREE.MeshStandardMaterial({ color: 0x9fc3b5, roughness: .4 }), x - 1.0, -.82, z + .25);
}
[-4.7, 0, 4.7].forEach((x, i) => { station(x, -20.5); chair(x + rand(-.15, .15), -18.7, (i - 1) * -.2 + Math.PI); });
// carro de herramientas
function cart(x, z, ry) {
  const g = group(x, FY, z, ry);
  rbox(.95, 1.5, .55, .03, M.black, 0, .95, 0, g); rbox(1.2, .05, .75, .02, M.black, 0, 1.73, 0, g);
  box(.8, .25, .02, M.chrome, 0, .55, .3, g);
  [[-.4, -.22], [.4, -.22], [-.4, .22], [.4, .22]].forEach(([dx, dz]) => sph(.06, M.chrome, dx, .06, dz, g));
}
cart(-7.4, -18.8, .3); cart(7.3, -17.5, -.3);
// parlantes con atril
[[7.4, -11.5], [7.9, -10.6]].forEach(([x, z]) => {
  rbox(.6, .8, .45, .04, M.matte, x, 1.9, z); box(.5, .55, .01, new THREE.MeshStandardMaterial({ color: 0x2a2a2a, roughness: 1 }), x, 1.9, z + .23);
  cyl(.025, .025, 3.0, M.black, x, .1, z, scene, 8);
  [0, 2.1, 4.2].forEach(a => { const l = cyl(.015, .015, 1.0, M.black, x + Math.cos(a) * .3, FY + .35, z + Math.sin(a) * .3, scene, 6); l.rotation.set(Math.sin(a) * .6, 0, -Math.cos(a) * .6); });
});
// ventilador de pie
cyl(.03, .03, 2.1, M.copper, 6.9, FY + 1.1, -9.5, scene, 16);
const fanBase = new THREE.Mesh(baseGeo, M.copper); fanBase.position.set(6.9, FY, -9.5); fanBase.scale.set(.75, 1, .75); add(fanBase);
const fanG = group(6.9, FY + 2.2, -9.32, -.35);
for (let k = 0; k < 4; k++) { const r = new THREE.Mesh(new THREE.TorusGeometry(.14 + k * .115, .007, 8, 48), M.copper); r.position.z = Math.sin((k + 1) * .5) * -.02 + .05; add(r, fanG); }
for (let k = 0; k < 12; k++) { const sp = new THREE.Mesh(new THREE.BoxGeometry(.005, .96, .005), M.copper); sp.rotation.z = k / 12 * Math.PI; sp.position.z = .07; add(sp, fanG, false); }
const blades = new THREE.Group(); blades.position.set(6.9, FY + 2.2, -9.32); blades.rotation.y = -.35; scene.add(blades);
for (let k = 0; k < 3; k++) { const b = new THREE.Mesh(new THREE.BoxGeometry(.2, .38, .008), M.copper); b.position.y = .2; const h = new THREE.Group(); h.rotation.z = k * 2.09; h.add(b); blades.add(h); }

// percha de madera en A con ganchos
function rack(x, z, ry) {
  const g = group(x, FY, z, ry);
  [[-.5, .13], [.5, -.13]].forEach(([dx, rz]) => [-.3, .3].forEach(dz => { const l = cyl(.024, .03, 3.5, M.oak, dx * .52, 1.72, dz, g, 10); l.rotation.z = rz; }));
  const top = cyl(.022, .022, .8, M.oak, 0, 3.43, 0, g, 10); top.rotation.x = Math.PI / 2;
  const low = cyl(.02, .02, 1.4, M.oak, 0, .55, .28, g, 10); low.rotation.z = Math.PI / 2;
  [-.2, -.06, .08].forEach(o => { const h = new THREE.Mesh(new THREE.TorusGeometry(.24, .012, 6, 3), M.oak); h.rotation.set(0, Math.PI / 2, Math.PI / 2); h.scale.y = 1.8; h.position.set(0, 3.2, o); add(h, g); });
}
rack(7.9, -5.2, .15); plant(7.6, -6.9, .75);
velvetChair(5.6, -3.4, -.65); velvetChair(-4.4, -12.6, .9);
bouquet(-4.6, -1.02, -4.2, 1.15);

// ── Zona de lavado (tarima) ───────────────────────────────────────────
rbox(13, .32, 7, .02, new THREE.MeshStandardMaterial({ color: 0x6f665d, roughness: .7 }), 1.5, FY + .16, -34.6);
rbox(3.0, 1.4, .9, .02, M.oak, -2.0, FY + 1.02, -37.3);
[-2.0].forEach(x => { box(.02, 1.2, .02, M.black, x, FY + 1.02, -36.84); });
function washUnit(x) {
  rbox(1.0, 1.0, 1.0, .08, M.porcelain, x, FY + .82, -36.6);
  const bowl = new THREE.Mesh(new THREE.SphereGeometry(.62, 32, 16, 0, Math.PI * 2, 0, Math.PI / 2), M.porcelain); bowl.material = M.porcelain.clone(); bowl.material.side = THREE.DoubleSide;
  bowl.rotation.x = Math.PI; bowl.scale.set(1, .7, 1); bowl.position.set(x, FY + 1.95, -36.7); add(bowl);
  rbox(1.3, .5, 1.0, .1, M.porcelain, x, FY + 1.6, -36.7);
  cyl(.03, .03, .55, M.chrome, x + .35, FY + 2.2, -37.05, scene, 12); sph(.06, M.chrome, x + .35, FY + 2.5, -36.95);
  rbox(1.15, .5, 1.5, .14, M.leather, x, FY + 1.0, -35.3).rotation.x = -.12;
  rbox(1.1, 1.0, .28, .12, M.leather, x, FY + 1.55, -36.0).rotation.x = .55;
  rbox(1.1, .55, .8, .1, M.porcelain, x, FY + .6, -34.4);
}
washUnit(.5); washUnit(3.3);
// sillón reclinable de pedicura + bowl blanco
const rec = group(-4.6, FY + .32, -33.6, .2);
rbox(1.5, .7, 1.4, .25, M.leather, 0, .55, 0, rec); rbox(1.5, 1.4, .4, .2, M.leather, 0, 1.2, -.6, rec);
[-1, 1].forEach(s => rbox(.35, .75, 1.4, .17, M.leather, s * .85, .8, 0, rec));
cyl(.38, .34, .3, M.porcelain, -4.4, FY + .5, -32.2);
// secador de casco
const hd = group(6.4, FY + .32, -35.2, -.4);
cyl(.035, .035, 2.4, M.chrome, 0, 1.2, 0, hd, 12); cyl(.45, .5, .05, M.black, 0, .03, 0, hd);
const hood = new THREE.Mesh(new THREE.SphereGeometry(.6, 32, 16, 0, Math.PI * 2, 0, Math.PI * .55), M.leather); hood.position.set(-.35, 2.6, 0); hood.rotation.z = -1.3; add(hood, hd);
[-.25, .25].forEach(o => { const disc = cyl(.18, .18, .06, M.chrome, -.15, 2.35 + o, .45, hd); disc.rotation.x = Math.PI / 2; });
// silla transparente estilo Eames
const ea = group(7.6, FY + .32, -33.2, -.6);
rbox(.75, .1, .7, .05, M.glass, 0, 1.0, 0, ea); rbox(.75, .65, .08, .05, M.glass, 0, 1.4, -.33, ea);
[[-.28, -.25], [.28, -.25], [-.28, .25], [.28, .25]].forEach(([dx, dz]) => { const l = cyl(.018, .018, 1.05, M.oak, dx * 1.25, .5, dz * 1.25, ea, 8); l.rotation.set(-dz * .45, 0, dx * .45); });
// lámpara de hexágonos con ampolletas Edison
const hexGeo = new THREE.TorusGeometry(.6, .02, 4, 6);
[[-1.04, 0], [-.52, -.6], [0, 0], [.52, -.6], [1.04, 0]].forEach(([dx, dy]) => {
  const x = 1.9 + dx * 1.9, y = 2.4 + dy, z = -34.8;
  const h = new THREE.Mesh(hexGeo, M.black); h.position.set(x, y, z); h.rotation.z = Math.PI / 6; add(h, scene, false);
  cyl(.003, .003, .45, M.black, x, y + .32, z, scene, 4, false);
  const b = new THREE.Mesh(new THREE.SphereGeometry(.09, 20, 14), M.bulb); b.scale.y = 1.35; b.position.set(x, y + .02, z); scene.add(b);
});
box(1.9 * 2.6, .03, .03, M.black, 1.9, 3.0, -34.8, scene, false);
[-.8, 4.6].forEach(x => cyl(.004, .004, CY - 1 - 3, M.black, x, (CY - 1 + 3) / 2, -34.8, scene, 4, false));
const hexL = new THREE.PointLight(0xffb866, 5, 10, 2); hexL.position.set(1.9, 2.0, -34.3); hexL.castShadow = false; scene.add(hexL);

// ── Cortina de cabello en la entrada ──────────────────────────────────
const N = MOBILE ? 110 : 380, SEG = 64;
const hg = new THREE.BufferGeometry(), hpos = new Float32Array(N * SEG * 2 * 3), hcol = new Float32Array(N * SEG * 2 * 3);
const pal = [0xB79C78, 0x8B7355, 0xA58A68, 0x5C4B39, 0xC9B491, 0x75614A].map(c => new THREE.Color(c));
const seeds = Array.from({ length: N }, () => ({ x: MOBILE ? rand(-6, 6) : .5 + Math.pow(Math.random(), .7) * 7.5, z: rand(6.5, 8.5), ph: rand(0, 6.28), amp: rand(.25, .7), len: 8.4 * rand(.75, 1.1), c: pal[(Math.random() * pal.length) | 0] }));
for (let s = 0; s < N; s++) for (let k = 0; k < SEG * 2; k++) {
  const t = Math.floor(k / 2 + (k % 2)) / SEG, c = seeds[s].c.clone().lerp(new THREE.Color(BG), t * .25), o = (s * SEG * 2 + k) * 3;
  hcol[o] = c.r; hcol[o + 1] = c.g; hcol[o + 2] = c.b;
}
hg.setAttribute("position", new THREE.BufferAttribute(hpos, 3)); hg.setAttribute("color", new THREE.BufferAttribute(hcol, 3));
const hair = new THREE.LineSegments(hg, new THREE.LineBasicMaterial({ vertexColors: true, transparent: true, fog: false }));
scene.add(hair);

// ── Line art: todo se funde en 3 geometrías (relleno, contorno, aristas) = 3 draw calls ──
const lineSegs = [];
// tablas del piso: líneas a lo largo de la sala con juntas alternadas
for (let x = -W; x <= W; x += 1.05) { lineSegs.push(x, FY + .006, Z0, x, FY + .006, Z1);
  for (let z = Z0 - rand(0, 6); z > Z1; z -= rand(4.5, 7)) lineSegs.push(x, FY + .006, z, Math.min(x + 1.05, W), FY + .006, z); }
// vista por la ventana: ciudad y palmera en trazo simple
const wz = Z1 - .4, rect = (x, y, w, h) => lineSegs.push(x, y, wz, x, y + h, wz, x, y + h, wz, x + w, y + h, wz, x + w, y + h, wz, x + w, y, wz);
for (let k = 0; k < 16; k++) { const x = -9 + k * 1.15, w = rand(.7, 1.05), h = rand(1.2, 3.8); rect(x, -1.6, w, h); for (let f = -1.3; f < -1.6 + h - .2; f += .38) lineSegs.push(x + .08, f, wz, x + w - .08, f, wz); }
const body = [], hull = [];
function bake(src, mat) {
  const g = src.index ? src.toNonIndexed() : src.clone();
  for (const n of Object.keys(g.attributes)) if (n !== "position" && n !== "normal") g.deleteAttribute(n);
  if (!g.attributes.normal) g.computeVertexNormals();
  g.applyMatrix4(mat); body.push(g);
  const e = new THREE.EdgesGeometry(src, 32).applyMatrix4(mat).attributes.position.array;
  for (let i = 0; i < e.length; i++) lineSegs.push(e[i]);
}
scene.remove(blades);
scene.updateMatrixWorld(true);
const doomed = [], tmp = new THREE.Matrix4(), mm = new THREE.Matrix4();
scene.traverse(o => {
  if (o.isLight) doomed.push(o);
  if (!o.isMesh || o.material === logoMat) return;
  doomed.push(o);
  if (o.isInstancedMesh) { for (let i = 0; i < o.count; i++) { o.getMatrixAt(i, tmp); bake(o.geometry, mm.multiplyMatrices(o.matrixWorld, tmp)); } }
  else bake(o.geometry, o.matrixWorld);
});
doomed.forEach(o => o.removeFromParent());
const merged = mergeGeometries(body);
scene.add(new THREE.Mesh(merged, fill));
// contorno de objetos curvos: copia inflada unos píxeles que solo muestra su cara trasera
const outline = new THREE.ShaderMaterial({
  side: THREE.BackSide,
  uniforms: { res: { value: new THREE.Vector2(1, 1) }, ink: { value: new THREE.Color(INK) }, bg: { value: new THREE.Color(BG) } },
  vertexShader: `uniform vec2 res; varying float d;
    void main(){ vec4 c = projectionMatrix*modelViewMatrix*vec4(position,1.); vec3 n = normalMatrix*normal; vec2 v = (projectionMatrix*vec4(n,0.)).xy;
      if(dot(v,v)>0.) c.xy += normalize(v)/res*1.5*c.w; d = c.w; gl_Position = c; }`,
  fragmentShader: `uniform vec3 ink, bg; varying float d; void main(){ gl_FragColor = vec4(mix(ink,bg,smoothstep(16.,58.,d)),1.);
  #include <colorspace_fragment>
  }`
});
scene.add(new THREE.Mesh(merged, outline));
const lg = new THREE.BufferGeometry(); lg.setAttribute("position", new THREE.Float32BufferAttribute(lineSegs, 3));
const inkLine = new THREE.LineBasicMaterial({ color: INK });
scene.add(new THREE.LineSegments(lg, inkLine));
// aspas: lo único que se mueve
blades.children.forEach(h => h.children.forEach(b => { b.add(new THREE.LineSegments(new THREE.EdgesGeometry(b.geometry), inkLine)); })); scene.add(blades);

// ── Recorrido de cámara ───────────────────────────────────────────────
const V = (x, y, z) => new THREE.Vector3(x, y, z);
const camPath = new THREE.CatmullRomCurve3([V(0, .5, 14), V(0, .5, 8), V(1.4, .5, 1), V(1.7, .45, -6), V(1.5, .4, -12), V(2.35, .5, -18), V(2.35, .6, -24), V(2, .6, -28.4)], false, "centripetal");
const lookPath = new THREE.CatmullRomCurve3([V(0, .5, 4), V(-.8, .4, -3), V(-5, .8, -8), V(-6, .8, -10), V(-2.5, .3, -19), V(1, .2, -25), V(1.8, .7, -34), V(1.9, 1, -35)], false, "centripetal");
const camPos = new THREE.Vector3(), camLook = new THREE.Vector3();

let mx = 0, my = 0, smx = 0, smy = 0, wind = 0, lastX = 0;
const onMove = e => { mx = e.clientX / innerWidth - .5; my = e.clientY / innerHeight - .5; wind += (e.clientX - lastX) * .004; lastX = e.clientX; };
addEventListener("mousemove", onMove, { passive: true });

function resize() {
  const w = innerWidth, h = innerHeight;
  renderer.setSize(w, h, false); outline.uniforms.res.value.set(w, h);
  cam.aspect = w / h; cam.fov = w < 760 ? 68 : 50; cam.updateProjectionMatrix();
}
resize(); addEventListener("resize", resize);

let lastMs = 0, sp = 0; // progreso suavizado
function tick(ms) {
  const t = ms * .001, dt = Math.min(.05, (ms - lastMs) * .001); lastMs = ms;
  const r = hero.getBoundingClientRect();
  if (r.bottom < 0 || r.top > innerHeight) { raf = requestAnimationFrame(tick); return; } // fuera de pantalla: no dibuja
  const prog = clamp(-r.top / (r.height - innerHeight));
  // suavizado por tiempo: igual de fluido a 60 o 120 Hz y sin saltos con la rueda del mouse
  sp = REDUCE ? prog : sp + (prog - sp) * (1 - Math.exp(-dt * 3.2));
  const mk = 1 - Math.exp(-dt * 2.5); smx += (mx - smx) * mk; smy += (my - smy) * mk;
  camPath.getPointAt(sp, camPos); lookPath.getPoint(sp, camLook);
  cam.position.set(camPos.x + smx * .25, camPos.y - smy * .15, camPos.z);
  cam.lookAt(camLook.x + smx * .8, camLook.y - smy * .3, camLook.z);

  // cabello
  wind *= .95;
  const part = clamp(sp * 5);
  hair.material.opacity = (MOBILE ? .4 : .95) * (1 - clamp((sp - .1) * 8));
  hair.visible = hair.material.opacity > .01;
  if (hair.visible) {
    let o = 0;
    for (let s = 0; s < N; s++) {
      const sd = seeds[s], dir = sd.x < 0 ? -1 : 1; let px, py, pz;
      for (let k = 0; k <= SEG; k++) {
        const uu = k / SEG;
        const sway = REDUCE ? 0 : Math.sin(t * 1.4 + sd.ph + uu * 4) * sd.amp * uu + Math.sin(t * .7 + uu * 2) * .3 * uu + wind * uu * uu;
        const open = dir * part * (5 + Math.abs(sd.x)) * Math.pow(uu, .6);
        const x = sd.x + sway + open, y = 4.3 - uu * sd.len, z = sd.z + Math.cos(t + sd.ph + uu * 3) * .25 * uu;
        if (k > 0) { hpos[o++] = px; hpos[o++] = py; hpos[o++] = pz; hpos[o++] = x; hpos[o++] = y; hpos[o++] = z; }
        px = x; py = y; pz = z;
      }
    }
    hg.attributes.position.needsUpdate = true;
  }

  if (!REDUCE) {
    blades.rotation.z = t * 6;
  }

  // textos por etapa
  const centers = [0, .3, .6, .93];
  steps.forEach((el, k) => { el.style.opacity = Math.max(0, 1 - Math.abs(prog - centers[k]) * 7).toFixed(3); });
  bars.forEach((b, k) => b.classList.toggle("on", prog >= centers[k] - .12));
  if (hint) hint.style.opacity = prog < .04 ? 1 : 0;
  renderer.render(scene, cam);
  raf = requestAnimationFrame(tick);
}
raf = requestAnimationFrame(tick);

// Limpieza al salir de la portada (Turbo reutiliza la página): libera GPU y listeners
return function destroy() {
  stopped = true; cancelAnimationFrame(raf);
  removeEventListener("mousemove", onMove); removeEventListener("resize", resize);
  scene.traverse(o => { o.geometry?.dispose(); });
  [fill, outline, inkLine, logoMat, hair.material].forEach(m => { m.map?.dispose(); m.dispose(); });
  renderer.dispose(); renderer.forceContextLoss();
};
}
