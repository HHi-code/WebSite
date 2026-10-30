require "test_helper"

class ElementTest < ActiveSupport::TestCase
  test "требует presence title" do
    element = Element.new
    refute element.valid?
    assert element.errors[:title].any?
  end

  test "ограничивает длину title максимум 100 символов" do
    element = Element.new(title: "A" * 101)
    refute element.valid?
    assert element.errors[:title].any?
  end

  test "принимает валидный rating для элемента каталога" do
    user = User.create!(email: "user@example.com", password: "secret123")
    catalog = user.catalogs.create!(name: "Каталог")
    element = catalog.elements.new(title: "Элемент", rating: 5)
    assert element.valid?
  end

  test "не требует валидацию rating для элемента без каталога" do
    element = Element.new(title: "Элемент тирлиста", rating: 0)
    assert element.valid?
  end

  test "может принадлежать каталогу (опционально)" do
    user = User.create!(email: "user@example.com", password: "secret123")
    catalog = user.catalogs.create!(name: "Каталог")
    element = catalog.elements.create!(title: "Элемент", rating: 5)
    assert_equal catalog, element.catalog
  end

  test "может принадлежать тирлисту (опционально)" do
    user = User.create!(email: "user@example.com", password: "secret123")
    tier_list = user.tier_lists.create!(title: "Тирлист")
    element = Element.create!(title: "Элемент", tier_list: tier_list)
    assert_equal tier_list, element.tier_list
  end

  test "имеет wiele tier_list_elements с зависимым удалением" do
    user = User.create!(email: "user@example.com", password: "secret123")
    tier_list = user.tier_lists.create!(title: "Т")
    element = Element.create!(title: "Элемент")
    placement = element.tier_list_elements.create!(tier_list: tier_list, rank: "S")
    element.destroy!
    refute TierListElement.exists?(placement.id)
  end

  test "valid_rank? возвращает true для допустимых рангов" do
    element = Element.new
    TierList::ALL_RANKS.each do |rank|
      assert element.valid_rank?(rank), "ожидался true для #{rank}"
    end
  end

  test "valid_rank? возвращает false для недопустимого ранга" do
    element = Element.new
    refute element.valid_rank?("Z")
    refute element.valid_rank?("")
    refute element.valid_rank?(nil)
  end

  test "change_rank! перемещает элемент на новый ранг с позицией" do
    user = User.create!(email: "user@example.com", password: "secret123")
    tier_list = user.tier_lists.create!(title: "Тирлист")
    element = Element.create!(title: "Элемент", tier_list: tier_list)
    tier_list.tier_list_elements.create!(element: element, rank: "S", position: 0)

    element.change_rank!("A", position: 2)

    element.reload
    placement = element.tier_list_elements.find_by(tier_list: tier_list)
    assert_equal "A", placement.rank
    assert_equal 2, placement.position
  end

  test "change_rank! переводит элемент в unranked" do
    user = User.create!(email: "user@example.com", password: "secret123")
    tier_list = user.tier_lists.create!(title: "Тирлист")
    element = Element.create!(title: "Элемент", tier_list: tier_list)
    tier_list.tier_list_elements.create!(element: element, rank: "S", position: 1)
    element.move_to_unranked!

    element.reload
    placement = element.tier_list_elements.find_by(tier_list: tier_list)
    assert_equal TierList::UNRANKED, placement.rank
  end

  test "change_rank! возбуждает ошибку для недопустимого ранга" do
    user = User.create!(email: "user@example.com", password: "secret123")
    tier_list = user.tier_lists.create!(title: "Тирлист")
    element = Element.create!(title: "Элемент", tier_list: tier_list)
    tier_list.tier_list_elements.create!(element: element, rank: "S", position: 0)

    assert_raises(ArgumentError) { element.change_rank!("Z") }
  end

  test "change_rank! возбуждает ошибку если элемент не в тирлисте" do
    element = Element.create!(title: "Сам по себе")
    assert_raises(ArgumentError) { element.change_rank!("S") }
  end
end
