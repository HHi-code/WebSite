class TierListElement < ApplicationRecord
  belongs_to :tier_list
  belongs_to :element

  validates :rank, inclusion: { in: TierList::ALL_RANKS }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :element_id, uniqueness: { scope: :tier_list_id }

  scope :ordered, -> { order(:position, :id) }
  scope :unranked, -> { where(rank: TierList::UNRANKED) }
end
