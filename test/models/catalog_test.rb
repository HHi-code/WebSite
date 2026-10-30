require "test_helper"

class CatalogTest < ActiveSupport::TestCase
  test "требует presence name" do
    catalog = Catalog.new(description: "Описание")
    refute catalog.valid?
    assert catalog.errors[:name].any?
  end

  test "ограничивает длину name максимум 60 символов" do
    catalog = Catalog.new(name: "A" * 61)
    refute catalog.valid?
    assert catalog.errors[:name].any?
  end

  test "требует формат border_color #RRGGBB" do
    catalog = Catalog.new(name: "Каталог", border_color: "not-a-color")
    refute catalog.valid?
    assert catalog.errors[:border_color].any?
  end

  test "принимает корректный border_color" do
    user = User.create!(email: "user@example.com", password: "secret123")
    catalog = user.catalogs.new(name: "Каталог", border_color: "#8B5CF6")
    assert catalog.valid?
  end

  test "принадлежит пользователю" do
    user = User.create!(email: "user@example.com", password: "secret123")
    catalog = user.catalogs.create!(name: "Каталог")
    assert_equal user, catalog.user
  end

  test "имеет wiele элементов с зависимым удалением" do
    user = User.create!(email: "user@example.com", password: "secret123")
    catalog = user.catalogs.create!(name: "Каталог")
    element = catalog.elements.create!(title: "Элемент", rating: 5)
    catalog.destroy!
    refute Element.exists?(element.id)
  end

  test "может существовать без описания" do
    user = User.create!(email: "user@example.com", password: "secret123")
    catalog = user.catalogs.create!(name: "Каталог")
    assert catalog.persisted?
    assert_nil catalog.description
  end

  test "имеет цвет рамки по умолчанию #8B5CF6" do
    user = User.create!(email: "user@example.com", password: "secret123")
    catalog = user.catalogs.create!(name: "Каталог")
    assert_equal "#8B5CF6", catalog.border_color
  end
end
