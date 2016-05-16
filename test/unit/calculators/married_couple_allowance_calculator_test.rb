require_relative '../../test_helper'

module SmartAnswer::Calculators
  class MarriedCouplesAllowanceCalculatorTest < ActiveSupport::TestCase
    setup do
      @income_limit = 27000
      @age_related_allowance = 12000
      @personal_allowance = 9000
    end

    def calculator(stubbed_values = {})
      calculator = MarriedCouplesAllowanceCalculator.new
      stubbed_values.each do |key, value|
        calculator.stubs(key).returns(value)
      end
      calculator
    end

    def default_calculator
      return @default_calculator if @default_calculator
      @default_calculator = calculator(
        maximum_mca: 8020,
        minimum_mca: 3010,
        income_limit_for_personal_allowances: @income_limit,
        personal_allowance: @personal_allowance,
        age_related_allowance: @age_related_allowance
      )
    end

    test "worked example on directgov for 2011-12" do
      hmrc_example_calculator = calculator(
        maximum_mca: 7295,
        minimum_mca: 2800,
        income_limit_for_personal_allowances: 24000,
        personal_allowance: 7475,
        age_related_allowance: 10090
      )

      result = hmrc_example_calculator.calculate_allowance(29600)
      assert_equal SmartAnswer::Money.new("711"), result
    end

    #add one for 2013-14 when the worked example is released
    test "worked example on HMRC site for 2012-13" do
      hmrc_example_calculator = calculator(
        maximum_mca: 7705,
        minimum_mca: 2960,
        income_limit_for_personal_allowances: 25400,
        personal_allowance: 8105,
        age_related_allowance: 10660
      )

      result = hmrc_example_calculator.calculate_allowance(31500)
      assert_equal SmartAnswer::Money.new("721"), result
    end

    test "allow an income less than 1" do
      result = default_calculator.calculate_allowance(0)
      assert_equal SmartAnswer::Money.new("802"), result
    end

    test "minimum allowance when annual income over income limit" do
      result = default_calculator.calculate_allowance(90000)
      assert_equal SmartAnswer::Money.new("301"), result
    end

    test "maximum allowance when low annual income" do
      result = default_calculator.calculate_allowance(100)
      assert_equal SmartAnswer::Money.new("802"), result
    end

    test "maximum allowance when income is greater than income limit but not enough to reduce personal allowance" do
      maximum_reduction = @age_related_allowance - @personal_allowance
      test_income = @income_limit + (maximum_reduction - 100)
      result = default_calculator.calculate_allowance(test_income)
      assert_equal SmartAnswer::Money.new("802"), result
    end

    test "maximum allowance when income is same as income limit" do
      result = default_calculator.calculate_allowance(@income_limit)
      assert_equal SmartAnswer::Money.new("802"), result
    end

    test "maximum allowance when just over income limit" do
      test_income = @income_limit + 1
      result = default_calculator.calculate_allowance(test_income)
      assert_equal SmartAnswer::Money.new("802"), result
    end

    test "adjusted net income calculation" do
      calculator = default_calculator
      calculator.income = 35000
      calculator.gross_pension_contributions = 3000
      calculator.net_pension_contributions = 2000
      calculator.gift_aided_donations = 1000

      result = calculator.calculate_adjusted_net_income
      assert_equal SmartAnswer::Money.new("28250"), result
    end

    test 'rate values for year 2013' do
      Timecop.freeze(Date.parse('2013-06-01')) do
        calculator = MarriedCouplesAllowanceCalculator.new

        assert_equal 9440, calculator.personal_allowance
        assert_equal 26100.0, calculator.income_limit_for_personal_allowances
        assert_equal 7915, calculator.maximum_mca
        assert_equal 3040, calculator.minimum_mca
      end
    end

    test 'rate values for year 2014' do
      Timecop.freeze(Date.parse('2014-06-01')) do
        calculator = MarriedCouplesAllowanceCalculator.new

        assert_equal 10000, calculator.personal_allowance
        assert_equal 27000.0, calculator.income_limit_for_personal_allowances
        assert_equal 8165, calculator.maximum_mca
        assert_equal 3140, calculator.minimum_mca
      end
    end

    test 'rate values for year 2015' do
      Timecop.freeze(Date.parse('2015-06-01')) do
        calculator = MarriedCouplesAllowanceCalculator.new

        assert_equal 10600, calculator.personal_allowance
        assert_equal 27700.0, calculator.income_limit_for_personal_allowances
        assert_equal 8355, calculator.maximum_mca
        assert_equal 3220, calculator.minimum_mca
      end
    end

    test 'rate values for year 2016' do
      Timecop.freeze(Date.parse('2016-06-01')) do
        calculator = MarriedCouplesAllowanceCalculator.new

        assert_equal 11000, calculator.personal_allowance
        assert_equal 27700.0, calculator.income_limit_for_personal_allowances
        assert_equal 8355, calculator.maximum_mca
        assert_equal 3220, calculator.minimum_mca
      end
    end
  end
end
