require "test_helper"

class TierListElementTest < ActiveSupport::TestCase
  test "требует inclusion rank в допустимых значениях" do
    placement = TierListElement.new(rank: "Z", position: 0)
    refute placement.valid?
    assert placement.errors[:rank].any?
  end

  test "требует presence rank" do
    placement = TierListElement.new(rank: nil, position: 0)
    refute placement.valid?
    assert placement.errors[:rank].any?
  end

  test "требует numericality position >= 0" do
    placement = TierListElement.new(rank: "S", position: -1)
    refute placement.valid?
    assert placement.errors[:position].any?
  end

  test "требует уникальность element_id в рамках tier_list_id" do
    user = User.create!(email: "user@example.com", password: "secret123")
    tier_list = user.tier_lists.create!(title: "Тирлист")
    element = Element.create!(title: "Элемент", tier_list: tier_list)
    tier_list.tier_list_elements.create!(element: element, rank: "S", position: 0)

    duplicate = TierListElement.new(tier_list: tier_list, element: element, rank: "A", position: 1)
    refute duplicate.valid?
    assert duplicate.errors[:element_id].any?
  end

  test "принадлежит тирлисту" do
    user = User.create!(email: "user@example.com", password: "secret123")
    tier_list = user.tier_lists.create!(title: "Тирлист")
    element = Element.create!(title: "Элемент")
    placement = TierListElement.create!(tier_list: tier_list, element: element, rank: "S")
    assert_equal tier_list, placement.tier_list
  end

  test "принадлежит элементу" do
    element = Element.create!(title: "Элемент")
    user = User.create!(email: "user@example.com", password: "secret123")
    tier_list = user.tier_lists.create!(title: "Тирлист")
    placement = TierListElement.create!(tier_list: tier_list, element: element, rank: "S")
    assert_equal element, placement.element
  end

  test "имеет scope ordered по позиции и ID" do
    user = User.create!(email: "user@example.com", password: "secret123")
    tier_list = user.tier_lists.create!(title: "Тирлист")
    element1 = Element.create!(title: "Элемент 1", tier_list: tier_list)
    element2 = Element.create!(title: "Элемент 2", tier_list: tier_list)
    tier_list.tier_list_elements.create!(element: element1, rank: "S", position: 2)
    tier_list.tier_list_elements.create!(element: element2, rank: "S", position: 1)

    ordered = tier_list.tier_list_elements.ordered
    assert_equal [element2, element1], ordered.map(&:element)
  end

  test "имеет scope unranked" do
    user = User.create!(email: "user@example.com", password: "secret123")
    tier_list = user.tier_lists.create!(title: "Тирлист")
    element1 = Element.create!(title: "Элемент 1", tier_list: tier_list)
    element2 = Element.create!(title: "Элемент 2", tier_list: tier_list)
    tier_list.tier_list_elements.create!(element: element1, rank: TierList::UNRANKED, position: 0)
    tier_list.tier_list_elements.create!(element: element2, rank: "S", position: 0)

    unranked = tier_list.tier_list_elements.unranked
    assert_includes unranked.map(&:element), element1
    refute_includes unranked.map(&:element), element2
  end

  test "move_to! обновляет ранг и позицию в одной транзакции" do
    user = User.create!(email: "user@example.com", password: "secret123")
    tier_list = user.tier_lists.create!(title: "Тирлист")
    element = Element.create!(title: "Элемент", tier_list: tier_list)
    placement = tier_list.tier_list_elements.create!(element: element, rank: "S", position: 0)

    placement.move_to!("A", position: 5)

    placement.reload
    assert_equal "A", placement.rank
    assert_equal 5, placement.position
  end

  test "move_to! возбуждает ошибку для недопустимого ранга" do
    user = User.create!(email: "user@example.com", password: "secret123")
    tier_list = user.tier_lists.create!(title: "Тирлист")
    element = Element.create!(title: "Элемент", tier_list: tier_list)
    placement = tier_list.tier_list_elements.create!(element: element, rank: "S", position: 0)

    assert_raises(ArgumentError) { placement.move_to!("Z", position: 0) }
  end

  test "move_to! возбуждает ошибку для отрицательной позиции" do
    user = User.create!(email: "user@example.com", password: "secret123")
    tier_list = user.tier_lists.create!(title: "Тирлист")
    element = Element.create!(title: "Элемент", tier_list: tier_list)
    placement = tier_list.tier_list_elements.create!(element: element, rank: "S", position: 0)

    assert_raises(ArgumentError) { placement.move_to!("S", position: -1) }
  end
end
