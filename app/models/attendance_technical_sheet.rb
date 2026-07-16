class AttendanceTechnicalSheet < ApplicationRecord
  belongs_to :attendance

  TECHNIQUES = %w[
    baño_de_color
    balayage
    mechas
    decoloración_total
    keratina
    corte
    tratamiento
    otro
  ].freeze

  DECOLORIZATION_HEIGHTS = {
    "raices"       => "Raíces",
    "mitad"        => "Hasta la mitad",
    "tres_cuartos" => "Tres cuartos",
    "largo_total"  => "Largo total"
  }.freeze

  ELASTICITY_OPTIONS = {
    "bien"     => "Bien (sin elasticidad)",
    "leve"     => "Leve elasticidad",
    "elastico" => "Elástico — requiere tratamiento"
  }.freeze

  POROSITY_OPTIONS = {
    "baja"   => "Baja",
    "normal" => "Normal",
    "alta"   => "Alta"
  }.freeze

  # Técnicas que incluyen decoloración
  DECOLORIZATION_TECHNIQUES = %w[balayage mechas decoloración_total].freeze

  validates :technique, inclusion: { in: TECHNIQUES }, allow_blank: true
  validates :decolorization_level_start,    numericality: { in: 1..10 }, allow_nil: true
  validates :decolorization_level_achieved, numericality: { in: 1..10 }, allow_nil: true

  def technique_label
    technique.presence&.humanize || "—"
  end

  def uses_decolorization?
    DECOLORIZATION_TECHNIQUES.include?(technique)
  end

  def decolorization_height_label
    DECOLORIZATION_HEIGHTS[decolorization_height] || decolorization_height
  end

  def elasticity_label
    ELASTICITY_OPTIONS[hair_elasticity] || hair_elasticity
  end

  def porosity_label
    POROSITY_OPTIONS[hair_porosity] || hair_porosity
  end

  def blank?
    technique.blank? && tint_brand.blank? && tint_formula.blank? && notes.blank?
  end
end
