local
  pkix_map = {
    "common_name": "CN",
    "serial_number": "SERIALNUMBER",
    "country": "C",
    "organization": "O",
    "organizational_unit": "OU",
    "locality": "L",
    "province": "ST",
    "street_address": "STREET",
    "postal_code": "POSTALCODE"
  };
  
{
  to_pkix(obj): {
      [pkix_map[field]]:obj[field]
      for field in std.objectFields(obj)
      if field in pkix_map
  }
}
