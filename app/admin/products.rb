ActiveAdmin.register Product do
  menu label: "🛍️ Productos", priority: 2

  permit_params :name, :brand, :product_category_id, :description,
                :price_cents, :stock_quantity, :featured, :active, :sku, :image

  # ── Listado ──────────────────────────────────────────────────────
  index do
    selectable_column
    column("Foto") do |p|
      if p.image.attached?
        image_tag url_for(p.image), width: 60, height: 60,
                  style: "object-fit:cover; border-radius:8px; border:1px solid #e5e7eb"
      else
        span "Sin foto", style: "color:#9ca3af; font-size:11px"
      end
    end
    column("Producto") do |p|
      div link_to(p.name, edit_admin_product_path(p)), style: "font-weight:600"
      div p.brand, style: "color:#6b7280; font-size:12px"
    end
    column("Categoría") { |p| p.product_category.name }
    column("Precio") { |p| number_to_currency(p.price_cents, unit: "$", delimiter: ".", precision: 0) }
    column("Stock") do |p|
      if p.stock_quantity == 0
        span "Sin stock", style: "background:#fee2e2; color:#dc2626; padding:3px 8px; border-radius:4px; font-size:11px; font-weight:bold"
      elsif p.stock_quantity <= 3
        span "⚠️ #{p.stock_quantity} uds.", style: "background:#fef3c7; color:#d97706; padding:3px 8px; border-radius:4px; font-size:11px; font-weight:bold"
      else
        span "#{p.stock_quantity} uds.", style: "background:#dcfce7; color:#16a34a; padding:3px 8px; border-radius:4px; font-size:11px; font-weight:bold"
      end
    end
    column("Destacado") { |p| p.featured? ? status_tag("Sí", class: "yes") : status_tag("No") }
    column("Activo")    { |p| p.active?   ? status_tag("Sí", class: "yes") : status_tag("No") }
    actions
  end

  # ── Filtros ───────────────────────────────────────────────────────
  filter :brand,            label: "Marca"
  filter :product_category, label: "Categoría"
  filter :featured,         label: "Destacado"
  filter :active,           label: "Activo"
  filter :name_cont,        label: "Nombre contiene"
  filter :stock_quantity_lteq, label: "Stock menor o igual a"

  # ── Acciones en lote ──────────────────────────────────────────────
  batch_action "Activar productos" do |ids|
    Product.where(id: ids).update_all(active: true)
    redirect_to collection_path, notice: "Productos activados."
  end

  batch_action "Desactivar productos" do |ids|
    Product.where(id: ids).update_all(active: false)
    redirect_to collection_path, notice: "Productos desactivados."
  end

  batch_action "Marcar como destacados" do |ids|
    Product.where(id: ids).update_all(featured: true)
    redirect_to collection_path, notice: "Productos marcados como destacados."
  end

  # ── Formulario ────────────────────────────────────────────────────
  form do |f|
    columns do
      column do
        f.inputs "📋 Información del producto" do
          f.input :product_category, label: "Categoría"
          f.input :brand,            label: "Marca"
          f.input :name,             label: "Nombre"
          f.input :sku,              label: "SKU / Código"
          f.input :description,      label: "Descripción", as: :text, input_html: { rows: 4 }
        end

        f.inputs "💲 Precio e inventario" do
          f.input :price_cents,    label: "Precio en pesos (ej: 34990)", hint: "Ingresa el precio sin puntos"
          f.input :stock_quantity, label: "Unidades en stock"
        end

        f.inputs "⚙️ Opciones" do
          f.input :featured, label: "Producto destacado (aparece en portada)"
          f.input :active,   label: "Producto activo (visible en tienda)"
        end
      end

      column do
        f.inputs "📷 Foto del producto" do
          if f.object.image.attached?
            div do
              image_tag url_for(f.object.image),
                        style: "max-width:100%; border-radius:8px; margin-bottom:12px; border:1px solid #e5e7eb"
            end
            div do
              span "Foto actual. Sube una nueva para reemplazarla.",
                   style: "color:#6b7280; font-size:12px; display:block; margin-bottom:8px"
            end
          else
            div do
              span "Sin foto. Sube una imagen (JPG, PNG o WEBP, 800×800px recomendado).",
                   style: "color:#9ca3af; font-size:12px; display:block; margin-bottom:8px"
            end
          end
          f.input :image, as: :file, label: "Subir foto"
        end
      end
    end

    f.actions
  end

  # ── Vista detalle ─────────────────────────────────────────────────
  show do
    columns do
      column do
        attributes_table title: "Información" do
          row("Marca")     { |p| p.brand }
          row("Nombre")    { |p| p.name }
          row("Categoría") { |p| p.product_category.name }
          row("SKU")       { |p| p.sku }
          row("Precio")    { |p| number_to_currency(p.price_cents, unit: "$", delimiter: ".", precision: 0) }
          row("Stock") do |p|
            color = p.stock_quantity == 0 ? "#dc2626" : (p.stock_quantity <= 3 ? "#d97706" : "#16a34a")
            span "#{p.stock_quantity} unidades", style: "font-weight:bold; color:#{color}"
          end
          row("Destacado") { |p| p.featured? ? "✅ Sí" : "❌ No" }
          row("Activo")    { |p| p.active?   ? "✅ Sí" : "❌ No" }
          row("Descripción") { |p| simple_format(p.description.to_s) }
        end
      end
      column do
        panel "📷 Foto del producto" do
          if product.image.attached?
            image_tag url_for(product.image),
                      style: "max-width:100%; border-radius:8px; border:1px solid #e5e7eb"
          else
            div "Sin foto cargada.", style: "color:#9ca3af; padding:20px; text-align:center"
          end
        end
      end
    end
  end
end
