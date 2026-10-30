require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "требует presence email" do
    user = User.new(password: "secret123")
    refute user.valid?
    assert user.errors[:email].any?
  end

  test "требует уникальность email" do
    User.create!(email: "existing@example.com", password: "secret123")
    user = User.new(email: "existing@example.com", password: "secret123")
    refute user.valid?
    assert user.errors[:email].any?
  end

  test "нормализует email к нижнему регистру и обрезает пробелы" do
    user = User.create!(email: "  User@Example.COM  ", password: "secret123")
    assert_equal "user@example.com", user.email
  end

  test "требует пароль минимум 6 символов" do
    user = User.new(email: "test@example.com", password: "short")
    refute user.valid?
    assert user.errors[:password].any?
  end

  test "имеет viele каталогов с зависимым удалением" do
    user = User.create!(email: "user@example.com", password: "secret123")
    catalog = user.catalogs.create!(name: "Каталог")
    user.destroy!
    refute Catalog.exists?(catalog.id)
  end

  test "имеет wiele тирлистов с зависимым удалением" do
    user = User.create!(email: "user@example.com", password: "secret123")
    tier_list = user.tier_lists.create!(title: "Тирлист")
    user.destroy!
    refute TierList.exists?(tier_list.id)
  end

  test "element_ids возвращает ID элементов из каталогов и тирлистов" do
    user = User.create!(email: "user@example.com", password: "secret123")
    catalog = user.catalogs.create!(name: "Каталог")
    catalog_element = catalog.elements.create!(title: "Элемент каталога", rating: 5)
    tier_list = user.tier_lists.create!(title: "Тирлист")
    tier_list_element = tier_list.elements.create!(title: "Элемент тирлиста")

    ids = user.element_ids
    assert_includes ids, catalog_element.id
    assert_includes ids, tier_list_element.id
  end

  test "element_ids не возвращает элементы других пользователей" do
    user = User.create!(email: "user@example.com", password: "secret123")
    other_user = User.create!(email: "other@example.com", password: "secret123")
    other_catalog = other_user.catalogs.create!(name: "Чужой каталог")
    other_element = other_catalog.elements.create!(title: "Чужой элемент", rating: 5)

    ids = user.element_ids
    refute_includes ids, other_element.id
  end
end
