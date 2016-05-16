module SmartAnswer
  class CalculateMarriedCouplesAllowanceFlow < Flow
    def define
      content_id "e04dc5fe-9a31-4229-9de9-884dd0c0a8ce"
      name 'calculate-married-couples-allowance'
      status :published
      satisfies_need "101007"

      multiple_choice :were_you_or_your_partner_born_on_or_before_6_april_1935? do
        option :yes
        option :no

        on_response do |response|
          self.calculator = Calculators::MarriedCouplesAllowanceCalculator.new
          calculator.born_on_or_before_6_april_1935 = response
        end

        calculate :net_pension_contributions do
          nil
        end
        calculate :gift_aided_donations do
          nil
        end

        next_node do
          if calculator.qualifies?
            question :did_you_marry_or_civil_partner_before_5_december_2005?
          else
            outcome :sorry
          end
        end
      end

      multiple_choice :did_you_marry_or_civil_partner_before_5_december_2005? do
        option :yes
        option :no

        on_response do |response|
          calculator.marriage_or_civil_partnership_before_5_december_2005 = response
        end

        next_node do
          if calculator.husband_income_measured?
            question :whats_the_husbands_date_of_birth?
          else
            question :whats_the_highest_earners_date_of_birth?
          end
        end
      end

      date_question :whats_the_husbands_date_of_birth? do
        from { Date.today.end_of_year }
        to { Date.parse('1 Jan 1896') }

        on_response do |response|
          calculator.birth_date = response
        end

        next_node do
          question :whats_the_husbands_income?
        end
      end

      date_question :whats_the_highest_earners_date_of_birth? do
        to { Date.parse('1 Jan 1896') }
        from { Date.today.end_of_year }

        on_response do |response|
          calculator.birth_date = response
        end

        next_node do
          question :whats_the_highest_earners_income?
        end
      end

      money_question :whats_the_husbands_income? do
        on_response do |response|
          calculator.income = response
        end

        validate { calculator.valid_income? }

        next_node do
          if calculator.income_within_limit_for_personal_allowance?
            outcome :husband_done
          else
            question :paying_into_a_pension?
          end
        end
      end

      money_question :whats_the_highest_earners_income? do
        on_response do |response|
          calculator.income = response
        end

        validate { calculator.valid_income? }

        next_node do
          if calculator.income_within_limit_for_personal_allowance?
            outcome :highest_earner_done
          else
            question :paying_into_a_pension?
          end
        end
      end

      multiple_choice :paying_into_a_pension? do
        option :yes
        option :no

        on_response do |response|
          calculator.paying_into_a_pension = response
        end

        next_node do
          if calculator.paying_into_a_pension?
            question :how_much_expected_contributions_before_tax?
          else
            question :how_much_expected_gift_aided_donations?
          end
        end
      end

      money_question :how_much_expected_contributions_before_tax? do
        on_response do |response|
          calculator.gross_pension_contributions = response
        end

        next_node do
          question :how_much_expected_contributions_with_tax_relief?
        end
      end

      money_question :how_much_expected_contributions_with_tax_relief? do
        save_input_as :net_pension_contributions

        next_node do
          question :how_much_expected_gift_aided_donations?
        end
      end

      money_question :how_much_expected_gift_aided_donations? do
        save_input_as :gift_aided_donations

        next_node do
          if calculator.husband_income_measured?
            outcome :husband_done
          else
            outcome :highest_earner_done
          end
        end
      end

      outcome :husband_done do
        precalculate :allowance do
          adjusted_income = calculator.calculate_adjusted_net_income(calculator.income.to_f, calculator.gross_pension_contributions.to_f, net_pension_contributions.to_f, gift_aided_donations.to_f)
          calculator.calculate_allowance(adjusted_income)
        end
      end
      outcome :highest_earner_done do
        precalculate :allowance do
          adjusted_income = calculator.calculate_adjusted_net_income(calculator.income.to_f, calculator.gross_pension_contributions.to_f, net_pension_contributions.to_f, gift_aided_donations.to_f)
          calculator.calculate_allowance(adjusted_income)
        end
      end
      outcome :sorry
    end
  end
end
