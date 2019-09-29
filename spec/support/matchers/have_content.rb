RSpec::Matchers.define(:have_content) do |expected|
  match do |actual|
    if actual.is_a?(Hash)
      values_match?(expected, actual[:value])
    else
      values_match?(expected, actual)
    end
  end
end
