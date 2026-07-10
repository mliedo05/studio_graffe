# Enlace en el navbar de ActiveAdmin que lleva directo al panel supervisor.
# Usa register_page para crear un ítem de menú sin una tabla/recurso detrás.
ActiveAdmin.register_page "Supervisor" do
  menu label: "👁️ Ver Supervisor", priority: 99

  # Redirigir inmediatamente al supervisor panel en lugar de mostrar una página vacía
  controller do
    def index
      redirect_to supervisor_root_path, allow_other_host: false, status: :found
    end
  end

  content title: "Panel Supervisor" do
    # Fallback por si el redirect no se ejecuta
    para do
      link_to "→ Ir al Panel Supervisor", supervisor_root_path,
              style: "font-size:16px; font-weight:600; color:#C9A96E;"
    end
  end
end
