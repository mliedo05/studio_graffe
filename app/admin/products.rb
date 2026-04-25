ActiveAdmin.register Product do
  permit_params :name, :brand, :product_category_id, :description,
                :price_cents, :stock_quantity, :featured, :active, :sku, :image

  index do
    selectable_column
    id_column
    column("Imagen") { |p| image_tag(p.image, width: 50, height: 50, style: "object-fit:cover; border-radius:4px") if p.image.attached? }
    column :brand
    column :name
    column(:category) { |p| p.product_category.name }
    column(:precio) { |p| number_to_currency(p.price_cents, unit: "$", delimiter: ".", precision: 0) }
    column :stock_quantity
    column :featured
    column :active
    actions
  end

  filter :brand
  filter :product_category
  filter :featured
  filter :active
  filter :name_cont, label: "Nombre contiene"

  form do |f|
    f.inputs "Producto" do
      f.input :product_category
      f.input :brand
      f.input :name
      f.input :description
      f.input :sku
      f.input :price_cents, label: "Precio (en pesos, ej: 34990)"
      f.input :stock_quantity, label: "Stock"
      f.input :featured, label: "Destacado"
      f.input :active,   label: "Activo"
      f.input :image, as: :file, label: "Imagen del producto",
              hint: "Formatos: JPG, PNG, WEBP. Recomendado: 800×800px"
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :brand
      row :name
      row :product_category
      row(:imagen) { |p| image_tag(p.image, width: 200) if p.image.attached? }
      row :price_cents
      row :stock_quantity
      row :featured
      row :active
      row :description
    end
  end
end
