class TierList < ApplicationRecord
  # Ранги тирлиста + состояние «не распределён».
  RANKS = %w[S A B C D F].freeze
  UNRANKED = "unranked".freeze
  ALL_RANKS = (RANKS + [UNRANKED]).freeze

  belongs_to :user
  has_many :tier_list_elements, dependent: :destroy
  has_many :elements, through: :tier_list_elements
  # Элементы, созданные напрямую внутри этого тирлиста (через «+ Создать элемент»).
  has_many :owned_elements, class_name: "Element", foreign_key: :tier_list_id, dependent: :destroy

  validates :title, presence: true, length: { maximum: 100 }
end
