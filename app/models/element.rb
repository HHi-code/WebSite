class Element < ApplicationRecord
  belongs_to :catalog, optional: true
  belongs_to :tier_list, optional: true

  has_many :tier_list_elements, dependent: :destroy
  has_one_attached :image

  validates :title, presence: true, length: { maximum: 100 }
  # Рейтинг проверяем только для элементов каталогов — у элементов тирлистов его нет.
  validates :rating, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }, allow_nil: true, if: -> { catalog_id.present? }
end
