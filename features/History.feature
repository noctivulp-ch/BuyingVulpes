Feature: History and PDF breakdown
  As someone who wants to compare purchases over time
  I want every finished purchase archived by day with a printable breakdown
  So that I can see what each store cost me and whether I kept the budget

  Scenario: Monthly calendar
    When the user opens "Historial"
    Then a month calendar marks the days with finished purchases
    And tapping a day lists that day's purchases; tapping it again shows the whole month
    And the calendar cannot move past the current month

  Scenario: Purchase detail
    When the user opens a finished purchase
    Then it shows bought, listed, not bought, budget and the difference
    And one block per store with each line marked bought or not, quantity, note and subtotal

  Scenario: PDF breakdown
    When the user asks for the PDF of a finished purchase
    Then a PDF is written to the app's documents folder and opened with the system viewer
    And it contains one table per store, store totals, and the overall totals with the budget comparison
    And amounts are printed with the colón sign, using the embedded Noto Sans fonts

  Scenario: Purchases live in yearly ledger files (the "typewriter")
    Given purchases are stored in one SQLite ledger file per calendar year, attached while it is the current year
    When the first purchase of a new year is opened
    Then the previous year's ledger is closed and left untouched, and a new one is opened ([0007])
    And no purchase is ever moved or deleted when a ledger closes
    And the history can read a closed year by opening its file read-only, without restoring anything
