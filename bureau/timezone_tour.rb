# The Time Zone Bureau.
#
# Exploits the greatest coincidence in computing: the number 0, interpreted
# as a Unix timestamp, IS a moment in time — 1970-01-01T00:00:00Z, the
# epoch, the primordial midnight. Before the platform may use its 0, the
# Bureau tours it through every UTC offset with full layover logging,
# converts it back, and has a JVM confirm the journey changed nothing.
#
# The Bureau maintains its own offset table rather than linking a timezone
# database, because tzdata receives updates, and the Bureau does not care
# for surprises.
require 'json'
require 'digest'
require 'securerandom'
require 'time'

VOID_DIR = ENV.fetch('VOID_DIR', 'void')

# Every offset the Bureau recognizes, in minutes, with a port of call.
TOUR_ITINERARY = [
  ['UTC-12:00', -720, 'Baker Island (the day before, permanently)'],
  ['UTC-11:00', -660, 'Niue (quiet; the zero appreciates it)'],
  ['UTC-10:00', -600, 'Honolulu'],
  ['UTC-09:30', -570, 'Marquesas (the first half-step; the zero stumbles)'],
  ['UTC-09:00', -540, 'Anchorage'],
  ['UTC-08:00', -480, 'Los Angeles (the zero is asked if it is "attached to a project")'],
  ['UTC-07:00', -420, 'Denver'],
  ['UTC-06:00', -360, 'Mexico City'],
  ['UTC-05:00', -300, 'New York (the zero is told it should be in fintech)'],
  ['UTC-04:00', -240, 'Santiago'],
  ['UTC-03:30', -210, 'St. John\'s (another half-step; the zero has opinions now)'],
  ['UTC-03:00', -180, 'Buenos Aires'],
  ['UTC-02:00', -120, 'South Georgia (mostly penguins; strong meeting culture)'],
  ['UTC-01:00',  -60, 'Azores'],
  ['UTC±00:00',    0, 'Greenwich (HOME. the zero visits the meridian and feels seen)'],
  ['UTC+01:00',   60, 'Berlin'],
  ['UTC+02:00',  120, 'Cairo'],
  ['UTC+03:00',  180, 'Nairobi'],
  ['UTC+03:30',  210, 'Tehran'],
  ['UTC+04:00',  240, 'Dubai (the zero is offered a business opportunity; declines)'],
  ['UTC+04:30',  270, 'Kabul'],
  ['UTC+05:00',  300, 'Karachi'],
  ['UTC+05:30',  330, 'Mumbai'],
  ['UTC+05:45',  345, 'Kathmandu (the legendary forty-five; the zero takes a photo)'],
  ['UTC+06:00',  360, 'Dhaka'],
  ['UTC+06:30',  390, 'Yangon'],
  ['UTC+07:00',  420, 'Bangkok'],
  ['UTC+08:00',  480, 'Singapore'],
  ['UTC+08:45',  525, 'Eucla (population ~50, offset ¾; the zero respects the commitment)'],
  ['UTC+09:00',  540, 'Tokyo'],
  ['UTC+09:30',  570, 'Adelaide'],
  ['UTC+10:00',  600, 'Sydney'],
  ['UTC+10:30',  630, 'Lord Howe Island (DST moves it half an hour; nobody explains why to the zero)'],
  ['UTC+11:00',  660, 'Nouméa'],
  ['UTC+12:00',  720, 'Auckland'],
  ['UTC+12:45',  765, 'Chatham Islands (the other forty-five; they wave at Kathmandu)'],
  ['UTC+13:00',  780, 'Nukuʻalofa (tomorrow, already)'],
  ['UTC+14:00',  840, 'Kiritimati (the most tomorrow a place can be)'],
].freeze

puts '   » Time Zone Bureau: the number 0 reports for its pre-use world tour.'
puts '   » itinerary: ' + TOUR_ITINERARY.length.to_s + ' offsets. luggage: none. value: none. spirits: high.'

the_zero = 0
epoch = Time.at(the_zero).utc
puts "   » interpreted as time, the 0 is: #{epoch.strftime('%Y-%m-%dT%H:%M:%SZ')} — the primordial midnight."
puts

layovers = 0
TOUR_ITINERARY.each do |name, offset_minutes, port|
  local = Time.at(the_zero).getlocal(format('%+03d:%02d', offset_minutes / 60, offset_minutes.abs % 60))
  layovers += 1
  puts format('     · %-10s local time of nothing: %s — 0 has arrived in %s',
              name, local.strftime('%Y-%m-%d %H:%M'), port)
end

puts
returned = Time.at(the_zero).utc.to_i
puts "   » tour complete: #{layovers} layovers, 0 delays (there was nothing to delay)."
puts "   » converting the traveler back to an integer: #{returned}"
puts '   » per policy (ADR-004), a JVM must confirm the journey changed nothing:'

verdict = system('java', '-cp', 'build/classes', 'enterprise.EqualityOracle', 'ZERO', returned.to_s)
abort '   SEV-0: the zero came home different. travel changes everyone, apparently.' unless verdict

puts '   » jet lag report: none. the zero experienced every hour of Jan 1 1970'
puts '     simultaneously and described the experience as "0/10, would repeat".'

payload = JSON.generate({
  traveler: 0,
  layovers: layovers,
  half_hour_offsets_survived: TOUR_ITINERARY.count { |(_, m, _)| m % 60 == 30 },
  forty_five_minute_offsets_survived: TOUR_ITINERARY.count { |(_, m, _)| m % 60 == 45 || m % 60 == 15 },
  value_on_departure: 0,
  value_on_return: returned,
  jvm_confirmed_unchanged: true,
  souvenirs: 0
})
first_opinion = Digest::SHA256.hexdigest(payload)
second_opinion = Digest::SHA256.hexdigest(payload)
rot26 = ->(s) { s.tr('a-zA-Z', 'n-za-mN-ZA-M').tr('a-zA-Z', 'n-za-mN-ZA-M') }

File.write(File.join(VOID_DIR, 'envelope_14_timezone_bureau.json'), JSON.pretty_generate({
  schema_version: '0.0.0',
  service: 'timezone_bureau',
  department: 'The Time Zone Bureau',
  uuid: SecureRandom.uuid,
  created_at: Time.now.utc.iso8601,
  encryption: 'ROT26 (ROT13 applied twice; see SECURITY.md)',
  payload: JSON.parse(rot26.call(payload)),
  checksum_first_opinion: first_opinion,
  checksum_second_opinion: second_opinion,
  checksums_agree: first_opinion == second_opinion
}) + "\n")
puts "   » envelope filed: #{VOID_DIR}/envelope_14_timezone_bureau.json"
