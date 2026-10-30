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

  # Проверяет, является ли переданное значение допустимым рангом.
  def self.valid_rank?(rank)
    ALL_RANKS.include?(rank)
  end

  def valid_rank?(rank)
    self.class.valid_rank?(rank)
  end

  # Размещает элемент на указанном ранге с заданной позицией.
  # Если элемент уже имеет запись размещения в этом тирлисте — обновляет её,
  # иначе создаёт новую.
  def place_element!(element, rank:, position: 0)
    raise ArgumentError, "Элемент не может быть nil" if element.nil?
    raise ArgumentError, "Недопустимый ранг: #{rank}" unless valid_rank?(rank)
    raise ArgumentError, "Элемент принадлежит другому тирлисту" unless element.tier_list_id == id

    placement = tier_list_elements.find_or_initialize_by(element: element)
    placement.update!(rank: rank, position: position)
  end

  # Перемещает элемент на другой ранг с новой позицией.
  def move_element!(element, rank:, position:)
    place_element!(element, rank: rank, position: position)
  end

  # Элементы в состоянии «не распределены».
  def unranked_elements
    elements.joins(:tier_list_elements).where(tier_list_elements: { rank: UNRANKED })
  end

  # Элементы на указанном рангу.
  def ranked_elements(rank)
    raise ArgumentError, "Недопустимый ранг: #{rank}" unless valid_rank?(rank)
    elements.joins(:tier_list_elements).where(tier_list_elements: { rank: rank })
  end
end
