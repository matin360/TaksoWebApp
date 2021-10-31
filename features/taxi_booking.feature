Feature: Taxi booking
  As a customer
  Such that I go to destination
  I want to arrange a taxi ride

  Scenario: Booking via STRS' web page (with confirmation)
    Given the following users
          | email | password | name | age | is_customer |
          | i@ut.ee | 12  | Test  | 19  | true  |
          | peeter88@ut.ee | 12  | DR2  | 19  | false  |
          | juhan85@ut.ee | 12  | DR2  | 19  | false  |
    And the following taxis are on duty
          | email | location	     | status    | capacity  | cost_per_km |
          | peeter88@ut.ee | Juhan Liivi 2 | busy      | 4  | 0.5 |
          | juhan85@ut.ee | Kalevi 4      | available | 9  | 0.3 |
    And I want to go from "Juhan Liivi 2" to "Muuseumi tee 2" with distance "1"
    And I login to the system as "i@ut.ee" with password "12"
    And I open STRS' web page
    And I enter the booking information
    When I submit the booking request
    Then I should receive a confirmation message

    Scenario: Booking via STRS' web page (with rejection)
      Given the following users
          | email | password | name | age | is_customer |
          | i@ut.ee | 12  | Test  | 19  | true  |
          | peeter88@ut.ee | 12  |  DR1 | 19  | false  |
          | juhan85@ut.ee | 12  | DR2  | 19  | false  |
    And the following taxis are on duty
          | email | location	     | status    | capacity  | cost_per_km |
          | peeter88@ut.ee | Juhan Liivi 2 | busy      | 4  | 0.5 |
          | juhan85@ut.ee | Kalevi 4      | busy | 9  | 0.3 |
      And I want to go from "Liivi 2" to "Lõunakeskus" with distance "1"
      And I login to the system as "i@ut.ee" with password "12"
	    And I open STRS' web page
	    And I enter the booking information
	    When I submit the booking request
	    Then I should receive a rejection message

    Scenario: Booking via STRS' web page (confirmation with the lowest price)
    Given the following users
          | email | password | name | age | is_customer |
          | i@ut.ee | 12  | Test  | 19  | true  |
          | peeter88@ut.ee | 12  | DR2  | 19  | false  |
          | juhan85@ut.ee | 12  | DR2  | 19  | false  |
    And the following taxis are on duty
          | email | location       | status    | capacity  | cost_per_km |
          | peeter88@ut.ee | Juhan Liivi 2 | available      | 4  | 0.5 |
          | juhan85@ut.ee | Juhan Liivi 2 | available | 9  | 0.3 |
    And I want to go from "Juhan Liivi 2" to "Muuseumi tee 2" with distance "1"
     And I login to the system as "i@ut.ee" with password "12"
    And I open STRS' web page
    And I enter the booking information
    When I submit the booking request
    Then I should receive a confirmation message

    Scenario: Booking via STRS' web page (confirmation with the least completed rides but same prices)
    Given the following users
          | email | password | name | age | is_customer |
          | i@ut.ee | 12  | Test  | 19  | true  |
          | peeter88@ut.ee | 12  | DR2  | 19  | false  |
          | juhan85@ut.ee | 12  | DR2  | 19  | false  |
    And the following taxis are on duty
          | email | location       | status    | capacity  | cost_per_km | completed_rides_num |
          | peeter88@ut.ee | Juhan Liivi 2 | available      | 4  | 0.5 | 2 |
          | juhan85@ut.ee | Juhan Liivi 2 | available | 9  | 0.5 | 3 |
    And I want to go from "Juhan Liivi 2" to "Muuseumi tee 2" with distance "1"
     And I login to the system as "i@ut.ee" with password "12"
    And I open STRS' web page
    And I enter the booking information
    When I submit the booking request
    Then I should receive a confirmation message