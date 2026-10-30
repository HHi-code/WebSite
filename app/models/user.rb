class User < ApplicationRecord
  has_secure_password

  has_many :catalogs, dependent: :destroy
  has_many :elements, through: :catalogs
  has_many :tier_lists, dependent: :destroy

  # Все ID элементов пользователя: как из каталогов, так и созданные внутри тирлистов.
  def element_ids
    Element.where(catalog_id: catalog_ids)
      .or(Element.where(id: TierListElement.where(tier_list_id: tier_list_ids).pluck(:element_id)))
      .pluck(:id)
  end

  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true
end
