Feature: Building and finishing a purchase
  As someone standing in the aisle
  I want to see what is left to buy, what is already in the cart, and how I am doing against my budget
  So that I finish the purchase without surprises at the checkout

  Scenario: There is at most one purchase in progress
    Given no purchase is in progress
    When the user adds the first product to the list
    Then a "Compra" is opened and stored in the database ([0005])
    And closing the app does not lose it

  Scenario: A line is a snapshot of the product
    When a product is added to the list
    Then the line copies the store name, product name, price per measure, measure and usual quantity ([0003])
    And editing the product afterwards does not change the line

  Scenario: Checking a line moves it to the cart
    Given the list has lines grouped by store
    When the user checks a line
    Then it moves from "Por comprar" to "En el carrito", still grouped by store
    And the cart total grows by that line's subtotal

  Scenario: Editing a line at the shelf
    When the user opens a line and changes quantity, today's price or the note
    Then the subtotal is price × quantity ([0002])
    And if the price changed, a switch "Guardar este precio en el producto" — on by default — updates the catalog ([0004])

  Scenario: Budget
    When the user sets a budget for the purchase in progress
    Then the footer shows list total, cart total and what remains (budget − cart)
    And the list total turns red as soon as the WHOLE list exceeds the budget, even if the cart does not yet
    And leaving the budget empty removes it

  Scenario: Finishing the purchase
    Given the purchase in progress has at least one line
    When the user taps "Finalizar compra" and confirms
    Then the purchase is closed with the current date and time
    And unchecked lines stay in the breakdown as not bought
    And a PDF breakdown is generated and the detail screen opens
    And the next product added opens a new purchase
