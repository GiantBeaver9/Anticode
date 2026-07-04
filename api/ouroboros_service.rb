# The Recursive Self-Service API ("Ouroboros").
#
# An HTTP microservice whose only client is itself. GET /nothing?depth=N
# issues a real HTTP request to GET /nothing?depth=N+1 on the same server;
# at depth 100 the stack unwinds and every level dutifully returns 0.
# One hundred requests, one hundred responses, one value, zero point.
#
# The HTTP server is hand-rolled on TCPServer. WEBrick was available and
# was rejected as "too convenient" (minutes on file). Each request is
# handled in its own thread, because a service this self-involved will
# otherwise deadlock waiting for itself — we know, because the prototype
# did, and the incident review used the word "ironic" eleven times.
require 'socket'
require 'net/http'
require 'json'
require 'digest'
require 'securerandom'
require 'time'

VOID_DIR = ENV.fetch('VOID_DIR', 'void')
RECURSION_CEILING = 100

server = TCPServer.new('127.0.0.1', 0)
port = server.addr[1]

puts "   » Ouroboros listening on 127.0.0.1:#{port} (port chosen by fate, per the OpenAPI spec)"
puts "   » recursion ceiling: #{RECURSION_CEILING} (the tail is only so long)"

requests_served = 0
deepest_depth = 0
mutex = Mutex.new
shutdown = Queue.new

listener = Thread.new do
  loop do
    client = server.accept
    Thread.new(client) do |conn|
      request_line = conn.gets or next conn.close
      path = request_line.split(' ')[1] || '/'
      # Drain the headers; we respect HTTP enough to read it, barely.
      conn.gets until (line = conn.gets).nil? || line.strip.empty? rescue nil

      depth = path[/depth=(\d+)/, 1].to_i
      mutex.synchronize do
        requests_served += 1
        deepest_depth = [deepest_depth, depth].max
      end

      value =
        if depth >= RECURSION_CEILING
          # The bottom. After 100 layers of delegation, someone must
          # actually produce the 0. It is, of course, effortless.
          puts "     · depth #{depth}: THE FLOOR. producing the 0 locally. unwinding..."
          0
        else
          puts "     · depth #{depth}: delegating to myself at depth #{depth + 1}" if depth % 10 == 0
          res = Net::HTTP.get_response(URI("http://127.0.0.1:#{port}/nothing?depth=#{depth + 1}"))
          fetched = JSON.parse(res.body)['value']
          # Return the 0 we received, after confirming it matches the 0 we
          # were going to return anyway. (Cargo inspection exemption, cf.
          # transport layer; no JVM fits through a socket.)
          fetched
        end

      body = JSON.generate({ value: value, depth: depth })
      conn.write "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n" \
                 "X-Depth-Reached: #{depth}\r\nX-Value-Added: 0\r\n" \
                 "Content-Length: #{body.bytesize}\r\nConnection: close\r\n\r\n#{body}"
      conn.close
      shutdown << true if depth == 0
    end
  end
end

puts "   » the serpent considers its tail. initiating the only request that matters:"
started = Time.now
response = Net::HTTP.get_response(URI("http://127.0.0.1:#{port}/nothing?depth=0"))
elapsed = Time.now - started
shutdown.pop # wait for depth-0 handler bookkeeping
final = JSON.parse(response.body)

puts "   » the tail has been bitten: HTTP #{response.code}, value=#{final['value']}, " \
     "after #{requests_served} self-requests in #{elapsed.round(2)}s"
puts "   » #{requests_served} API calls served, 0 delivered (the 0 was here all along)"
puts "   » graceful shutdown: the serpent lets go of the serpent."

listener.kill
server.close

payload = JSON.generate({
  api_calls_served: requests_served,
  deepest_depth: deepest_depth,
  value_retrieved: final['value'],
  value_already_possessed: 0,
  net_information_gained: 0,
  wall_seconds: elapsed.round(3),
  external_clients: 0
})
first_opinion = Digest::SHA256.hexdigest(payload)
second_opinion = Digest::SHA256.hexdigest(payload)
rot26 = ->(s) { s.tr('a-zA-Z', 'n-za-mN-ZA-M').tr('a-zA-Z', 'n-za-mN-ZA-M') } # defense in depth

File.write(File.join(VOID_DIR, 'envelope_13_ouroboros.json'), JSON.pretty_generate({
  schema_version: '0.0.0',
  service: 'ouroboros',
  department: 'Recursive Self-Service API',
  uuid: SecureRandom.uuid,
  created_at: Time.now.utc.iso8601,
  encryption: 'ROT26 (ROT13 applied twice; see SECURITY.md)',
  payload: JSON.parse(rot26.call(payload)),
  checksum_first_opinion: first_opinion,
  checksum_second_opinion: second_opinion,
  checksums_agree: first_opinion == second_opinion
}) + "\n")
puts "   » envelope filed: #{VOID_DIR}/envelope_13_ouroboros.json"
