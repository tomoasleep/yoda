module AddressHelper
  def addresses(*address_strings)
    address_strings.map { |a| Yoda::Store::Address.of(a) }
  end
end
