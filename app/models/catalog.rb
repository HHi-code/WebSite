class Catalog < ApplicationRecord
  belongs_to :user
  has_many :elements, dependent: :destroy

  validates :name, presence: true, length: { maximum: 60 }
  validates :border_color, presence: true, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: "должен быть в формате #RRGGBB" }
end
