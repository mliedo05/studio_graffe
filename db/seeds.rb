# Studio Graffe — Seeds de desarrollo
# Idempotente: usa find_or_create_by para no duplicar datos

puts "Creando usuarios..."

admin = User.find_or_create_by!(email: "admin@studiograffe.cl") do |u|
  u.first_name = "Admin"
  u.last_name  = "Studio"
  u.role       = "admin"
  u.password   = "graffe2025!"
end
puts "  ✅ Admin: #{admin.email}"

stylists_data = [
  { first_name: "Valentina", last_name: "Rojas",  email: "vale@studiograffe.cl",  commission: 35, specialties: [ "Coloración", "Mechas Balayage", "Keratina" ] },
  { first_name: "Camila",    last_name: "Muñoz",  email: "cami@studiograffe.cl",  commission: 30, specialties: [ "Corte Damas", "Peinados", "Extensiones" ] },
  { first_name: "Isidora",   last_name: "Pérez",  email: "isi@studiograffe.cl",   commission: 40, specialties: [ "Uñas Gel", "Nail Art", "Spa de Manos" ] }
]

stylists_data.each do |data|
  stylist = User.find_or_create_by!(email: data[:email]) do |u|
    u.first_name = data[:first_name]
    u.last_name  = data[:last_name]
    u.role       = "stylist"
    u.password   = "graffe2025!"
  end
  StylistProfile.find_or_create_by!(stylist: stylist) do |p|
    p.commission_percentage = data[:commission]
    p.specialties           = data[:specialties]
    p.bio                   = "Profesional del salón Studio Graffe con años de experiencia."
  end
  # Horario: Lunes a Sábado 9:00 - 18:00
  (1..6).each do |day|
    StylistSchedule.find_or_create_by!(stylist: stylist, day_of_week: day) do |s|
      s.start_time = "09:00"
      s.end_time   = "18:00"
    end
  end
  puts "  ✅ Estilista: #{stylist.full_name}"
end

puts "\nCreando servicios..."

services = [
  { category: "Cortes", name: "Corte Damas",         price: 18000, duration: 60 },
  { category: "Cortes", name: "Corte Caballero",      price: 12000, duration: 30 },
  { category: "Cortes", name: "Corte + Lavado",        price: 22000, duration: 75 },
  { category: "Coloración", name: "Tinte Completo",   price: 45000, duration: 120 },
  { category: "Coloración", name: "Mechas Balayage",  price: 85000, duration: 180 },
  { category: "Coloración", name: "Retoque de Raíz",  price: 30000, duration: 90 },
  { category: "Tratamientos", name: "Keratina",       price: 65000, duration: 150 },
  { category: "Tratamientos", name: "Hidratación Profunda", price: 25000, duration: 60 },
  { category: "Tratamientos", name: "Botox Capilar",  price: 55000, duration: 120 },
  { category: "Peinados", name: "Peinado Novia",      price: 80000, duration: 120 },
  { category: "Peinados", name: "Brushing",           price: 15000, duration: 45 },
  { category: "Peinados", name: "Trenzados",          price: 20000, duration: 60 },
  { category: "Uñas", name: "Manicure Básico",        price: 12000, duration: 45 },
  { category: "Uñas", name: "Pedicure Básico",        price: 15000, duration: 60 },
  { category: "Uñas", name: "Uñas Gel Manos",         price: 28000, duration: 90 }
]

services.each_with_index do |s, i|
  Service.find_or_create_by!(name: s[:name]) do |svc|
    svc.category         = s[:category]
    svc.price_cents      = s[:price]
    svc.duration_minutes = s[:duration]
    svc.position         = i
  end
end
puts "  ✅ #{Service.count} servicios creados"

puts "\nCreando categorías de productos..."

categories_data = [
  { name: "Shampoo y Acondicionador", slug: "shampoo-acondicionador" },
  { name: "Tratamientos Capilares",   slug: "tratamientos-capilares" },
  { name: "Coloración",               slug: "coloracion" },
  { name: "Herramientas",             slug: "herramientas" },
  { name: "Cuidado de Uñas",         slug: "cuidado-unas" },
  { name: "Accesorios",               slug: "accesorios" }
]

categories_data.each do |c|
  ProductCategory.find_or_create_by!(slug: c[:slug]) do |cat|
    cat.name = c[:name]
  end
end
puts "  ✅ #{ProductCategory.count} categorías creadas"

puts "\nCreando productos..."

shampoo_cat    = ProductCategory.find_by!(slug: "shampoo-acondicionador")
tratamientos_cat = ProductCategory.find_by!(slug: "tratamientos-capilares")
herramientas_cat = ProductCategory.find_by!(slug: "herramientas")

products_data = [
  { category: shampoo_cat,     brand: "Wella",   name: "Shampoo Elements Renewing",       price: 18990, featured: true },
  { category: shampoo_cat,     brand: "Wella",   name: "Acondicionador Elements",          price: 16990, featured: false },
  { category: shampoo_cat,     brand: "Redken",  name: "Shampoo All Soft",                 price: 21990, featured: true },
  { category: shampoo_cat,     brand: "Redken",  name: "Acondicionador All Soft",          price: 19990, featured: false },
  { category: tratamientos_cat, brand: "Olaplex", name: "No.3 Hair Perfector",             price: 42990, featured: true },
  { category: tratamientos_cat, brand: "Kerastase", name: "Masque Nutritive",              price: 38990, featured: true },
  { category: tratamientos_cat, brand: "Wella",   name: "INVIGO Mask Nutri-Enrich",        price: 24990, featured: false },
  { category: herramientas_cat, brand: "Remington", name: "Plancha Profesional S9500",     price: 89990, featured: false },
  { category: herramientas_cat, brand: "Dyson",   name: "Supersonic Hair Dryer",           price: 249990, featured: true },
  { category: herramientas_cat, brand: "GHD",     name: "Rizador Curve Classic Wave",      price: 129990, featured: false }
]

products_data.each_with_index do |p, i|
  Product.find_or_create_by!(brand: p[:brand], name: p[:name]) do |prod|
    prod.product_category = p[:category]
    prod.price_cents      = p[:price]
    prod.stock_quantity   = rand(5..30)
    prod.featured         = p[:featured]
    prod.position         = i
    prod.sku              = "SG-#{SecureRandom.hex(3).upcase}"
  end
end
puts "  ✅ #{Product.count} productos creados"

puts "\n🎉 Seeds completados!"
puts "   Admin:      admin@studiograffe.cl / graffe2025!"
puts "   Estilista:  vale@studiograffe.cl  / graffe2025!"
