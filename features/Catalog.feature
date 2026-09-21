Feature: Stores and products
  As someone who shops in several stores
  I want each store to keep its own list of products with prices
  So that my shopping list is organized the way I actually shop

  Scenario: The app starts with nothing
    Given a fresh installation
    When the app opens
    Then there are no stores, no products and no purchase in progress
    And the empty list points to the stores panel to create the first store

  Scenario: Creating a store
    When the user creates a "Tienda" with a name and optional notes
    Then it appears in the stores panel, collapsed, with zero products

  Scenario: Creating a product inside a store
    Given a "Tienda" exists
    When the user creates a "Producto" in it with name, price, measure, usual quantity, optional photo and notes
    Then the price is PER measure (unit, kilogram, gram, litre, millilitre, package, dozen) ([0002])
    And the product belongs to that store only; the same item in another store is another product ([0001])
    And a product created from the panel is left checked, ready to be added to the list

  Scenario: Archiving a product or a store is a soft delete
    When the user removes a "Producto"
    Then it disappears from the panel but keeps its id, because past purchases name it ([0003])

  Scenario: The stores panel is a full-screen side drawer with multi-select
    When the user opens the stores panel from the left
    Then it covers the whole screen
    And products from several stores can be checked before adding them all at once
    And products already on the list are marked as such and are not duplicated
