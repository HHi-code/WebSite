require "test_helper"

class TierListTest < ActiveSupport::TestCase
  test "требует presence title" do
    tier_list = TierList.new
    refute tier_list.valid?
    assert tier_list.errors[:title].any?
  end

  test "ограничивает длину title максимум 100 символов" do
    tier_list = TierList.new(title: "A" * 101)
    refute tier_list.valid?
    assert tier_list.errors[:title].any?
  end

  test "может существовать без описания" do
    user = User.create!(email: "user@example.com", password: "secret123")
    tier_list = user.tier_lists.create!(title: "Тирлист")
    assert tier_list.persisted?
    assert_nil tier_list.description
  end

  test "принадлежит пользователю" do
    user = User.create!(email: "user@example.com", password: "secret123")
    tier_list = user.tier_lists.create!(title: "Тирлист")
    assert_equal user, tier_list.user
  end

  test "имеет wiele tier_list_elements с зависимым удалением" do
    user = User.create!(email: "user@example.com", password: "secret123")
    tier_list = user.tier_lists.create!(title: "Тирлист")
    placement = tier_list.tier_list_elements.create!(
      element: Element.create!(title: "Элемент", tier_list: tier_list),
      rank: "S"
    )
    tier_list.destroy!
    refute TierListElement.exists?(placement.id)
  end

  test "имеет элементы через tier_list_elements" do
    user = User.create!(email: "user@example.com", password: "secret123")
    tier_list = user.tier_lists.create!(title: "Тирлист")
    element = Element.create!(title: "Элемент", tier_list: tier_list)
    tier_list.tier_list_elements.create!(element: element, rank: "A")

    assert_includes tier_list.elements, element
  end

  test "valid_rank? возвращает true для допустимых рангов" do
    tier_list = TierList.new
    TierList::ALL_RANKS.each do |rank|
      assert tier_list.valid_rank?(rank), "ожидался true для #{rank}"
    end
  end

  test "valid_rank? возвращает false для недопустимого ранга" do
    tier_list = TierList.new
    refute tier_list.valid_rank?("Z")
    refute tier_list.valid_rank?("")
    refute tier_list.valid_rank?(nil)
  end

  test "place_element! создаёт размещение элемента на ранге" do
    user = User.create!(email: "user@example.com", password: "secret123")
    tier_list = user.tier_lists.create!(title: "Тирлист")
    element = Element.create!(title: "Элемент", tier_list: tier_list)

    tier_list.place_element!(element, rank: "S", position: 0)

    element.reload
    placement = element.tier_list_elements.find_by(tier_list: tier_list)
    assert_equal "S", placement.rank
    assert_equal 0, placement.position
  end

  test "place_element! обновляет существующее размещение вместо дубля" do
    user = User.create!(email: "user@example.com", password: "secret123")
    tier_list = user.tier_lists.create!(title: "Тирлист")
    element = Element.create!(title: "Элемент", tier_list: tier_list)
    tier_list.tier_list_elements.create!(element: element, rank: "S", position: 0)

    tier_list.place_element!(element, rank: "A", position: 3)

    assert_equal 1, tier_list.tier_list_elements.where(element: element).count
    placement = element.tier_list_elements.find_by(tier_list: tier_list)
    assert_equal "A", placement.rank
    assert_equal 3, placement.position
  end

  test "place_element! возбуждает ошибку для элемента чужого тирлиста" do
    user = User.create!(email: "user@example.com", password: "secret123")
    other_user = User.create!(email: "other@example.com", password: "secret123")
    tier_list = user.tier_lists.create!(title: "Тирлист")
    element = Element.create!(title: "Элемент", tier_list: other_user.tier_lists.create!(title: "Чужой"))

    assert_raises(ArgumentError) { tier_list.place_element!(element, rank: "S") }
  end

  test "unranked_elements возвращает элементы в состоянии не распределены" do
    user = User.create!(email: "user@example.com", password: "secret123")
    tier_list = user.tier_lists.create!(title: "Тирлист")
    element1 = Element.create!(title: "Элемент 1", tier_list: tier_list)
    element2 = Element.create!(title: "Элемент 2", tier_list: tier_list)
    tier_list.tier_list_elements.create!(element: element1, rank: TierList::UNRANKED, position: 0)
    tier_list.tier_list_elements.create!(element: element2, rank: "S", position: 0)

    assert_includes tier_list.unranked_elements, element1
    refute_includes tier_list.unranked_elements, element2
  end

  test "ranked_elements возвращает элементы на указанном рангу" do
    user = User.create!(email: "user@example.com", password: "secret123")
    tier_list = user.tier_lists.create!(title: "Тирлист")
    element = Element.create!(title: "Элемент", tier_list: tier_list)
    tier_list.tier_list_elements.create!(element: element, rank: "S", position: 0)

    assert_includes tier_list.ranked_elements("S"), element
    assert tier_list.ranked_elements("A").empty?
  end

  test "ranked_elements возбуждает ошибку для недопустимого ранга" do
    user = User.create!(email: "user@example.com", password: "secret123")
    tier_list = user.tier_lists.create!(title: "Тирлист")
    assert_raises(ArgumentError) { tier_list.ranked_elements("Z") }
  end
end
