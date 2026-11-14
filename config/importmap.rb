# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Portada: salón 3D (solo se descarga en la portada, por eso preload: false)
pin "salon_scene", preload: false
pin "three", to: "https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.module.js", preload: false
pin "three/addons/utils/BufferGeometryUtils.js", to: "https://cdn.jsdelivr.net/npm/three@0.160.0/examples/jsm/utils/BufferGeometryUtils.js", preload: false
pin "three/addons/geometries/RoundedBoxGeometry.js", to: "https://cdn.jsdelivr.net/npm/three@0.160.0/examples/jsm/geometries/RoundedBoxGeometry.js", preload: false
