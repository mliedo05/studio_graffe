ActiveAdmin.register ProductCategory do
  permit_params :name, :slug, :description, :active, :position

  index do
    selectable_column
    id_column
    column :name
    column :slug
    column :active
    column(:productos) { |c| c.products.count }
    actions
  end

  filter :active

  form do |f|
    f.inputs "Categoría" do
      f.input :name
      f.input :slug
      f.input :description
      f.input :active
      f.input :position
    end
    f.actions
  end
end
