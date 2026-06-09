Mobility.configure do
  plugins do
    backend :table
    active_record
    reader
    writer
    fallbacks
    locale_accessors
    query
    dirty
  end
end
