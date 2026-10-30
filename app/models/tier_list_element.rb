class TierListElement < ApplicationRecord
  belongs_to :tier_list
  belongs_to :element

  validates :rank, inclusion: { in: TierList::ALL_RANKS }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :element_id, uniqueness: { scope: :tier_list_id }

  scope :ordered, -> { order(:position, :id) }
  scope :unranked, -> { where(rank: TierList::UNRANKED) }

  # Обновляет ранг и позицию размещения в одной транзакции.
  def move_to!(rank, position:)
    raise ArgumentError, "Недопустимый ранг: #{rank}" unless tier_list.valid_rank?(rank)
    raise ArgumentError, "Позиция не может быть отрицательной" if position.to_i < 0

    update!(rank: rank, position: position)
  end
end
