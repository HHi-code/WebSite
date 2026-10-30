class Element < ApplicationRecord
  belongs_to :catalog, optional: true
  belongs_to :tier_list, optional: true

  has_many :tier_list_elements, dependent: :destroy
  has_one_attached :image

  validates :title, presence: true, length: { maximum: 100 }
  # Рейтинг проверяем только для элементов каталогов — у элементов тирлистов его нет.
  validates :rating, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }, allow_nil: true, if: -> { catalog_id.present? }

  # Проверяет, является ли переданное значение допустимым рангом тирлиста.
  def valid_rank?(rank)
    TierList::ALL_RANKS.include?(rank)
  end

  # Изменяет ранг элемента в его тирлисте с опциональной позицией.
  # Работает только для элементов, созданных внутри тирлиста.
  def change_rank!(new_rank, position: nil)
    raise ArgumentError, "Недопустимый ранг: #{new_rank}" unless valid_rank?(new_rank)
    raise ArgumentError, "Элемент не принадлежит ни одному тирлисту" unless tier_list

    placement = tier_list_elements.find_by!(tier_list: tier_list)
    placement.update!(rank: new_rank, position: position || 0)
  end

  # Переводит элемент в состояние «не распределён» в его тирлисте.
  def move_to_unranked!
    change_rank!(TierList::UNRANKED)
  end
end
